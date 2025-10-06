import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';

/// ตัวจัดการสินค้า (ProductController)
class ProductController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  final List<Product> _products = [
    Product(
      id: '1',
      name: 'Soft Cookie',
      description: 'คุกกี้นุ่มโฮมเมด',
      price: 59.0,
      imageUrl: 'https://via.placeholder.com/150',
      variants: ['ช็อกโกแลต', 'แมคคาเดเมีย'],
      stock: 10,
    ),
    Product(
      id: '2',
      name: 'Brownie',
      description: 'บราวนี่เข้มข้น',
      price: 79.0,
      imageUrl: 'https://via.placeholder.com/150',
      variants: ['อัลมอนด์', 'ช็อกโกแลต'],
      stock: 8,
    ),
  ];

  List<Product> get products => _products;

  // โหลดข้อมูลจาก Firestore มาเก็บใน _products
  Future<void> loadProductsFromCloud() async {
    try {
      final snap = await _db.collection('products').get();
      _products.clear();
      _products.addAll(snap.docs.map((doc) =>
        Product.fromFirestore(doc.data(), doc.id)
      ));
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