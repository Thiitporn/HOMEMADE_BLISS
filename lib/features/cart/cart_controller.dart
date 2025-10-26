import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String id; // simple id (e.g., name)
  final String name;
  final double price;
  final String? imageAsset;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.imageAsset,
    this.imageUrl,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageAsset': imageAsset,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      imageAsset: map['imageAsset'] as String?,
      imageUrl: map['imageUrl'] as String?,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class CartController extends ChangeNotifier {
  static const _storageKey = 'cart_items';
  final Map<String, CartItem> _items = {};

  CartController() {
    _restoreCart();
  }

  List<CartItem> get items => _items.values.toList();
  int get totalItems => _items.values.fold(0, (sum, i) => sum + i.quantity);
  double get totalPrice => _items.values.fold(0.0, (sum, i) => sum + i.price * i.quantity);

  Future<void> _restoreCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      _items.clear();
      for (final entry in decoded) {
        if (entry is Map<String, dynamic>) {
          final item = CartItem.fromMap(entry);
          _items[item.id] = item;
        }
      }
      notifyListeners();
    } catch (_) {
      // In case of corrupted data, clear storage silently.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    }
  }

  Future<void> _persistCart() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _items.values.map((item) => item.toMap()).toList();
    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  void addItem({
    required String id,
    required String name,
    required double price,
    String? imageAsset,
    String? imageUrl,
    int qty = 1,
  }) {
    if (_items.containsKey(id)) {
      _items[id]!.quantity += qty;
    } else {
      _items[id] = CartItem(
        id: id,
        name: name,
        price: price,
        imageAsset: imageAsset,
        imageUrl: imageUrl,
        quantity: qty,
      );
    }
    notifyListeners();
    _persistCart();
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
    _persistCart();
  }

  void removeAll(String id) {
    _items.remove(id);
    notifyListeners();
    _persistCart();
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _persistCart();
  }
}
