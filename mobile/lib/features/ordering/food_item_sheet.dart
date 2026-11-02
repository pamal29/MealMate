import 'package:flutter/material.dart';

import '../home/home_style.dart';
import 'tray.dart';

Future<void> showFoodItem(
  BuildContext context,
  Tray tray,
  FoodItem item,
) async {
  var quantity = 1;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: HomeStyle.surface,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tray.shop.name,
                        style: const TextStyle(color: HomeStyle.muted),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close item',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    item.image,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'LKR ${item.price}',
                        style: const TextStyle(
                          color: HomeStyle.orange,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text(
                      '• Available',
                      style: TextStyle(color: HomeStyle.green, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ingredients',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: const TextStyle(color: HomeStyle.muted),
                ),
                const Divider(height: 32, color: HomeStyle.border),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Decrease item quantity',
                          onPressed: quantity > 1
                              ? () => setState(() => quantity--)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$quantity'),
                        IconButton.filled(
                          tooltip: 'Increase item quantity',
                          onPressed: quantity + tray.quantity(item) < 20
                              ? () => setState(() => quantity++)
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    FilledButton(
                      onPressed: tray.quantity(item) >= 20
                          ? null
                          : () {
                              tray.change(item, quantity);
                              Navigator.pop(context);
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            const Text('Add to Order'),
                            Text(
                              'LKR ${quantity * item.price}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
