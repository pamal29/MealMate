import 'package:flutter/material.dart';
import '../../core/colors.dart';
import 'models/shop.dart';
import 'widgets/category_chips.dart';
import 'widgets/shop_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _categories = [
    'All', 'Rice & Curry', 'Snacks', 'Beverages', 'Fast Food'
  ];
  String _selected = 'All';
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final shops = _selected == 'All'
        ? mockShops
        : mockShops.where((s) => s.category == _selected).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MealMate',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.primary)),
        actions: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined)),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Hungry? 👋',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Pre-order and skip the queue',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search shops or food',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          CategoryChips(
            categories: _categories,
            selected: _selected,
            onSelected: (c) => setState(() => _selected = c),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Campus shops',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
          if (shops.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: Text('No shops in this category',
                      style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            ...shops.map((s) => ShopCard(shop: s, onTap: () {})),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
              label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.primary),
              label: 'Profile'),
        ],
      ),
    );
  }
}