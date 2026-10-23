import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../home/home_style.dart';
import 'tray.dart';

class FoodPhoto extends StatelessWidget {
  final FoodItem item;
  final double size;
  const FoodPhoto({super.key, required this.item, this.size = 94});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.asset(
      item.image,
      width: size,
      height: size,
      fit: BoxFit.cover,
      semanticLabel: item.name,
      errorBuilder: (_, _, _) => SizedBox(
        width: size,
        height: size,
        child: const Icon(Icons.restaurant),
      ),
    ),
  );
}

class QuantityControl extends StatelessWidget {
  final Tray tray;
  final FoodItem item;
  final bool compact;
  const QuantityControl({
    super.key,
    required this.tray,
    required this.item,
    this.compact = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: HomeStyle.background,
      border: Border.all(color: HomeStyle.border),
      borderRadius: BorderRadius.circular(compact ? 8 : 24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(
          Icons.remove,
          'Decrease ${item.name}',
          () => tray.change(item, -1),
        ),
        SizedBox(
          width: 20,
          child: Text(
            '${tray.quantity(item)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        _button(
          Icons.add,
          'Increase ${item.name}',
          tray.quantity(item) < 20 ? () => tray.change(item, 1) : null,
        ),
      ],
    ),
  );
  Widget _button(IconData icon, String label, VoidCallback? action) => SizedBox(
    width: 32,
    height: 36,
    child: IconButton(
      padding: EdgeInsets.zero,
      tooltip: label,
      onPressed: action,
      icon: Icon(icon, size: 16),
      color: HomeStyle.muted,
    ),
  );
}

class OrderingHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? subtitle, shopName;
  final Widget? action;
  const OrderingHeader({super.key, this.subtitle, this.shopName, this.action});
  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 56 : 66);
  @override
  Widget build(BuildContext context) => AppBar(
    leadingWidth: 84,
    leading: Row(
      children: [
        const SizedBox(width: 16),
        Container(
          width: 30,
          height: 32,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: HomeStyle.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SvgPicture.asset(
            'assets/login/utensils.svg',
            colorFilter: const ColorFilter.mode(
              HomeStyle.orange,
              BlendMode.srcIn,
            ),
          ),
        ),
        Expanded(
          child: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
        ),
      ],
    ),
    centerTitle: true,
    title: Column(
      crossAxisAlignment: subtitle == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        const Text(
          'MealMate',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        if (shopName != null)
          Text(
            shopName!,
            style: const TextStyle(fontSize: 10, color: HomeStyle.muted),
          ),
      ],
    ),
    actions: [?action, const SizedBox(width: 12)],
  );
}

BoxDecoration orderPanel() => BoxDecoration(
  color: HomeStyle.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: HomeStyle.border),
);
