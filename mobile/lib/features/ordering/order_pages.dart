import 'package:flutter/material.dart';

import '../home/home_style.dart';
import 'preview_orders.dart';

Color orderColor(OrderStatus status) => switch (status) {
  OrderStatus.rejected => Colors.redAccent,
  OrderStatus.cancelled => HomeStyle.muted,
  OrderStatus.ready => HomeStyle.green,
  _ => HomeStyle.orange,
};

class OrderPageShell extends StatelessWidget {
  const OrderPageShell({
    super.key,
    required this.title,
    required this.child,
    this.onNavigate,
  });
  final String title;
  final Widget child;
  final ValueChanged<int>? onNavigate;
  @override
  Widget build(BuildContext context) => Theme(
    data: HomeStyle.theme,
    child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'MealMate',
              style: TextStyle(color: HomeStyle.orange, fontSize: 11),
            ),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: const [
          Center(
            child: Text(
              'SUSL',
              style: TextStyle(color: HomeStyle.orange, fontSize: 10),
            ),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: child,
      bottomNavigationBar: onNavigate == null
          ? null
          : BottomNavigationBar(
              currentIndex: 2,
              onTap: onNavigate,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: HomeStyle.orange,
              unselectedItemColor: HomeStyle.muted,
              backgroundColor: HomeStyle.surface,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.storefront_outlined),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu),
                  label: 'Explore',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            ),
    ),
  );
}

Widget orderPanel(Widget child) => Container(
  margin: const EdgeInsets.only(bottom: 18),
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: HomeStyle.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: HomeStyle.border),
  ),
  child: child,
);

class OrderSummary extends StatelessWidget {
  const OrderSummary({super.key, required this.order, this.images = true});
  final PreviewOrder order;
  final bool images;
  Widget amount(String name, int amount) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: HomeStyle.muted, fontSize: 12),
          ),
        ),
        Text('LKR $amount', style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => orderPanel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ORDER SUMMARY',
          style: TextStyle(color: HomeStyle.muted, fontSize: 11),
        ),
        const SizedBox(height: 16),
        for (final line in order.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (images && line.image != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      line.image!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${line.quantity} × ${line.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (line.description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          line.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: HomeStyle.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text('LKR ${line.total}', style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        const Divider(color: HomeStyle.border),
        amount('Subtotal', order.subtotal),
        if (order.packaging > 0) amount('Campus Packaging', order.packaging),
        const Divider(height: 28, color: HomeStyle.border),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Order total',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            Text(
              'LKR ${order.total}',
              style: const TextStyle(
                color: HomeStyle.orange,
                fontWeight: FontWeight.w700,
                fontSize: 21,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order, this.onNavigate});
  final PreviewOrder order;
  final ValueChanged<int>? onNavigate;
  @override
  Widget build(BuildContext context) => OrderPageShell(
    title: 'Order placed',
    onNavigate: onNavigate,
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        const CircleAvatar(
          radius: 36,
          backgroundColor: Color(0xFF10251A),
          child: Icon(Icons.check, color: HomeStyle.green, size: 32),
        ),
        const SizedBox(height: 20),
        const Text(
          'Order Placed\nSuccessfully!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        const Text(
          'Preview only — no order was sent to a shop.\nFollow its sample progress below.',
          textAlign: TextAlign.center,
          style: TextStyle(color: HomeStyle.muted, fontSize: 12, height: 1.6),
        ),
        const SizedBox(height: 24),
        Text(
          '#${order.id}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: HomeStyle.orange, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          order.shop,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          order.dateLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(color: HomeStyle.muted, fontSize: 10),
        ),
        const SizedBox(height: 20),
        OrderSummary(order: order, images: false),
        const Text(
          'Cash on Delivery · Preview, no payment taken',
          textAlign: TextAlign.center,
          style: TextStyle(color: HomeStyle.muted, fontSize: 11),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  OrderDetailsScreen(order: order, onNavigate: onNavigate),
            ),
          ),
          child: const Text('Track My Order'),
        ),
        TextButton(
          onPressed: () {
            if (onNavigate != null) {
              onNavigate!(0);
            } else {
              Navigator.pop(context);
            }
          },
          child: const Text('Back to Home'),
        ),
      ],
    ),
  );
}

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.order, this.onNavigate});
  final PreviewOrder order;
  final ValueChanged<int>? onNavigate;
  void _go(BuildContext context, int index) {
    if (onNavigate != null) {
      onNavigate!(index);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: PreviewOrders.instance,
    builder: (context, _) => OrderPageShell(
      title: 'Order details',
      onNavigate: onNavigate,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${order.id}',
                  style: const TextStyle(color: HomeStyle.muted, fontSize: 11),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: orderColor(order.status).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '• ${order.label}',
                  style: TextStyle(
                    color: orderColor(order.status),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.shop,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            order.dateLabel,
            style: const TextStyle(color: HomeStyle.muted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          const Text(
            'Preview · Sample order only',
            style: TextStyle(color: HomeStyle.muted, fontSize: 10),
          ),
          const SizedBox(height: 20),
          if (order.closed)
            orderPanel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        order.status == OrderStatus.rejected
                            ? Icons.cancel_outlined
                            : Icons.block,
                        color: orderColor(order.status),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order ${order.status.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Order closed',
                              style: TextStyle(
                                fontSize: 11,
                                color: orderColor(order.status),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    order.status == OrderStatus.rejected
                        ? 'The shop did not accept this order. It will not be prepared. You can place a new order from another shop.'
                        : 'This order is no longer active and will not be prepared. No collection is needed.',
                    style: const TextStyle(
                      color: HomeStyle.muted,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            )
          else
            orderPanel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ORDER STATUS',
                    style: TextStyle(color: HomeStyle.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 18),
                  for (var i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            i < order.status.index
                                ? Icons.check_circle
                                : i == order.status.index
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: i < order.status.index
                                ? HomeStyle.green
                                : i == order.status.index
                                ? HomeStyle.orange
                                : HomeStyle.muted,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  [
                                    'Pending',
                                    'Confirmed',
                                    'Preparing',
                                    'Ready',
                                  ][i],
                                  style: TextStyle(
                                    color: i == order.status.index
                                        ? HomeStyle.orange
                                        : Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  [
                                    'Order sent to the shop',
                                    'The shop accepted your order',
                                    'Your food is being prepared',
                                    'Collect from the shop when ready',
                                  ][i],
                                  style: const TextStyle(
                                    color: HomeStyle.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (i == order.status.index)
                            const Text(
                              'Current',
                              style: TextStyle(
                                color: HomeStyle.orange,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          OrderSummary(order: order),
          orderPanel(
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: HomeStyle.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cash on Delivery',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.closed
                            ? 'No payment is due for this order.'
                            : 'Pay at the shop when collecting your food.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: HomeStyle.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (order.closed)
            FilledButton(
              onPressed: () => _go(context, 1),
              child: Text(
                order.status == OrderStatus.rejected
                    ? 'Explore Shops'
                    : 'Browse Menu',
              ),
            ),
          if (!order.closed && order.status != OrderStatus.ready)
            OutlinedButton(
              onPressed: () => PreviewOrders.instance.advance(order),
              child: const Text('Preview next status'),
            ),
          if (order.status == OrderStatus.pending)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cancel preview order?'),
                    content: const Text('This only updates the local preview.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Keep order'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Cancel order'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) PreviewOrders.instance.cancel(order);
              },
              child: const Text('Cancel preview order'),
            ),
          TextButton(
            onPressed: () => _go(context, 2),
            child: const Text('Back to Orders'),
          ),
        ],
      ),
    ),
  );
}
