import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../home/home_style.dart';
import 'ordering_widgets.dart';
import 'live_orders.dart';
import 'tray.dart';
import 'preview_orders.dart';
import 'order_pages.dart' show OrderSuccessScreen;

class CheckoutScreen extends StatelessWidget {
  final Tray tray;
  const CheckoutScreen({super.key, required this.tray, this.onNavigate});
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) => Theme(
    data: HomeStyle.theme,
    child: ListenableBuilder(
      listenable: tray,
      builder: (context, _) => Scaffold(
        appBar: OrderingHeader(
          subtitle: 'Your Tray',
          shopName: tray.shop.name,
          action: TextButton(
            onPressed: tray.count == 0 ? null : tray.clear,
            style: TextButton.styleFrom(
              backgroundColor: HomeStyle.orange,
              foregroundColor: Colors.black,
              minimumSize: const Size(44, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
        ),
        body: tray.count == 0
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 42,
                      color: HomeStyle.muted,
                    ),
                    const SizedBox(height: 16),
                    const Text('Your tray is empty'),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Browse menu'),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ITEMS IN TRAY',
                        style: TextStyle(
                          fontSize: 11,
                          color: HomeStyle.muted,
                          letterSpacing: .6,
                        ),
                      ),
                      Text(
                        '${tray.items.length} ${tray.items.length == 1 ? 'item' : 'items'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: HomeStyle.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final item in tray.items) _item(context, item),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: orderPanel(),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: HomeStyle.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              color: HomeStyle.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PICKUP STUDENT',
                                style: TextStyle(
                                  color: HomeStyle.muted,
                                  fontSize: 10,
                                  letterSpacing: .6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(_name, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        if (!tray.live)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: HomeStyle.orange.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: HomeStyle.orange.withValues(alpha: .25),
                              ),
                            ),
                            child: const Text(
                              '15–20m',
                              style: TextStyle(
                                fontSize: 10,
                                color: HomeStyle.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: orderPanel(),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ORDER BREAKDOWN',
                            style: TextStyle(
                              fontSize: 12,
                              color: HomeStyle.muted,
                              letterSpacing: .4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _amount('Subtotal', tray.subtotal),
                        const SizedBox(height: 10),
                        if (!tray.live)
                          _amount('Campus Packaging', tray.packaging),
                        const Divider(height: 24, color: HomeStyle.border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Total Payable',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              'LKR ${money(tray.total)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: HomeStyle.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: HomeStyle.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: _PlaceOrderButton(tray: tray, onNavigate: onNavigate),
            ),
          ),
        ),
      ),
    ),
  );

  String get _name => (AuthService.user?['name'] as String?) ?? 'Student';
  String get _initials => _name
      .trim()
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .take(2)
      .map((s) => s[0].toUpperCase())
      .join();
  Widget _amount(String label, num amount) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, color: HomeStyle.muted),
        ),
      ),
      Text('LKR ${money(amount)}', style: const TextStyle(fontSize: 14)),
    ],
  );
  Widget _item(BuildContext context, FoodItem item) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: orderPanel(),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FoodPhoto(
          item: item,
          size: MediaQuery.sizeOf(context).width < 350 ? 64 : 78,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.id == 'rice'
                          ? 'Chicken Fried Rice'
                          : item.id == 'samosa'
                          ? 'Vegetable Samosa'
                          : item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Remove ${item.name}',
                      onPressed: () => tray.remove(item),
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: HomeStyle.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tray.live
                    ? 'LKR ${money(item.price)} each'
                    : item.id == 'samosa'
                    ? '2 pcs portion · LKR ${item.price} each'
                    : 'SUSL Special · LKR ${item.price} each',
                style: const TextStyle(fontSize: 11, color: HomeStyle.muted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'LKR ${money(item.price * tray.quantity(item))}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: HomeStyle.orange,
                    ),
                  ),
                  QuantityControl(tray: tray, item: item, compact: true),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PlaceOrderButton extends StatefulWidget {
  const _PlaceOrderButton({required this.tray, this.onNavigate});
  final Tray tray;
  final ValueChanged<int>? onNavigate;
  @override
  State<_PlaceOrderButton> createState() => _PlaceOrderButtonState();
}

class _PlaceOrderButtonState extends State<_PlaceOrderButton> {
  bool _placing = false;
  String? _error;

  Future<void> _place() async {
    final tray = widget.tray;
    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      final order = tray.live
          ? await LiveOrders.instance.place(tray)
          : PreviewOrders.instance.place(tray);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              OrderSuccessScreen(order: order, onNavigate: widget.onNavigate),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _placing = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ),
      FilledButton(
        onPressed: widget.tray.count == 0 || _placing ? null : _place,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _placing
                      ? 'Placing order...'
                      : widget.tray.live
                      ? 'Place order (LKR ${money(widget.tray.total)})'
                      : 'Place preview order (LKR ${widget.tray.total})',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ),
    ],
  );
}
