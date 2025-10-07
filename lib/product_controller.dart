import 'package:flutter/material.dart';

class Product {
  final String name;
  final double price;
  Product({required this.name, required this.price});
}

class ProductController extends ChangeNotifier {
  List<Product> products = [];

  Future<void> fetchProducts() async {
    // ตัวอย่าง mock data
    products = [
      Product(name: 'Cheese Cupcake', price: 20.0),
      Product(name: 'Strawberry Tart', price: 35.0),
      Product(name: 'Chocolate Cookie', price: 15.0),
    ];
    notifyListeners();
  }
}
