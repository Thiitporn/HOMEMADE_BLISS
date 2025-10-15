import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final double price;
  final List<Map<String, dynamic>> variants;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.price,
    required this.variants,
  });
}

class ProductController extends ChangeNotifier {
  List<Product> products = [];

  Future<void> fetchProducts() async {
    // ตัวอย่าง mock data พร้อมข้อมูลครบ
    products = [
      Product(
        id: '1',
        name: 'Cheese Cupcake',
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
        description: 'คัพเค้กชีสเนื้อนุ่ม หอมมัน อร่อยลงตัว',
        price: 20.0,
        variants: [
          {'name': 'ปกติ', 'price': 20.0},
          {'name': 'เพิ่มชีส', 'price': 25.0},
        ],
      ),
      Product(
        id: '2',
        name: 'Strawberry Tart',
        imageUrl: 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c',
        description: 'ทาร์ตสตรอว์เบอร์รี่สดใหม่ รสเปรี้ยวหวาน',
        price: 35.0,
        variants: [
          {'name': 'ปกติ', 'price': 35.0},
        ],
      ),
      Product(
        id: '3',
        name: 'Chocolate Cookie',
        imageUrl: 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c',
        description: 'คุกกี้ช็อกโกแลตเข้มข้น กรอบนอกนุ่มใน',
        price: 15.0,
        variants: [
          {'name': 'ปกติ', 'price': 15.0},
        ],
      ),
    ];
    notifyListeners();
  }
}
