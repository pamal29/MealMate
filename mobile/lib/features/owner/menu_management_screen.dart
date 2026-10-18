import 'package:flutter/material.dart';

import '../home/home_style.dart';
import '../home/widgets/category_chips.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});
  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  String _query = '', _category = 'All';
  final _items = [
    _Dish(
      'Chicken Fried Rice',
      'Basmati, roast chicken, egg',
      480,
      'Rice & Curry',
      'assets/food/rice.jpg',
    ),
    _Dish(
      'Vegetable Samosa',
      'Spiced potato, peas, crisp pastry',
      150,
      'Short Eats',
      'assets/food/samosa.jpg',
    ),
    _Dish(
      'Fresh Passion Fruit Juice',
      '350ml fresh squeezed, lightly sweetened',
      200,
      'Beverages',
      null,
      available: false,
    ),
  ];
  Future<void> _edit([_Dish? dish]) async {
    final name = TextEditingController(text: dish?.name);
    final description = TextEditingController(text: dish?.description);
    final price = TextEditingController(text: dish?.price.toString());
    var category = dish?.category ?? 'Rice & Curry';
    final form = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(dish == null ? 'New menu item' : 'Edit menu item'),
          content: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Dish name'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter a name.' : null,
                  ),
                  TextFormField(
                    controller: description,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  TextFormField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price (LKR)'),
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                        ? 'Enter a positive whole amount.'
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    items: [
                      for (final c in [
                        'Rice & Curry',
                        'Short Eats',
                        'Beverages',
                      ])
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => update(() => category = v!),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Preview changes last for this session.',
                    style: TextStyle(fontSize: 12, color: HomeStyle.muted),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Save item'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        if (dish == null) {
          _items.add(
            _Dish(
              name.text.trim(),
              description.text.trim(),
              int.parse(price.text),
              category,
              null,
            ),
          );
        } else {
          dish.name = name.text.trim();
          dish.description = description.text.trim();
          dish.price = int.parse(price.text);
          dish.category = category;
        }
      });
    }
    // Let the dialog's closing animation finish before disposing its fields.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    description.dispose();
    price.dispose();
  }

  Future<void> _delete(_Dish dish) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete menu item?'),
        content: Text('Remove ${dish.name} from this preview menu?'),
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
    if (yes == true && mounted) setState(() => _items.remove(dish));
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Shan Food Cabin',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton(
              onPressed: () => _edit(),
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
        const SizedBox(height: 18),
        CategoryChips(
          categories: const ['All', 'Rice & Curry', 'Short Eats', 'Beverages'],
          selected: _category,
          onSelected: (v) => setState(() => _category = v),
        ),
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
        const Text(
          'Preview · Changes are not published',
          style: TextStyle(fontSize: 10, color: HomeStyle.muted),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No matching dishes.'),
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
                          child: dish.image == null
                              ? const SizedBox(
                                  width: 70,
                                  height: 76,
                                  child: Icon(
                                    Icons.local_drink_outlined,
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
                                'LKR ${dish.price}',
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
                              onPressed: () =>
                                  setState(() => dish.available = true),
                              child: const Text(
                                'Restock',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          Switch(
                            value: dish.available,
                            activeThumbColor: Colors.white,
                            activeTrackColor: HomeStyle.green,
                            onChanged: (v) =>
                                setState(() => dish.available = v),
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
  }
}

class _Dish {
  _Dish(
    this.name,
    this.description,
    this.price,
    this.category,
    this.image, {
    this.available = true,
  });
  String name, description, category;
  int price;
  final String? image;
  bool available;
}
