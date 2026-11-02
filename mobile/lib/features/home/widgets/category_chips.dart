import 'package:flutter/material.dart';

import '../home_style.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, i) => Center(
        child: ChoiceChip(
          label: Text(categories[i]),
          selected: categories[i] == selected,
          onSelected: (_) => onSelected(categories[i]),
          showCheckmark: false,
          backgroundColor: HomeStyle.surface,
          selectedColor: HomeStyle.orange,
          side: BorderSide(
            color: categories[i] == selected
                ? HomeStyle.orange
                : HomeStyle.border,
          ),
          shape: const StadiumBorder(),
          labelStyle: TextStyle(
            fontSize: 14,
            color: categories[i] == selected ? Colors.white : HomeStyle.muted,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          visualDensity: VisualDensity.compact,
        ),
      ),
    ),
  );
}
