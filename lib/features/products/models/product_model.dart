// ...
// import 'package:cloud_firestore/cloud_firestore.dart';

/// โครงสร้างข้อมูลสินค้า (Product model)
class ProductVariant {
  final String name;
  final double price;
  final int stock;
  ProductVariant({required this.name, required this.price, required this.stock});

  static ProductVariant fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<ProductVariant> variants;
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
    final variantList = (data['variants'] ?? []) as List;
    return Product(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      variants: variantList.map((v) => ProductVariant.fromMap(Map<String, dynamic>.from(v))).toList(),
      stock: data['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'variants': variants.map((v) => {
      'name': v.name,
      'price': v.price,
      'stock': v.stock,
    }).toList(),
    'stock': stock,
  };
}