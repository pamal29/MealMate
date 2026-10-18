import 'package:flutter/material.dart';

import '../home/home_style.dart';

class StudentProfileView extends StatefulWidget {
  const StudentProfileView({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onOrders,
    this.isPreview = false,
  });
  final Map<String, dynamic> user;
  final VoidCallback onLogout, onOrders;
  final bool isPreview;
  @override
  State<StudentProfileView> createState() => _StudentProfileViewState();
}

class _StudentProfileViewState extends State<StudentProfileView> {
  bool _notifications = true;
  String? _name, _phone;
  void _notice(String title, String message) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
  Future<void> _edit() async {
    if (!widget.isPreview) {
      _notice(
        'Edit Profile',
        'Profile updates are not connected yet. Your account has not changed.',
      );
      return;
    }
    final name = TextEditingController(
      text: _name ?? widget.user['name'] as String? ?? 'Student',
    );
    final phone = TextEditingController(
      text: _phone ?? widget.user['phone'] as String? ?? '',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit preview profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _name = name.text.trim().isEmpty ? 'Student' : name.text.trim();
        _phone = phone.text;
      });
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    phone.dispose();
  }

  Widget _panel(List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 22),
    decoration: BoxDecoration(
      color: HomeStyle.surface,
      border: Border.all(color: HomeStyle.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Column(children: children),
    ),
  );
  Widget _row(
    IconData icon,
    String title,
    VoidCallback action, {
    String? trailing,
  }) => ListTile(
    leading: Icon(icon, size: 20, color: HomeStyle.muted),
    title: Text(title, style: const TextStyle(fontSize: 14)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(fontSize: 11, color: HomeStyle.orange),
          ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, size: 18),
      ],
    ),
    onTap: action,
  );
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const CircleAvatar(
        radius: 38,
        backgroundColor: HomeStyle.surface,
        child: Icon(Icons.person, size: 50, color: HomeStyle.orange),
      ),
      const SizedBox(height: 14),
      Text(
        _name ?? widget.user['name'] as String? ?? 'Student',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Text(
        widget.isPreview
            ? 'Student · Sabaragamuwa University · Preview'
            : '${widget.user['role'] == 'shop_owner' ? 'Shop owner' : 'Student'} · Sabaragamuwa University',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: HomeStyle.muted),
      ),
      const SizedBox(height: 26),
      _panel([
        ListTile(
          leading: const Icon(Icons.mail_outline, size: 20),
          title: const Text(
            'Email',
            style: TextStyle(color: HomeStyle.muted, fontSize: 11),
          ),
          subtitle: Text(widget.user['email'] as String? ?? 'Not provided'),
        ),
        const Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: HomeStyle.border,
        ),
        ListTile(
          leading: const Icon(Icons.phone_outlined, size: 20),
          title: const Text(
            'Phone number',
            style: TextStyle(color: HomeStyle.muted, fontSize: 11),
          ),
          subtitle: Text(
            _phone ?? widget.user['phone'] as String? ?? 'Not provided',
          ),
        ),
      ]),
      _panel([
        _row(
          Icons.receipt_long_outlined,
          'My Orders',
          widget.onOrders,
          trailing: '3 sample',
        ),
        _row(
          Icons.notifications_none,
          'Notifications',
          () => _notice(
            'Notifications',
            _notifications
                ? 'No new notifications. Live notifications are not connected.'
                : 'Preview alerts are disabled.',
          ),
        ),
        _row(Icons.manage_accounts_outlined, 'Edit Profile', _edit),
        _row(
          Icons.settings_outlined,
          'Settings',
          () => showDialog<void>(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (context, update) => AlertDialog(
                title: const Text('Preview settings'),
                content: SwitchListTile(
                  title: const Text('Show preview alerts'),
                  value: _notifications,
                  onChanged: (v) {
                    setState(() => _notifications = v);
                    update(() {});
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
      OutlinedButton.icon(
        onPressed: widget.onLogout,
        icon: const Icon(Icons.logout, size: 18),
        label: Text(widget.isPreview ? 'Back to login' : 'Logout'),
      ),
      const SizedBox(height: 34),
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'MealMate',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(width: 8),
          Text('SUSL', style: TextStyle(color: HomeStyle.orange, fontSize: 11)),
        ],
      ),
    ],
  );
}
