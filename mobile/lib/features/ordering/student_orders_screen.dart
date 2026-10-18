import 'package:flutter/material.dart';

import '../home/home_style.dart';

class StudentOrdersScreen extends StatefulWidget {
  const StudentOrdersScreen({super.key});
  @override
  State<StudentOrdersScreen> createState() => _StudentOrdersScreenState();
}

class _StudentOrdersScreenState extends State<StudentOrdersScreen> {
  bool _previous = false;
  static const _orders = [
    (
      'MM-1048',
      'Royal Box',
      '1 × Chicken Fried Rice · 2 × Samosa',
      900,
      'Pending',
    ),
    (
      'MM-1047',
      'Shan Food Cabin',
      '1 × Chicken Kottu · 1 × Lime Juice',
      750,
      'Confirmed',
    ),
    ('MM-1046', 'Eat Art', '1 × Rice & Curry · 1 × Iced Tea', 620, 'Ready'),
    ('MM-1029', 'Royal Box', '2 × Vegetable Rice & Curry', 800, 'Rejected'),
  ];
  Widget _card(int index) {
    final order = _orders[index];
    final color = index == 2
        ? HomeStyle.green
        : index == 3
        ? Colors.redAccent
        : HomeStyle.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: HomeStyle.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('#${order.$1} · ${order.$2}'),
            content: Text(
              '${order.$3}\n\n${order.$5} · LKR ${order.$4}\n\nSample order for preview only.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${order.$1}',
                      style: const TextStyle(
                        color: HomeStyle.muted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '• ${order.$5}',
                      style: TextStyle(color: color, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.$2,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: HomeStyle.muted,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.$3,
                style: const TextStyle(fontSize: 11, color: HomeStyle.muted),
              ),
              const Divider(height: 22, color: HomeStyle.border),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '08 Oct 2026 · 12:35 PM',
                      style: TextStyle(fontSize: 10, color: HomeStyle.muted),
                    ),
                  ),
                  Text(
                    'LKR ${order.$4}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      SegmentedButton<bool>(
        showSelectedIcon: false,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? HomeStyle.orange
                : HomeStyle.surface,
          ),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          side: WidgetStateProperty.all(
            const BorderSide(color: HomeStyle.border),
          ),
        ),
        segments: const [
          ButtonSegment(value: false, label: Text('Active 3')),
          ButtonSegment(value: true, label: Text('Previous')),
        ],
        selected: {_previous},
        onSelectionChanged: (v) => setState(() => _previous = v.first),
      ),
      const SizedBox(height: 12),
      const Text(
        'Preview · Sample orders',
        style: TextStyle(color: HomeStyle.muted, fontSize: 10),
      ),
      const SizedBox(height: 16),
      if (!_previous) ...[
        for (var i = 0; i < 3; i++) _card(i),
        Row(
          children: [
            const Expanded(
              child: Text(
                'PREVIOUS · MOST RECENT',
                style: TextStyle(fontSize: 11, color: HomeStyle.muted),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _previous = true),
              child: const Text('View all'),
            ),
          ],
        ),
      ],
      _card(3),
      const SizedBox(height: 12),
      const Text(
        'Collect your food when your order is ready.',
        textAlign: TextAlign.center,
        style: TextStyle(color: HomeStyle.muted, fontSize: 11),
      ),
    ],
  );
}
