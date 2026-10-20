import 'package:flutter/material.dart';

import '../home/home_style.dart';
import 'preview_orders.dart';
import 'order_pages.dart';

class StudentOrdersScreen extends StatefulWidget {
  const StudentOrdersScreen({super.key, this.onNavigate});
  final ValueChanged<int>? onNavigate;
  @override
  State<StudentOrdersScreen> createState() => _StudentOrdersScreenState();
}

class _StudentOrdersScreenState extends State<StudentOrdersScreen> {
  bool _previous = false;
  Widget _card(PreviewOrder order) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    color: HomeStyle.surface,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              OrderDetailsScreen(order: order, onNavigate: widget.onNavigate),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${order.id}',
                    style: const TextStyle(
                      color: HomeStyle.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.shop,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: HomeStyle.muted,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order.lines
                  .map((line) => '${line.quantity} × ${line.name}')
                  .join(' · '),
              style: const TextStyle(fontSize: 11, color: HomeStyle.muted),
            ),
            const Divider(height: 22, color: HomeStyle.border),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.dateLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: HomeStyle.muted,
                    ),
                  ),
                ),
                Text(
                  'LKR ${order.total}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: PreviewOrders.instance,
    builder: (context, _) {
      final active = PreviewOrders.instance.orders
          .where((o) => !o.closed)
          .toList();
      final previous = PreviewOrders.instance.orders
          .where((o) => o.closed)
          .toList();
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? HomeStyle.orange
                    : HomeStyle.surface,
              ),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              side: WidgetStateProperty.all(
                const BorderSide(color: HomeStyle.border),
              ),
            ),
            segments: [
              ButtonSegment(
                value: false,
                label: Text('Active ${active.length}'),
              ),
              const ButtonSegment(value: true, label: Text('Previous')),
            ],
            selected: {_previous},
            onSelectionChanged: (v) => setState(() => _previous = v.first),
          ),
          const SizedBox(height: 12),
          const Text(
            'Preview · Sample orders',
            style: TextStyle(color: HomeStyle.muted, fontSize: 10),
          ),
          const SizedBox(height: 16),
          if (_previous) ...[
            for (final order in previous) _card(order),
          ] else ...[
            if (active.isEmpty) const Text('No active orders.'),
            for (final order in active) _card(order),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'PREVIOUS · MOST RECENT',
                    style: TextStyle(fontSize: 11, color: HomeStyle.muted),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _previous = true),
                  child: const Text('View all'),
                ),
              ],
            ),
            if (previous.isNotEmpty) _card(previous.first),
          ],
          const SizedBox(height: 12),
          const Text(
            'Collect your food when your order is ready.',
            textAlign: TextAlign.center,
            style: TextStyle(color: HomeStyle.muted, fontSize: 11),
          ),
        ],
      );
    },
  );
}
