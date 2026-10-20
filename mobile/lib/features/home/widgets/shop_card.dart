import 'package:flutter/material.dart';

import '../home_style.dart';
import '../models/shop.dart';

class ShopCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback? onTap;
  const ShopCard({super.key, required this.shop, this.onTap});

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
    return Container(
      height: largeText ? 212 : 170,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      decoration: BoxDecoration(
        color: HomeStyle.surface,
        border: Border.all(color: HomeStyle.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              shop.imageAsset,
              width: MediaQuery.sizeOf(context).width < 350 ? 90 : 112,
              height: double.infinity,
              fit: BoxFit.cover,
              semanticLabel: '${shop.name} restaurant',
              errorBuilder: (_, _, _) => const SizedBox(
                width: 112,
                child: Icon(Icons.restaurant, color: HomeStyle.muted),
              ),
            ),
          ),
          const SizedBox(width: 36),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                Text(
                  shop.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: shop.isOpen ? HomeStyle.green : HomeStyle.muted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${shop.isOpen ? 'Open' : 'Closed'} • ${shop.preparationTime}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: HomeStyle.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: HomeStyle.orange.withValues(alpha: .18),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('View', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
