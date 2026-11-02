import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../auth/auth_service.dart';
import '../auth/profile_screen.dart';
import '../auth/student_profile_view.dart';
import '../ordering/student_orders_screen.dart';
import 'home_style.dart';
import '../ordering/shop_menu_screen.dart';
import '../ordering/tray.dart';
import 'models/shop.dart';
import 'widgets/category_chips.dart';
import 'widgets/shop_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.isPreview = false});
  final bool isPreview;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _categories = ['All', 'Rice & Curry', 'Short Eats', 'Beverages'];
  final _search = TextEditingController();
  final Map<String, Tray> _trays = {};
  String _selected = 'All';
  int _navIndex = 0;

  @override
  void dispose() {
    _search.dispose();
    for (final tray in _trays.values) {
      tray.dispose();
    }
    super.dispose();
  }

  void _explore() => setState(() {
    _navIndex = 1;
    _selected = 'All';
    _search.clear();
  });

  String get _greeting {
    if (widget.isPreview) return 'Preview mode · Sample menu';
    final hour = DateTime.now().hour;
    final period = hour < 12
        ? 'morning'
        : hour < 17
        ? 'afternoon'
        : 'evening';
    final name = (AuthService.user?['name'] as String? ?? '')
        .trim()
        .split(' ')
        .first;
    return 'Good $period${name.isEmpty ? '' : ', $name'}';
  }

  void _navigate(int index) {
    final route = ModalRoute.of(context);
    Navigator.of(context).popUntil((r) => r == route);
    setState(() => _navIndex = index);
  }

  void _viewShop(Shop shop) {
    final tray = _trays.putIfAbsent(shop.id, () => Tray(shop));
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ShopMenuScreen(tray: tray, onNavigate: _navigate),
      ),
    );
  }

  Widget _header() => Container(
    height: 80,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: HomeStyle.border)),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: HomeStyle.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/login/utensils.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  HomeStyle.orange,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'MealMate',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _navIndex == 3
                  ? 'Profile'
                  : _navIndex == 2
                  ? 'Orders'
                  : _greeting,
              style: const TextStyle(fontSize: 10, color: Color(0xFFD4D4D4)),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _shops() {
    final query = _search.text.trim().toLowerCase();
    final shops = mockShops
        .where(
          (shop) =>
              (_selected == 'All' || shop.category == _selected) &&
              '${shop.name} ${shop.category}'.toLowerCase().contains(query),
        )
        .toList();
    return ListView(
      key: const PageStorageKey('shop-list'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search food or canteens...',
                hintStyle: const TextStyle(
                  color: HomeStyle.muted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: HomeStyle.muted,
                ),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(_search.clear),
                      ),
                filled: true,
                fillColor: HomeStyle.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: HomeStyle.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: HomeStyle.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: HomeStyle.orange),
                ),
              ),
            ),
          ),
        ),
        CategoryChips(
          categories: _categories,
          selected: _selected,
          onSelected: (c) => setState(() => _selected = c),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _navIndex == 1 ? 'Explore shops' : 'Nearby Shops',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: _explore,
                style: TextButton.styleFrom(
                  foregroundColor: HomeStyle.orange,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 32),
                ),
                child: const Text('View all', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        if (shops.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.search_off, color: HomeStyle.muted, size: 36),
                SizedBox(height: 12),
                Text('No matching shops'),
                SizedBox(height: 8),
                Text(
                  'Try another search or category.',
                  style: TextStyle(color: HomeStyle.muted),
                ),
              ],
            ),
          )
        else
          ...shops.map(
            (shop) => ShopCard(shop: shop, onTap: () => _viewShop(shop)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: HomeStyle.theme,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: HomeStyle.background,
        systemNavigationBarColor: HomeStyle.surface,
      ),
      child: Scaffold(
        backgroundColor: HomeStyle.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(),
              Expanded(
                child: switch (_navIndex) {
                  3 =>
                    widget.isPreview
                        ? StudentProfileView(
                            isPreview: true,
                            user: const {
                              'name': 'Pamal Perera',
                              'email': 'pamal@example.com',
                              'phone': '+94 71 234 5678',
                            },
                            onLogout: () => Navigator.pop(context),
                            onOrders: () => setState(() => _navIndex = 2),
                          )
                        : ProfileScreen(
                            onOrders: () => setState(() => _navIndex = 2),
                          ),
                  2 => StudentOrdersScreen(onNavigate: _navigate),
                  _ => _shops(),
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: HomeStyle.border)),
          ),
          child: BottomNavigationBar(
            currentIndex: _navIndex,
            onTap: (index) => setState(() => _navIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: HomeStyle.surface,
            selectedItemColor: HomeStyle.orange,
            unselectedItemColor: HomeStyle.muted,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            iconSize: 20,
            elevation: 0,
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
      ),
    ),
  );
}
