import 'package:flutter/foundation.dart';

import '../auth/auth_service.dart';
import 'preview_orders.dart';
import 'student_api.dart';
import 'tray.dart';

/// The signed-in student's real orders, shown through the same screens as
/// the preview orders.
class LiveOrders extends ChangeNotifier {
  static final instance = LiveOrders();

  final List<PreviewOrder> orders = [];
  bool loading = false;
  String? error;
  String? _token;

  Future<void> load() async {
    // Never show one student's orders to the next one on this device.
    if (_token != AuthService.token) {
      orders.clear();
      _token = AuthService.token;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await StudentApi.myOrders();
      orders
        ..clear()
        ..addAll(rows.map(_fromJson));
    } on StudentApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Sends the tray to the shop and empties it. Throws a
  /// [StudentApiException] and keeps the tray if the order is refused.
  Future<PreviewOrder> place(Tray tray) async {
    final row = await StudentApi.placeOrder(
      shopId: tray.shop.id,
      quantities: {for (final i in tray.items) i.id: tray.quantity(i)},
    );
    final order = _fromJson({
      ...row,
      'shop_name': tray.shop.name,
      'items': [
        for (final i in tray.items)
          {'name': i.name, 'quantity': tray.quantity(i), 'unit_price': i.price},
      ],
    });
    orders.insert(0, order);
    tray.clear();
    notifyListeners();
    return order;
  }

  /// Students can only cancel an order the shop has not answered yet.
  Future<void> cancel(PreviewOrder order) async {
    await StudentApi.cancelOrder(order.serverId!);
    order.status = OrderStatus.cancelled;
    notifyListeners();
  }

  static PreviewOrder _fromJson(Map<String, dynamic> json) {
    final id = '${json['id']}';
    return PreviewOrder(
      id: id.split('-').first.toUpperCase(),
      serverId: id,
      shop: json['shop_name'] as String? ?? 'Shop',
      lines: [
        for (final line
            in (json['items'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>())
          OrderLine(
            line['name'] as String? ?? 'Item',
            (line['quantity'] as num?)?.toInt() ?? 1,
            parsePrice(line['unit_price']),
          ),
      ],
      status: switch (json['status']) {
        'accepted' => OrderStatus.confirmed,
        'rejected' => OrderStatus.rejected,
        'cancelled' => OrderStatus.cancelled,
        _ => OrderStatus.pending,
      },
      createdAt:
          DateTime.tryParse('${json['created_at']}')?.toLocal() ??
          DateTime.now(),
      pickupTime: DateTime.tryParse('${json['pickup_time']}')?.toLocal(),
      serverTotal: parsePrice(json['total']),
      packaging: 0,
    );
  }
}
