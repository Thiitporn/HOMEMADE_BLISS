import 'package:cloud_firestore/cloud_firestore.dart';

/// โครงสร้างข้อมูลสินค้า (Product model)
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> variants;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.variants,
    required this.stock,
  });

  // สำหรับแปลงข้อมูลจาก Firestore
  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      variants: List<String>.from(data['variants'] ?? []),
      stock: data['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'variants': variants,
    'stock': stock,
  };
}