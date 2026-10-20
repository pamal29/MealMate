import 'package:flutter/foundation.dart';

import '../home/models/shop.dart';

class FoodItem {
  final String id, name, description, category, image;
  final int price;
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
  Tray(this.shop);
  final Map<String, int> _quantities = {};
  List<FoodItem> get items =>
      sampleMenu.where((item) => quantity(item) > 0).toList();
  int quantity(FoodItem item) => _quantities[item.id] ?? 0;
  int get count => _quantities.values.fold(0, (sum, value) => sum + value);
  int get subtotal =>
      items.fold(0, (sum, item) => sum + item.price * quantity(item));
  int get packaging => count == 0 ? 0 : 40;
  int get total => subtotal + packaging;
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
