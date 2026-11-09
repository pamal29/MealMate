import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../home/home_style.dart';
import 'food_editor_screen.dart';
import 'owner_shop_service.dart';
import '../home/widgets/category_chips.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({
    super.key,
    this.onNavigate,
    this.isPreview = true,
    this.shopName,
    this.client,
  });
  final ValueChanged<int>? onNavigate;

  /// Sample dishes unless the owner dashboard passes false for a signed-in
  /// owner, in which case the menu is loaded from and saved to the API.
  final bool isPreview;
  final String? shopName;

  /// HTTP client for the menu API; tests pass a mock.
  final http.Client? client;
  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  String _query = '', _category = 'All';
  List<MenuDish> _live = [];
  bool _loading = false, _noShop = false;
  String? _error;
  final _previewItems = [
    MenuDish(
      'Chicken Fried Rice',
      'Basmati, roast chicken, egg',
      480,
      'Rice & Curry',
      'assets/food/rice.jpg',
    ),
    MenuDish(
      'Vegetable Samosa',
      'Spiced potato, peas, crisp pastry',
      150,
      'Short Eats',
      'assets/food/samosa.jpg',
    ),
    MenuDish(
      'Fresh Passion Fruit Juice',
      '350ml fresh squeezed, lightly sweetened',
      200,
      'Beverages',
      null,
      available: false,
    ),
  ];
  List<MenuDish> get _items => widget.isPreview ? _previewItems : _live;

  @override
  void initState() {
    super.initState();
    if (!widget.isPreview) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await OwnerShopService.myMenu(client: widget.client);
      if (!mounted) return;
      setState(() {
        _live = [for (final row in rows) _fromJson(row)];
        _noShop = false;
      });
    } on ShopException catch (e) {
      if (!mounted) return;
      setState(() {
        _noShop = e.notFound;
        if (!e.notFound) _error = e.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static MenuDish _fromJson(Map<String, dynamic> row) => MenuDish(
    row['name'] as String? ?? '',
    row['description'] as String? ?? '',
    num.tryParse('${row['price']}') ?? 0,
    '',
    null,
    available: row['is_available'] != false,
    id: '${row['id']}',
  );

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  /// Saves a dish from the editor; errors keep the editor open.
  Future<void> _saveLive(MenuDish dish) async {
    final description = dish.description.isEmpty ? null : dish.description;
    if (dish.id == null) {
      final row = await OwnerShopService.addItem(
        name: dish.name,
        description: dish.description,
        price: dish.price,
        client: widget.client,
      );
      // New items start available; the add route does not take the flag.
      if (!dish.available) {
        await OwnerShopService.updateItem(
          '${row['id']}',
          isAvailable: false,
          client: widget.client,
        );
      }
    } else {
      await OwnerShopService.updateItem(
        dish.id!,
        name: dish.name,
        description: description,
        price: dish.price,
        isAvailable: dish.available,
        client: widget.client,
      );
    }
  }

  Future<void> _setAvailable(MenuDish dish, bool value) async {
    setState(() => dish.available = value);
    if (widget.isPreview) return;
    try {
      await OwnerShopService.updateItem(
        dish.id!,
        isAvailable: value,
        client: widget.client,
      );
    } on ShopException catch (e) {
      if (!mounted) return;
      setState(() => dish.available = !value);
      _toast(e.message);
    }
  }

  Future<void> _edit([MenuDish? dish]) async {
    final saved = await Navigator.push<MenuDish>(
      context,
      MaterialPageRoute<MenuDish>(
        builder: (_) => FoodEditorScreen(
          dish: dish,
          onNavigate: widget.onNavigate,
          isPreview: widget.isPreview,
          shopName: widget.shopName,
          onSave: widget.isPreview ? null : _saveLive,
        ),
      ),
    );
    if (saved == null || !mounted) return;
    if (!widget.isPreview) {
      _toast(dish == null ? '${saved.name} added.' : '${saved.name} updated.');
      await _load();
      return;
    }
    if (mounted) {
      setState(() {
        if (dish == null) {
          _items.add(saved);
        } else {
          _items[_items.indexOf(dish)] = saved;
        }
      });
    }
  }

  Future<void> _delete(MenuDish dish) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete menu item?'),
        content: Text(
          widget.isPreview
              ? 'Remove ${dish.name} from this preview menu?'
              : 'Remove ${dish.name} from your menu? Students will no longer see it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    if (widget.isPreview) {
      setState(() => _items.remove(dish));
      return;
    }
    try {
      await OwnerShopService.deleteItem(dish.id!, client: widget.client);
      if (!mounted) return;
      setState(() => _live.remove(dish));
      _toast('${dish.name} deleted.');
    } on ShopException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _items
        .where(
          (d) =>
              (_category == 'All' || d.category == _category) &&
              d.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.shopName ??
                    (widget.isPreview ? 'Shan Food Cabin' : 'Menu'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: _noShop ? null : () => _edit(),
              child: const Text('+ New Item'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Search dishes...',
            prefixIcon: Icon(Icons.search),
            filled: true,
            fillColor: HomeStyle.surface,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        if (widget.isPreview) ...[
          const SizedBox(height: 18),
          CategoryChips(
            categories: const [
              'All',
              'Rice & Curry',
              'Short Eats',
              'Beverages',
            ],
            selected: _category,
            onSelected: (v) => setState(() => _category = v),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'ACTIVE MENU (${visible.length} ITEMS)',
                style: const TextStyle(fontSize: 11, color: HomeStyle.muted),
              ),
            ),
            const Text(
              'Tap card to edit',
              style: TextStyle(fontSize: 10, color: HomeStyle.muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.isPreview)
          const Text(
            'Preview · Changes are not published',
            style: TextStyle(fontSize: 10, color: HomeStyle.muted),
          )
        else if (_error != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 11, color: HomeStyle.orange),
                ),
              ),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          )
        else if (_loading && _live.isEmpty)
          const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 12),
        if (_noShop)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Create your shop first. Then you can add menu items.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => widget.onNavigate?.call(2),
                  child: const Text('Set up shop'),
                ),
              ],
            ),
          )
        else if (visible.isEmpty && !(_loading && _live.isEmpty))
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _query.isEmpty && !widget.isPreview
                  ? 'No menu items yet. Tap + New Item to add one.'
                  : 'No matching dishes.',
            ),
          ),
        for (final dish in visible)
          Card(
            margin: const EdgeInsets.only(bottom: 14),
            color: HomeStyle.surface,
            child: InkWell(
              onTap: () => _edit(dish),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: dish.photo != null
                              ? Image.memory(
                                  dish.photo!,
                                  width: 70,
                                  height: 76,
                                  fit: BoxFit.cover,
                                )
                              : dish.image == null
                              ? SizedBox(
                                  width: 70,
                                  height: 76,
                                  child: Icon(
                                    widget.isPreview
                                        ? Icons.local_drink_outlined
                                        : Icons.restaurant_outlined,
                                    color: HomeStyle.muted,
                                    size: 38,
                                  ),
                                )
                              : Image.asset(
                                  dish.image!,
                                  width: 70,
                                  height: 76,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dish.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'LKR ${formatPrice(dish.price)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                dish.description,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: HomeStyle.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          child: IconButton(
                            tooltip: 'Edit ${dish.name}',
                            padding: EdgeInsets.zero,
                            onPressed: () => _edit(dish),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          child: IconButton(
                            tooltip: 'Delete ${dish.name}',
                            padding: EdgeInsets.zero,
                            onPressed: () => _delete(dish),
                            icon: const Icon(Icons.delete_outline, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: HomeStyle.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              dish.available ? '• In Stock' : '• Out of Stock',
                              style: TextStyle(
                                fontSize: 12,
                                color: dish.available
                                    ? HomeStyle.green
                                    : Colors.redAccent,
                              ),
                            ),
                          ),
                          if (!dish.available)
                            TextButton(
                              onPressed: () => _setAvailable(dish, true),
                              child: const Text(
                                'Restock',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          Switch(
                            value: dish.available,
                            activeThumbColor: Colors.white,
                            activeTrackColor: HomeStyle.green,
                            onChanged: (v) => _setAvailable(dish, v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
    return widget.isPreview
        ? list
        : RefreshIndicator(onRefresh: _load, child: list);
  }
}
