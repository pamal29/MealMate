import 'package:flutter/foundation.dart';

import '../home/models/shop.dart';

/// Reads a price from the API, keeping whole rupees as `int`.
num parsePrice(Object? value) {
  final price = num.tryParse('$value') ?? 0;
  return price == price.roundToDouble() ? price.round() : price;
}

/// Formats a price without a trailing ".0", e.g. 480 or 480.50.
String money(num value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(2);

class FoodItem {
  final String id, name, description, category;
  final String? image;
  final num price;
  const FoodItem(
    this.id,
    this.name,
    this.description,
    this.category,
    this.price,
    this.image,
  );
}

const sampleMenu = [
  FoodItem(
    'rice',
    'Chicken Fried Rice (SUSL Special)',
    'Wok fried basmati rice with chicken and vegetables',
    'Rice & Curry',
    480,
    'assets/food/rice.jpg',
  ),
  FoodItem(
    'samosa',
    'Vegetable Samosa (2 pcs)',
    'Crispy pastry triangles filled with spiced vegetables',
    'Short Eats',
    150,
    'assets/food/samosa.jpg',
  ),
  FoodItem(
    'kothu',
    'Devilled Chicken Kothu',
    'Spicy chopped roti tossed with chicken',
    'Rice & Curry',
    550,
    'assets/food/kothu.jpg',
  ),
];

class Tray extends ChangeNotifier {
  final Shop shop;

  /// True for a real shop: the menu comes from the API and the order is
  /// sent to the backend, which does not charge for packaging.
  final bool live;
  Tray(this.shop, {this.live = false}) : menu = live ? const [] : sampleMenu;
  List<FoodItem> menu;
  final Map<String, int> _quantities = {};

  /// Replaces the menu, dropping anything no longer on sale.
  void setMenu(List<FoodItem> items) {
    menu = items;
    _quantities.removeWhere((id, _) => !items.any((item) => item.id == id));
    notifyListeners();
  }

  List<FoodItem> get items => menu.where((item) => quantity(item) > 0).toList();
  int quantity(FoodItem item) => _quantities[item.id] ?? 0;
  int get count => _quantities.values.fold(0, (sum, value) => sum + value);
  num get subtotal =>
      items.fold<num>(0, (sum, item) => sum + item.price * quantity(item));
  int get packaging => count == 0 || live ? 0 : 40;
  num get total => subtotal + packaging;
  void change(FoodItem item, int delta) {
    final next = (quantity(item) + delta).clamp(0, 20);
    if (next == 0) {
      _quantities.remove(item.id);
    } else {
      _quantities[item.id] = next;
    }
    notifyListeners();
  }

  void remove(FoodItem item) {
    _quantities.remove(item.id);
    notifyListeners();
  }

  void clear() {
    _quantities.clear();
    notifyListeners();
  }
}
