import 'package:flutter/foundation.dart';

import 'tray.dart';

enum OrderStatus { pending, confirmed, preparing, ready, rejected, cancelled }

class OrderLine {
  const OrderLine(
    this.name,
    this.quantity,
    this.price, {
    this.image,
    this.description = '',
  });
  final String name, description;
  final String? image;
  final int quantity, price;
  int get total => quantity * price;
}

class PreviewOrder {
  PreviewOrder({
    required this.id,
    required this.shop,
    required this.lines,
    required this.status,
    required this.createdAt,
    this.packaging = 40,
  });
  final String id, shop;
  final List<OrderLine> lines;
  final DateTime createdAt;
  final int packaging;
  OrderStatus status;
  bool get closed =>
      status == OrderStatus.rejected || status == OrderStatus.cancelled;
  int get subtotal => lines.fold(0, (sum, line) => sum + line.total);
  int get total => subtotal + packaging;
  String get label => status.name[0].toUpperCase() + status.name.substring(1);
  String get dateLabel =>
      '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} · ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
}

/// Entirely local preview data. No order is transmitted to a shop.
class PreviewOrders extends ChangeNotifier {
  static final instance = PreviewOrders();
  PreviewOrders() {
    reset();
  }
  final List<PreviewOrder> orders = [];
  int _next = 1050;
  void reset() {
    orders.clear();
    _next = 1050;
    const meal = [
      OrderLine(
        'Chicken Fried Rice',
        1,
        560,
        image: 'assets/food/rice.jpg',
        description: 'SUSL Special · Sunny Egg',
      ),
      OrderLine(
        'Vegetable Samosa',
        2,
        150,
        image: 'assets/food/samosa.jpg',
        description: '2 pcs portion · LKR 150 each',
      ),
    ];
    orders.addAll([
      PreviewOrder(
        id: 'MM-1049',
        shop: 'Shan Food Cabin',
        lines: meal,
        status: OrderStatus.preparing,
        createdAt: DateTime(2026, 10, 8, 12, 40),
      ),
      PreviewOrder(
        id: 'MM-1047',
        shop: 'Shan Food Cabin',
        lines: const [OrderLine('Chicken Kottu + Lime Juice', 1, 710)],
        status: OrderStatus.confirmed,
        createdAt: DateTime(2026, 10, 8, 12, 28),
      ),
      PreviewOrder(
        id: 'MM-1046',
        shop: 'Eat Art',
        lines: const [OrderLine('Rice & Curry + Iced Tea', 1, 580)],
        status: OrderStatus.ready,
        createdAt: DateTime(2026, 10, 8, 12, 15),
      ),
      PreviewOrder(
        id: 'MM-1029',
        shop: 'Royal Box',
        lines: const [OrderLine('Vegetable Rice & Curry', 2, 400)],
        status: OrderStatus.rejected,
        createdAt: DateTime(2026, 10, 7, 13, 10),
        packaging: 0,
      ),
      PreviewOrder(
        id: 'MM-1038',
        shop: 'Shan Food Cabin',
        lines: meal,
        status: OrderStatus.cancelled,
        createdAt: DateTime(2026, 10, 8, 11, 45),
      ),
    ]);
    notifyListeners();
  }

  PreviewOrder place(Tray tray) {
    if (tray.count == 0) throw StateError('Cannot place an empty tray.');
    final order = PreviewOrder(
      id: 'MM-${_next++}',
      shop: tray.shop.name,
      lines: List.unmodifiable(
        tray.items.map(
          (item) => OrderLine(
            item.name,
            tray.quantity(item),
            item.price,
            image: item.image,
            description: item.description,
          ),
        ),
      ),
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      packaging: tray.packaging,
    );
    orders.insert(0, order);
    tray.clear();
    notifyListeners();
    return order;
  }

  void advance(PreviewOrder order) {
    if (order.status.index >= OrderStatus.ready.index) return;
    order.status = OrderStatus.values[order.status.index + 1];
    notifyListeners();
  }

  void cancel(PreviewOrder order) {
    if (order.status != OrderStatus.pending) return;
    order.status = OrderStatus.cancelled;
    notifyListeners();
  }
}
