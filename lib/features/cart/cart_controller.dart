import 'package:flutter/material.dart';

class CartItem {
  final String id; // simple id (e.g., name)
  final String name;
  final double price;
  final String? imageAsset;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.imageAsset,
    this.quantity = 1,
  });
}

class CartController extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  int get totalItems => _items.values.fold(0, (sum, i) => sum + i.quantity);
  double get totalPrice => _items.values.fold(0.0, (sum, i) => sum + i.price * i.quantity);

  void addItem({
    required String id,
    required String name,
    required double price,
    String? imageAsset,
    int qty = 1,
  }) {
    if (_items.containsKey(id)) {
      _items[id]!.quantity += qty;
    } else {
      _items[id] = CartItem(id: id, name: name, price: price, imageAsset: imageAsset, quantity: qty);
    }
    notifyListeners();
  }

  void removeOne(String id) {
    if (!_items.containsKey(id)) return;
    final item = _items[id]!;
    if (item.quantity > 1) {
      item.quantity -= 1;
    } else {
      _items.remove(id);
    }
    notifyListeners();
  }

  void removeAll(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
