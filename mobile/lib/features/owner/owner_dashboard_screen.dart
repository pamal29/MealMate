import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../auth/profile_screen.dart';
import '../home/home_style.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key, this.isPreview = false});
  final bool isPreview;

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _tab = 1;
  bool _history = false;
  final _orders = [
    _Order(
      'MM-8493',
      'Nuwan Perera',
      '2× Devilled Chicken Kothu\n1× Passion Juice',
      1300,
      '2m ago',
    ),
    _Order('MM-8494', 'Rashmi', '1× Chicken Fried Rice', 600, '5m ago'),
    _Order('MM-8477', 'Dulara', '1× Chicken Chicken Kottu', 900, '5m ago'),
  ];

  int get _pending => _orders.where((order) => order.status == null).length;

  void _respond(_Order order, String status) {
    setState(() => order.status = status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preview: ${order.id} ${status.toLowerCase()}. No customer was notified.',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (mounted) setState(() => order.status = null);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: HomeStyle.theme,
    child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: HomeStyle.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SvgPicture.asset(
                'assets/login/utensils.svg',
                colorFilter: const ColorFilter.mode(
                  HomeStyle.orange,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MealMate',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              ['Overview', 'Orders', 'Profile'][_tab],
              style: const TextStyle(fontSize: 11, color: HomeStyle.muted),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Notifications'),
                content: const Text(
                  'This dashboard uses sample orders. Live notifications are not connected yet.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            icon: const Icon(
              Icons.notifications_none,
              size: 20,
              color: HomeStyle.muted,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _tab == 2
          ? widget.isPreview
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Shop-owner preview'),
                        const SizedBox(height: 12),
                        const Text('No account or database is required.'),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Back to login'),
                        ),
                      ],
                    ),
                  )
                : const ProfileScreen()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: HomeStyle.surface,
                    border: Border.all(color: HomeStyle.border),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shan Food Cabin',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -.6,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Y junction',
                              style: TextStyle(
                                fontSize: 11,
                                color: HomeStyle.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.circle, size: 7, color: HomeStyle.green),
                      const SizedBox(width: 4),
                      const Text(
                        'Open',
                        style: TextStyle(fontSize: 11, color: HomeStyle.green),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Today's Overview", style: TextStyle(fontSize: 13)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _metric('Orders', '28')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metric('Pending', '$_pending new', accent: true),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Preview · Sample orders only',
                  style: TextStyle(fontSize: 10, color: HomeStyle.muted),
                ),
                if (_tab == 0) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => setState(() {
                      _tab = 1;
                      _history = false;
                    }),
                    child: const Text('View pending orders'),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        _history ? 'Order History' : 'Pending Orders',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: HomeStyle.orange,
                        ),
                        child: Text(
                          '${_history ? _orders.length - _pending : _pending}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _history = !_history),
                        child: Text(
                          _history ? 'Pending' : 'History',
                          style: const TextStyle(
                            color: HomeStyle.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_orders.any(
                    (order) => (order.status != null) == _history,
                  ))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          _history
                              ? 'No orders in history yet.'
                              : 'All caught up! No pending orders.',
                          style: const TextStyle(color: HomeStyle.muted),
                        ),
                      ),
                    ),
                  for (final order in _orders.where(
                    (order) => (order.status != null) == _history,
                  ))
                    _card(order),
                ],
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (index) => setState(() => _tab = index),
        backgroundColor: HomeStyle.background,
        selectedItemColor: HomeStyle.orange,
        unselectedItemColor: HomeStyle.muted,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        iconSize: 20,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'Home',
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

  Widget _metric(String label, String value, {bool accent = false}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HomeStyle.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HomeStyle.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: HomeStyle.muted,
                    ),
                  ),
                ),
                if (accent)
                  const Icon(Icons.circle, size: 5, color: HomeStyle.orange),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: accent ? HomeStyle.orange : Colors.white,
              ),
            ),
          ],
        ),
      );

  Widget _card(_Order order) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: HomeStyle.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: HomeStyle.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '#${order.id}',
                style: const TextStyle(fontSize: 10, color: HomeStyle.muted),
              ),
            ),
            Text(
              order.time,
              style: const TextStyle(fontSize: 10, color: HomeStyle.muted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          order.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Text(
          order.items,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFD4D4D4),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'LKR ${order.total.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 22),
        if (order.status == null)
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: HomeStyle.border,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _respond(order, 'Rejected'),
                  child: const Text('Reject', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _respond(order, 'Confirmed'),
                  child: const Text(
                    'Confirm Order',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            '${order.status} · Preview',
            style: const TextStyle(color: HomeStyle.orange, fontSize: 12),
          ),
      ],
    ),
  );
}

class _Order {
  _Order(this.id, this.name, this.items, this.total, this.time);
  final String id, name, items, time;
  final int total;
  String? status;
}
