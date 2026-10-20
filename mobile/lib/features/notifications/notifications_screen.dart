import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../home/home_style.dart';
import 'notifications_service.dart';

/// The signed-in student's order notifications.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.client});

  /// HTTP client for the notifications API; tests pass a mock.
  final http.Client? client;

  /// Opens the screen with the app's dark theme.
  static Future<void> open(BuildContext context, {http.Client? client}) =>
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => Theme(
            data: HomeStyle.theme,
            child: NotificationsScreen(client: client),
          ),
        ),
      );

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification>? _items;
  String? _error;
  bool _markingAll = false;

  int get _unread => _items?.where((n) => !n.isRead).length ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await NotificationsService.fetch(client: widget.client);
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
    } on NotificationsException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  /// Marks one notification as read, updating the list first so the tap
  /// feels instant, and undoing it if the server refuses.
  Future<void> _markRead(AppNotification item) async {
    if (item.isRead) return;
    setState(() => item.isRead = true);
    try {
      await NotificationsService.markRead(item.id, client: widget.client);
    } on NotificationsException catch (e) {
      if (!mounted) return;
      setState(() => item.isRead = false);
      _toast(e.message);
    }
  }

  Future<void> _markAllRead() async {
    final unread = _items!.where((n) => !n.isRead).toList();
    setState(() => _markingAll = true);
    try {
      for (final item in unread) {
        await NotificationsService.markRead(item.id, client: widget.client);
        if (!mounted) return;
        setState(() => item.isRead = true);
      }
    } on NotificationsException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [
        if (_unread > 0)
          TextButton(
            onPressed: _markingAll ? null : _markAllRead,
            child: const Text('Mark all read'),
          ),
        const SizedBox(width: 8),
      ],
    ),
    body: RefreshIndicator(onRefresh: _load, child: _body()),
  );

  Widget _body() {
    final items = _items;
    if (items == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items == null || (items.isEmpty && _error != null)) {
      return _message(
        Icons.cloud_off_outlined,
        _error!,
        action: TextButton(
          onPressed: () {
            setState(() => _error = null);
            _load();
          },
          child: const Text('Retry'),
        ),
      );
    }
    if (items.isEmpty) {
      return _message(
        Icons.notifications_none,
        "No notifications yet.\nYou'll be notified here when a shop accepts or cancels your order.",
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _tile(items[i]),
    );
  }

  /// Centered message that still allows pull-to-refresh.
  Widget _message(IconData icon, String text, {Widget? action}) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(32, 120, 32, 24),
    children: [
      Icon(icon, size: 44, color: HomeStyle.muted),
      const SizedBox(height: 16),
      Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: HomeStyle.muted, height: 1.5),
      ),
      if (action != null) ...[
        const SizedBox(height: 12),
        Center(child: action),
      ],
    ],
  );

  Widget _tile(AppNotification item) {
    final (icon, color) = switch (item.type) {
      'order_accepted' => (Icons.check_circle_outline, HomeStyle.green),
      'order_cancelled' => (Icons.cancel_outlined, HomeStyle.orange),
      _ => (Icons.notifications_none, HomeStyle.muted),
    };
    return Material(
      color: HomeStyle.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _markRead(item),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isRead ? HomeStyle.border : color.withAlpha(110),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _ago(item.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: HomeStyle.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: item.isRead
                            ? HomeStyle.muted
                            : const Color(0xFFD4D4D4),
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isRead) ...[
                const SizedBox(width: 10),
                Semantics(
                  key: const ValueKey('unread-dot'),
                  label: 'Unread',
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 8, color: HomeStyle.orange),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _ago(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
