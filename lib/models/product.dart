// Product & ProductVariant model for cart/variant selection
// TODO(doc): ใช้ ProductVariant สำหรับพาร์สตัวเลือกสินค้าและใช้งานใน Cart/BottomSheet

class ProductVariant {
  final String name;
  final num price;
  final int stock;
  const ProductVariant(
      {required this.name, required this.price, required this.stock});
  factory ProductVariant.fromMap(Map<String, dynamic> m) => ProductVariant(
      name: m['name'] ?? '', price: m['price'] ?? 0, stock: m['stock'] ?? 0);
  Map<String, dynamic> toMap() =>
      {'name': name, 'price': price, 'stock': stock};
}

class Product {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final num price;
  final int stock;
  final int totalStock;
  final List<ProductVariant> variants;
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.stock,
    required this.totalStock,
    required this.variants,
  });
  factory Product.fromFirestore(Map<String, dynamic> m, String id) => Product(
        id: id,
        name: m['name'] ?? '',
        description: m['description'] ?? '',
        imageUrl: m['imageUrl'] ?? '',
        price: m['price'] ?? 0,
        stock: m['stock'] ?? 0,
        totalStock: m['totalStock'] ?? 0,
        variants: (m['variants'] as List?)
                ?.map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
