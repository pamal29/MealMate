import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../home/home_style.dart';
import 'owner_shop_service.dart';

class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({
    super.key,
    required this.onManageMenu,
    required this.onAccount,
    this.isPreview = true,
    this.shop,
    this.shopLoading = false,
    this.shopError,
    this.onShopChanged,
    this.onRetry,
    this.client,
  });
  final VoidCallback onManageMenu, onAccount;

  /// Sample shop unless the owner dashboard passes false for a signed-in
  /// owner. Live mode shows the fields the backend stores (name, category,
  /// location, open/closed) and saves them to the API.
  final bool isPreview;

  /// The owner's shop; null when they have not created one yet.
  final OwnerShop? shop;
  final bool shopLoading;
  final String? shopError;
  final ValueChanged<OwnerShop>? onShopChanged;
  final VoidCallback? onRetry;

  /// HTTP client for the shop API; tests pass a mock.
  final http.Client? client;
  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  final _values = <String, String>{
    'Shop name': 'Shan Food Cabin',
    'Location': 'Y Junction · Belihuloya',
    'Description': 'Fresh rice, kothu and campus favourites, cooked with care. Your everyday stop at Y Junction.',
    'Phone': '+94 77 234 5678',
    'Email': 'shanfoodcabin@example.com',
  };
  final _hours = [
    const TimeOfDay(hour: 7, minute: 0),
    const TimeOfDay(hour: 19, minute: 0),
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 17, minute: 0),
  ];
  Future<void> _edit() async {
    final controllers = {
      for (final e in _values.entries)
        e.key: TextEditingController(text: e.value),
    };
    final form = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Shop Profile'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in controllers.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: e.value,
                      decoration: InputDecoration(labelText: e.key),
                      maxLines: e.key == 'Description' ? 3 : 1,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter ${e.key.toLowerCase()}.'
                          : e.key == 'Email' &&
                                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(v)
                          ? 'Enter a valid email.'
                          : null,
                    ),
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
            child: const Text('Save profile'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        for (final e in controllers.entries) {
          _values[e.key] = e.value.text.trim();
        }
      });
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final c in controllers.values) {
      c.dispose();
    }
  }

  Future<void> _editHours() async {
    final draft = List<TimeOfDay>.from(_hours);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Edit Opening Hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 4; i++)
                TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: draft[i],
                    );
                    if (time != null && context.mounted) {
                      update(() => draft[i] = time);
                    }
                  },
                  child: Text(
                    '${['Weekday opening', 'Weekday closing', 'Weekend opening', 'Weekend closing'][i]}: ${draft[i].format(context)}',
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save hours'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _hours.setAll(0, draft);
      });
    }
  }

  bool _saving = false;

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  /// Creates the shop (when there is none) or edits its details.
  Future<void> _editLive() async {
    final shop = widget.shop;
    final fields = {
      'Shop name': TextEditingController(text: shop?.name),
      'Category': TextEditingController(text: shop?.category),
      'Location': TextEditingController(text: shop?.location),
    };
    final form = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => Theme(
        data: HomeStyle.theme,
        child: AlertDialog(
          title: Text(shop == null ? 'Set up your shop' : 'Edit Shop Profile'),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in fields.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: e.value,
                      decoration: InputDecoration(
                        labelText: e.key,
                        hintText: e.key == 'Category'
                            ? 'e.g. Rice & Curry'
                            : null,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter ${e.key.toLowerCase()}.'
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: Text(shop == null ? 'Create shop' : 'Save profile'),
            ),
          ],
        ),
      ),
    );
    final name = fields['Shop name']!.text.trim();
    final category = fields['Category']!.text.trim();
    final location = fields['Location']!.text.trim();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final c in fields.values) {
      c.dispose();
    }
    if (saved != true || !mounted) return;
    setState(() => _saving = true);
    try {
      final updated = shop == null
          ? await OwnerShopService.createShop(
              name: name,
              category: category,
              location: location,
              client: widget.client,
            )
          : await OwnerShopService.updateShop(
              name: name,
              category: category,
              location: location,
              client: widget.client,
            );
      widget.onShopChanged?.call(updated);
      if (mounted) {
        _toast(shop == null ? 'Shop created.' : 'Shop profile saved.');
      }
    } on ShopException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setOpen(bool open) async {
    setState(() => _saving = true);
    try {
      final updated = await OwnerShopService.updateShop(
        isOpen: open,
        client: widget.client,
      );
      widget.onShopChanged?.call(updated);
      if (mounted) {
        _toast(
          open ? 'Shop is open for orders.' : 'Shop is closed for orders.',
        );
      }
    } on ShopException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _live() {
    final shop = widget.shop;
    if (widget.shopLoading && shop == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.shopError != null && shop == null) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Text(widget.shopError!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: widget.onRetry,
              child: const Text('Retry'),
            ),
          ),
          TextButton(onPressed: widget.onAccount, child: const Text('Account')),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: HomeStyle.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.storefront_outlined,
            size: 56,
            color: HomeStyle.orange,
          ),
        ),
        const SizedBox(height: 20),
        if (shop == null) ...[
          const Text(
            "You haven't set up your shop yet",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your shop so students can find it and you can add menu items.',
            style: TextStyle(color: HomeStyle.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _editLive,
            icon: const Icon(Icons.add_business_outlined, size: 18),
            label: const Text('Set up your shop'),
          ),
        ] else ...[
          Text(
            shop.name,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '${shop.category} · ${shop.location}',
            style: const TextStyle(color: HomeStyle.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          panel(
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  shop.isOpen ? 'Open for orders' : 'Closed for orders',
                  style: TextStyle(
                    color: shop.isOpen ? HomeStyle.green : HomeStyle.muted,
                  ),
                ),
                subtitle: const Text(
                  'Students cannot order while the shop is closed.',
                  style: TextStyle(fontSize: 10),
                ),
                value: shop.isOpen,
                activeTrackColor: HomeStyle.green,
                onChanged: _saving ? null : _setOpen,
              ),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: HomeStyle.surface),
            onPressed: _saving ? null : _editLive,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit Shop Profile'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: widget.onManageMenu,
            icon: const Icon(Icons.restaurant_menu, size: 18),
            label: const Text('Manage Menu'),
          ),
        ],
        TextButton(onPressed: widget.onAccount, child: const Text('Account')),
      ],
    );
  }

  Widget panel(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: HomeStyle.surface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
  @override
  Widget build(BuildContext context) => !widget.isPreview
      ? _live()
      : ListView(
          children: [
            Image.asset(
              'assets/shops/shan-food-cabin.jpg',
              height: 235,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _values['Shop name']!,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(
                        '• Open',
                        style: TextStyle(color: HomeStyle.green, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _values['Location']!,
                    style: const TextStyle(
                      color: HomeStyle.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _values['Description']!,
                    style: const TextStyle(
                      color: HomeStyle.muted,
                      fontSize: 12,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Preview · Sample shop, edits stay in this session',
                    style: TextStyle(color: HomeStyle.orange, fontSize: 10),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: HomeStyle.surface,
                    ),
                    onPressed: _edit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Shop Profile'),
                  ),
                  const SizedBox(height: 18),
                  panel(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Opening hours',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 14),
                        for (var i = 0; i < 2; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    i == 0
                                        ? 'Monday – Friday'
                                        : 'Saturday – Sunday',
                                    style: const TextStyle(
                                      color: HomeStyle.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_hours[i * 2].format(context)} – ${_hours[i * 2 + 1].format(context)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        TextButton(
                          onPressed: _editHours,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Edit Opening Hours',
                                style: TextStyle(fontSize: 12),
                              ),
                              Icon(Icons.chevron_right, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  panel(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contact information'),
                        const SizedBox(height: 16),
                        Text(
                          'Phone\n${_values['Phone']}',
                          style: const TextStyle(fontSize: 12, height: 1.6),
                        ),
                        const Divider(height: 26, color: HomeStyle.border),
                        Text(
                          'Email\n${_values['Email']}',
                          style: const TextStyle(fontSize: 12, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: widget.onManageMenu,
                    icon: const Icon(Icons.restaurant_menu, size: 18),
                    label: const Text('Manage Menu'),
                  ),
                  TextButton(
                    onPressed: widget.onAccount,
                    child: const Text('Account / Back to login'),
                  ),
                ],
              ),
            ),
          ],
        );
}
