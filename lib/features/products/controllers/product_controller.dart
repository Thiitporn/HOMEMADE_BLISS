import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';

/// ตัวจัดการสินค้า (ProductController)
class ProductController extends ChangeNotifier {
  /// ลด stock สินค้าแบบ static (เรียกใช้จากที่ไหนก็ได้)
  static Future<void> decrementStock(String productId, int qty, {String? variantName}) async {
    final db = FirebaseFirestore.instance;
    final docRef = db.collection('products').doc(productId);
    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
  final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};

      final rawStock = data['stock'];
      final currentStock = rawStock is num ? rawStock.toInt() : 0;
      final nextStock = (currentStock - qty).clamp(0, 1 << 30);

      final updates = <String, dynamic>{'stock': nextStock};

      final targetVariant = variantName?.trim();
      if (targetVariant != null && targetVariant.isNotEmpty && data['variants'] is List) {
        final variants = (data['variants'] as List)
            .whereType<Map<dynamic, dynamic>>()
            .map((variant) => variant.map((key, value) => MapEntry(key.toString(), value)))
            .toList(growable: false);

        final index = variants.indexWhere(
          (variant) => (variant['name'] ?? '').toString().trim() == targetVariant,
        );

        if (index >= 0) {
          final variantData = Map<String, dynamic>.from(variants[index]);
          final rawVariantStock = variantData['stock'];
          final variantStock = rawVariantStock is num ? rawVariantStock.toInt() : 0;
          variantData['stock'] = (variantStock - qty).clamp(0, 1 << 30);

          final updatedVariants = List<Map<String, dynamic>>.from(variants);
          updatedVariants[index] = variantData;
          updates['variants'] = updatedVariants;
        }
      }

      transaction.update(docRef, updates);
    });
  }
  final _db = FirebaseFirestore.instance;

  final List<Product> _products = [
    Product(
      id: '1',
      name: 'Soft Cookie',
      description: 'คุกกี้นุ่มโฮมเมด',
      price: 59.0,
      imageUrl: 'https://via.placeholder.com/150',
      variants: [
        ProductVariant(name: 'ช็อกโกแลต', price: 59.0, stock: 5),
        ProductVariant(name: 'แมคคาเดเมีย', price: 69.0, stock: 3),
      ],
      stock: 8,
    ),
    Product(
      id: '2',
      name: 'Brownie',
      description: 'บราวนี่เข้มข้น',
      price: 79.0,
      imageUrl: 'https://via.placeholder.com/150',
      variants: [
        ProductVariant(name: 'อัลมอนด์', price: 79.0, stock: 4),
        ProductVariant(name: 'ช็อกโกแลต', price: 89.0, stock: 2),
      ],
      stock: 6,
    ),
  ];

  List<Product> get products => _products;

  // โหลดข้อมูลจาก Firestore มาเก็บใน _products
  Future<void> loadProductsFromCloud() async {
    try {
      final snap = await _db.collection('products').get();
      _products.clear();
      _products.addAll(snap.docs.map((doc) {
        final product = Product.fromFirestore(doc.data(), doc.id);
        debugPrint('Product: ${product.name}, variants: ${product.variants.map((v) => v.name).toList()}');
        return product;
      }));
      notifyListeners();
    } catch (e) {
      debugPrint('Load products error: $e');
    }
  }

  // เพิ่มสินค้าใหม่
  Future<void> addProduct(Product p) async {
    try {
      await _db.collection('products').add(p.toMap());
      await loadProductsFromCloud();
    } catch (e) {
      debugPrint('Add product error: $e');
    }
  }

  // แก้ไขสินค้า
  Future<void> updateProduct(Product p) async {
    try {
      await _db.collection('products').doc(p.id).update(p.toMap());
      await loadProductsFromCloud();
    } catch (e) {
      debugPrint('Update product error: $e');
    }
  }

  // ลบสินค้า
  Future<void> deleteProduct(String id) async {
    try {
      await _db.collection('products').doc(id).delete();
      await loadProductsFromCloud();
    } catch (e) {
      debugPrint('Delete product error: $e');
    }
  }
}