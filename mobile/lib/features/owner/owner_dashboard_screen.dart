import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../auth/profile_screen.dart';
import '../home/home_style.dart';
import 'menu_management_screen.dart';
import 'owner_orders_service.dart';
import 'owner_shop_service.dart';
import 'shop_profile_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key, this.isPreview = false, this.client});
  final bool isPreview;

  /// HTTP client for the orders API; tests pass a mock.
  final http.Client? client;

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _tab = 1;
  bool _history = false;
  final _previewOrders = [
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

  List<OwnerOrder> _live = [];
  bool _loading = false;
  String? _error;
  final _busy = <String>{};
  Timer? _poll;

  OwnerShop? _shop;
  bool _shopLoading = false;
  String? _shopError;

  /// Pending order ids from the last load, to spot newly arrived orders.
  Set<String>? _seenPending;

  List<_Order> get _orders => widget.isPreview
      ? _previewOrders
      : [for (final order in _live) _Order.live(order, _statusLabel(order))];

  int get _pending => _orders.where((order) => order.status == null).length;

  int get _todayCount {
    final now = DateTime.now();
    return _live
        .where(
          (o) =>
              o.createdAt.year == now.year &&
              o.createdAt.month == now.month &&
              o.createdAt.day == now.day,
        )
        .length;
  }

  bool get _isOpen => widget.isPreview || (_shop?.isOpen ?? false);

  Future<void> _loadShop() async {
    setState(() {
      _shopLoading = true;
      _shopError = null;
    });
    try {
      final shop = await OwnerShopService.myShop(client: widget.client);
      if (mounted) setState(() => _shop = shop);
    } on ShopException catch (e) {
      if (mounted) setState(() => _shopError = e.message);
    } finally {
      if (mounted) setState(() => _shopLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (!widget.isPreview) {
      _load();
      _loadShop();
      _poll = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _load(silent: true),
      );
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (!silent) _error = null;
    });
    try {
      final orders = await OwnerOrdersService.fetch(client: widget.client);
      if (!mounted) return;
      final pending = orders.where((o) => o.isPending).toList();
      final arrived = _seenPending == null
          ? const <OwnerOrder>[]
          : pending.where((o) => !_seenPending!.contains(o.id)).toList();
      _seenPending = {for (final o in pending) o.id};
      setState(() {
        _live = orders;
        _error = null;
      });
      if (arrived.isNotEmpty) _announce(arrived);
    } on OrdersException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      if (e.signedOut) _poll?.cancel();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statusLabel(OwnerOrder order) => switch (order.status) {
    'pending' => '',
    'accepted' when order.pickupTime != null =>
      'Accepted · Pickup ${TimeOfDay.fromDateTime(order.pickupTime!).format(context)}',
    'accepted' => 'Accepted',
    'cancelled' => 'Cancelled',
    final other => other[0].toUpperCase() + other.substring(1),
  };

  /// Tells the owner about orders that arrived since the last refresh.
  void _announce(List<OwnerOrder> arrived) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          arrived.length == 1
              ? 'New order from ${arrived.single.studentName}'
              : '${arrived.length} new orders',
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: HomeStyle.orange,
          onPressed: _showPending,
        ),
      ),
    );

  /// Opens the pending list, refreshing it first when live.
  void _showPending() {
    setState(() {
      _tab = 1;
      _history = false;
    });
    if (!widget.isPreview) _load(silent: true);
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _act(
    _Order order,
    Future<void> Function() call,
    String done,
  ) async {
    setState(() => _busy.add(order.serverId!));
    try {
      await call();
      if (!mounted) return;
      _toast(done);
      await _load(silent: true);
    } on OrdersException catch (e) {
      if (!mounted) return;
      _toast(e.message);
      if (e.stale) await _load(silent: true);
    } finally {
      if (mounted) setState(() => _busy.remove(order.serverId));
    }
  }

  // Dialogs open on the root navigator, so they need the app theme again.
  Future<T?> _dialog<T>({required WidgetBuilder builder}) => showDialog<T>(
    context: context,
    builder: (context) => Theme(
      data: HomeStyle.theme,
      child: Builder(builder: builder),
    ),
  );

  Future<void> _confirm(_Order order) async {
    final minutes = await _dialog<int>(
      builder: (context) => SimpleDialog(
        title: const Text('Ready for pickup in'),
        children: [
          for (final m in const [10, 15, 20, 30, 45, 60])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, m),
              child: Text('$m minutes'),
            ),
        ],
      ),
    );
    if (minutes == null || !mounted) return;
    await _act(
      order,
      () => OwnerOrdersService.accept(
        order.serverId!,
        minutes,
        client: widget.client,
      ),
      'Order #${order.id} accepted. The student has been notified.',
    );
  }

  Future<void> _reject(_Order order) async {
    final sure = await _dialog<bool>(
      builder: (context) => AlertDialog(
        title: const Text('Reject order?'),
        content: Text(
          'Order #${order.id} from ${order.name} will be cancelled and the student notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    await _act(
      order,
      () => OwnerOrdersService.reject(order.serverId!, client: widget.client),
      'Order #${order.id} rejected. The student has been notified.',
    );
  }

  void _respond(_Order order, String status) {
    setState(() => order.status = status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preview: ${order.id} ${status.toLowerCase()}. No customer was notified.',
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: HomeStyle.orange,
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
              ['Home', 'Orders', 'Profile'][_tab],
              style: const TextStyle(fontSize: 11, color: HomeStyle.muted),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _pending == 0
                ? 'No pending orders'
                : '$_pending pending ${_pending == 1 ? 'order' : 'orders'}',
            onPressed: _showPending,
            icon: Badge(
              isLabelVisible: _pending > 0,
              label: Text('$_pending'),
              backgroundColor: HomeStyle.orange,
              textColor: Colors.white,
              child: Icon(
                _pending > 0
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none,
                size: 20,
                color: _pending > 0 ? Colors.white : HomeStyle.muted,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          MenuManagementScreen(
            // Re-created when the shop appears, so the menu reloads.
            key: ValueKey(_shop?.id),
            onNavigate: (i) => setState(() => _tab = i),
            isPreview: widget.isPreview,
            shopName: _shop?.name,
            client: widget.client,
          ),
          RefreshIndicator(
            onRefresh: widget.isPreview ? () async {} : _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isPreview
                                  ? 'Shan Food Cabin'
                                  : _shop?.name ??
                                        (_shopLoading ? '' : 'No shop yet'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.isPreview
                                  ? 'Y junction'
                                  : _shop?.location ??
                                        (_shopLoading
                                            ? ''
                                            : 'Set it up in the Profile tab'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: HomeStyle.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isPreview || _shop != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.circle,
                          size: 7,
                          color: _isOpen ? HomeStyle.green : HomeStyle.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isOpen ? HomeStyle.green : HomeStyle.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Today's Overview", style: TextStyle(fontSize: 13)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        widget.isPreview ? 'Orders' : 'Orders today',
                        widget.isPreview ? '28' : '$_todayCount',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metric('Pending', '$_pending new', accent: true),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.isPreview)
                  const Text(
                    'Preview · Sample orders only',
                    style: TextStyle(fontSize: 10, color: HomeStyle.muted),
                  )
                else if (_error != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: HomeStyle.orange,
                          ),
                        ),
                      ),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  )
                else if (_loading && _live.isEmpty)
                  const LinearProgressIndicator(minHeight: 2),
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
                      ) &&
                      !(_loading && _live.isEmpty))
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
          ),
          ShopProfileScreen(
            isPreview: widget.isPreview,
            shop: _shop,
            shopLoading: _shopLoading,
            shopError: _shopError,
            onShopChanged: (shop) => setState(() => _shop = shop),
            onRetry: _loadShop,
            client: widget.client,
            onManageMenu: () => setState(() => _tab = 0),
            onAccount: () {
              if (widget.isPreview) {
                Navigator.pop(context);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => Theme(
                      data: HomeStyle.theme,
                      child: Scaffold(
                        appBar: AppBar(title: const Text('Account')),
                        body: const ProfileScreen(),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
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
        if (order.note != null && order.note!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Note: ${order.note}',
            style: const TextStyle(fontSize: 12, color: HomeStyle.muted),
          ),
        ],
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _lkr(order.total),
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
                  onPressed: _busy.contains(order.serverId)
                      ? null
                      : () => widget.isPreview
                            ? _respond(order, 'Rejected')
                            : _reject(order),
                  child: const Text('Reject', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _busy.contains(order.serverId)
                      ? null
                      : () => widget.isPreview
                            ? _respond(order, 'Confirmed')
                            : _confirm(order),
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
            widget.isPreview ? '${order.status} · Preview' : order.status!,
            style: const TextStyle(color: HomeStyle.orange, fontSize: 12),
          ),
      ],
    ),
  );
}

String _lkr(num value) {
  final text = value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(2);
  final parts = text.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return 'LKR $whole${parts.length > 1 ? '.${parts[1]}' : ''}';
}

String _ago(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class _Order {
  _Order(this.id, this.name, this.items, this.total, this.time)
    : serverId = null,
      note = null;

  _Order.live(OwnerOrder order, String label)
    : id = order.shortId,
      name = order.studentName,
      items = order.items,
      total = order.total,
      time = _ago(order.createdAt),
      serverId = order.id,
      note = order.note,
      status = order.isPending ? null : label;

  final String id, name, items, time;
  final num total;

  /// The order's UUID on the server; null for preview orders.
  final String? serverId, note;

  /// Null while pending; otherwise the label shown in history.
  String? status;
}
