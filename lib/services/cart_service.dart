// CartService for add-to-cart with variant support
// TODO(doc): ใช้ CartService.addToCart สำหรับเพิ่มสินค้าลงตะกร้าแบบเลือกตัวเลือก

import 'package:flutter/material.dart';
import '../features/products/models/product_model.dart';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  List<CartItem> get items => _items.values.toList();

  void addToCart(Product product, {ProductVariant? variant, int qty = 1}) {
    final maxQty = (variant?.stock ?? product.stock) < 10
        ? (variant?.stock ?? product.stock)
        : 10;
    if (maxQty == 0) return; // บล็อกถ้าสต็อกหมด
    final key = '${product.id}::${variant?.name ?? ""}';
    final unitPrice = variant?.price ?? product.price;
    if (_items.containsKey(key)) {
      final item = _items[key]!;
      item.qty = (item.qty + qty) > maxQty ? maxQty : (item.qty + qty);
    } else {
      _items[key] = CartItem(
        productId: product.id,
        productName: product.name,
        imageUrl: product.imageUrl,
        variantName: variant?.name,
        unitPrice: unitPrice,
        qty: qty > maxQty ? maxQty : qty,
      );
    }
    notifyListeners();
  }

  // ...existing methods (remove, clear, etc.)
}
