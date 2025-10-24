// CartItem model for variant-aware cart
// TODO(doc): ใช้ CartItem สำหรับเก็บสินค้าในตะกร้าแบบแยกตามตัวเลือก

class CartItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final String? variantName; // null ถ้าไม่มีตัวเลือก
  final num unitPrice; // variant.price หรือ product.price
  int qty;
  CartItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    this.variantName,
    required this.unitPrice,
    required this.qty,
  });
  String get uniqueKey => '$productId::${variantName ?? ""}';

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'variantName': variantName,
      'unitPrice': unitPrice,
      'qty': qty,
    };
    // Remove any key with null value
    map.removeWhere((key, value) => value == null);
    return map;
  }
}
