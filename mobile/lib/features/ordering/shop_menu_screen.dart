import 'package:flutter/material.dart';

import '../home/home_style.dart';
import '../home/widgets/category_chips.dart';
import 'checkout_screen.dart';
import 'ordering_widgets.dart';
import 'student_api.dart';
import 'tray.dart';
import 'food_item_sheet.dart';

class ShopMenuScreen extends StatefulWidget {
  final Tray tray;
  const ShopMenuScreen({super.key, required this.tray, this.onNavigate});
  final ValueChanged<int>? onNavigate;
  @override
  State<ShopMenuScreen> createState() => _ShopMenuScreenState();
}

class _ShopMenuScreenState extends State<ShopMenuScreen> {
  String _category = 'Popular';
  bool _favourite = false;
  bool _loading = false;
  String? _error;

  bool get _live => widget.tray.live;

  @override
  void initState() {
    super.initState();
    if (_live) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await StudentApi.menu(widget.tray.shop.id);
      if (mounted) widget.tray.setMenu(items);
    } on StudentApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: HomeStyle.theme,
    child: ListenableBuilder(
      listenable: widget.tray,
      builder: (context, _) => Scaffold(
        appBar: OrderingHeader(
          action: IconButton(
            tooltip: _favourite
                ? 'Remove from favourites'
                : 'Add to favourites',
            onPressed: () => setState(() => _favourite = !_favourite),
            icon: Icon(
              _favourite ? Icons.favorite : Icons.favorite_border,
              size: 22,
              color: _favourite ? HomeStyle.orange : HomeStyle.muted,
            ),
          ),
        ),
        body: ListView(
          children: [
            Stack(
              children: [
                if (widget.tray.shop.imageAsset.isEmpty)
                  const SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: Icon(
                      Icons.storefront_outlined,
                      size: 56,
                      color: HomeStyle.orange,
                    ),
                  )
                else
                  Image.asset(
                    widget.tray.shop.imageAsset,
                    height: 255,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, HomeStyle.background],
                        stops: [.35, 1],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.tray.shop.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: widget.tray.shop.isOpen
                              ? HomeStyle.green
                              : HomeStyle.muted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.tray.shop.isOpen ? 'Open Now' : 'Closed',
                        style: const TextStyle(
                          fontSize: 10,
                          color: HomeStyle.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _live ? widget.tray.shop.location : 'Open till 7:00 PM',
                    style: const TextStyle(
                      fontSize: 12,
                      color: HomeStyle.muted,
                    ),
                  ),
                  if (!_live) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _badge(
                          Icons.star,
                          '${widget.tray.shop.rating} (184)',
                          HomeStyle.orange,
                        ),
                        const SizedBox(width: 10),
                        _badge(Icons.schedule, '10–15 mins', HomeStyle.muted),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Live menu items have no category yet.
            if (!_live) ...[
              CategoryChips(
                categories: const [
                  'Popular',
                  'Rice & Curry',
                  'Short Eats',
                  'Beverages',
                ],
                selected: _category,
                onSelected: (category) => setState(() => _category = category),
              ),
              const SizedBox(height: 20),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_loading && widget.tray.menu.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_live && widget.tray.menu.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'This shop has no items available right now.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: HomeStyle.muted),
                  ),
                ),
              ),
            if (_category == 'Beverages')
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No beverages available yet.',
                    style: TextStyle(color: HomeStyle.muted),
                  ),
                ),
              ),
            for (final item in widget.tray.menu.where(
              (item) => _category == 'Popular' || item.category == _category,
            ))
              _food(item),
            const SizedBox(height: 24),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: BoxDecoration(
                color: HomeStyle.surface,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: HomeStyle.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.tray.count} ${widget.tray.count == 1 ? 'Item' : 'Items'} in Tray • LKR ${money(widget.tray.subtotal)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  FilledButton(
                    onPressed: widget.tray.count == 0
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => CheckoutScreen(
                                tray: widget.tray,
                                onNavigate: widget.onNavigate,
                              ),
                            ),
                          ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Tray', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget _badge(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: HomeStyle.surface,
      border: Border.all(color: HomeStyle.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: HomeStyle.muted),
        ),
      ],
    ),
  );
  Widget _food(FoodItem item) => GestureDetector(
    onTap: () => showFoodItem(context, widget.tray, item),
    child: Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: orderPanel(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: HomeStyle.muted),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'LKR ${money(item.price)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: HomeStyle.orange,
                      ),
                    ),
                    if (widget.tray.quantity(item) > 0)
                      QuantityControl(tray: widget.tray, item: item)
                    else
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton.filled(
                          tooltip: 'Add ${item.name}',
                          style: IconButton.styleFrom(
                            backgroundColor: HomeStyle.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => widget.tray.change(item, 1),
                          icon: const Icon(Icons.add, size: 20),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FoodPhoto(
            item: item,
            size: MediaQuery.sizeOf(context).width < 350 ? 78 : 94,
          ),
        ],
      ),
    ),
  );
}
