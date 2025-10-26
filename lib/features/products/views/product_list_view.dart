import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/cart_service.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';

/// หน้ารายการสินค้า
class ProductListView extends StatefulWidget {
  const ProductListView({super.key});

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      context.read<ProductController>().loadProductsFromCloud()
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductController>().products;
    final cartService = Provider.of<CartService>(context, listen: false);
    final Color darkBrown = const Color(0xFF4E342E);
    final Color mediumBrown = const Color(0xFF8D6E63);
    final Color lightBorder = const Color(0xFFD7CCC8);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF3EF),
        elevation: 0,
        title: Text(
          'สินค้า',
          style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold),
        ),
      ),
      body: products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = products[i];
                final hasVariants = p.variants.isNotEmpty;
                final variantChips = p.variants
                    .where((v) => v.name.isNotEmpty)
                    .map((v) => _InfoPill(
                          label: '${v.name} ฿${v.price.toStringAsFixed(2)}',
                          icon: Icons.analytics_outlined,
                          color: mediumBrown,
                        ))
                    .toList();
                final bool canAddToCart = hasVariants
                    ? p.variants.any((v) => v.stock > 0)
                    : p.stock > 0;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lightBorder.withOpacity(0.65)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.035),
                        offset: const Offset(0, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CustomerProductThumbnail(imageUrl: p.imageUrl),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: darkBrown,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (p.description.trim().isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      p.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 11,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _InfoPill(
                                        label: '฿${p.price.toStringAsFixed(2)}',
                                        icon: Icons.sell_outlined,
                                        color: darkBrown,
                                      ),
                                      _InfoPill(
                                        label: 'สต็อก ${p.stock}',
                                        icon: Icons.inventory_2_outlined,
                                        color: Colors.teal.shade700,
                                      ),
                                      ...variantChips,
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mediumBrown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: Text(canAddToCart ? 'เพิ่มลงตะกร้า' : 'สินค้าหมด'),
                            onPressed: canAddToCart
                                ? () {
                                    if (hasVariants) {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                        ),
                                        builder: (context) {
                                          ProductVariant? selectedVariant;
                                          int qty = 1;
                                          return StatefulBuilder(
                                            builder: (context, setState) {
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: MediaQuery.of(context)
                                                      .viewInsets
                                                      .bottom,
                                                  left: 12,
                                                  right: 12,
                                                  top: 12,
                                                ),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'เลือกตัวเลือกสินค้า',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    ...p.variants.map((v) {
                                                      final isAvailable = v.stock > 0;
                                                      final bool isSelected = selectedVariant == v;
                                                      return Padding(
                                                        padding: const EdgeInsets.only(bottom: 6),
                                                        child: InkWell(
                                                          onTap: isAvailable
                                                              ? () {
                                                                  setState(() {
                                                                    selectedVariant = v;
                                                                    qty = 1;
                                                                  });
                                                                }
                                                              : null,
                                                          borderRadius: BorderRadius.circular(10),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              color: isSelected
                                                                  ? mediumBrown.withOpacity(0.08)
                                                                  : Colors.white,
                                                              borderRadius: BorderRadius.circular(10),
                                                              border: Border.all(
                                                                color: isSelected
                                                                    ? mediumBrown
                                                                    : lightBorder.withOpacity(0.7),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 6,
                                                            ),
                                                            child: Row(
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                Transform.scale(
                                                                  scale: 0.8,
                                                                  child: Radio<ProductVariant>(
                                                                    value: v,
                                                                    groupValue: selectedVariant,
                                                                    materialTapTargetSize:
                                                                        MaterialTapTargetSize.shrinkWrap,
                                                                    onChanged: isAvailable
                                                                        ? (val) {
                                                                            setState(() {
                                                                              selectedVariant = val;
                                                                              qty = 1;
                                                                            });
                                                                          }
                                                                        : null,
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 6),
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment.start,
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Text(
                                                                        v.name,
                                                                        style: TextStyle(
                                                                          fontSize: 12,
                                                                          fontWeight: FontWeight.w600,
                                                                          color: isAvailable
                                                                              ? darkBrown
                                                                              : Colors.grey.shade500,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 2),
                                                                      Text(
                                                                        '฿${v.price.toStringAsFixed(2)} • คงเหลือ ${v.stock}',
                                                                        style: TextStyle(
                                                                          fontSize: 10,
                                                                          color: isAvailable
                                                                              ? Colors.grey.shade600
                                                                              : Colors.grey.shade400,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                    const SizedBox(height: 6),
                                                    if (selectedVariant != null)
                                                      Row(
                                                        children: [
                                                          const Text('จำนวน:', style: TextStyle(fontSize: 12)),
                                                          IconButton(
                                                            icon: const Icon(
                                                              Icons.remove,
                                                              size: 16,
                                                            ),
                                                            padding: EdgeInsets.zero,
                                                            visualDensity: VisualDensity.compact,
                                                            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                            onPressed: qty > 1
                                                                ? () => setState(
                                                                      () => qty--,
                                                                    )
                                                                : null,
                                                          ),
                                                          Text(
                                                            '$qty',
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(
                                                              Icons.add,
                                                              size: 16,
                                                            ),
                                                            padding: EdgeInsets.zero,
                                                            visualDensity: VisualDensity.compact,
                                                            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                            onPressed: qty <
                                                                    (selectedVariant!.stock < 10
                                                                        ? selectedVariant!.stock
                                                                        : 10)
                                                                ? () => setState(
                                                                      () => qty++,
                                                                    )
                                                                : null,
                                                          ),
                                                          Text(
                                                            '(สูงสุด ${selectedVariant!.stock < 10 ? selectedVariant!.stock : 10})',
                                                            style: const TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    const SizedBox(height: 10),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              mediumBrown,
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding:
                                                              const EdgeInsets.symmetric(vertical: 6),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(8),
                                                          ),
                                                          elevation: 0,
                                                        ),
                                                        onPressed:
                                                            selectedVariant != null
                                                                ? () {
                                                                    cartService.addToCart(
                                                                      p,
                                                                      variant:
                                                                          selectedVariant,
                                                                      qty: qty,
                                                                    );
                                                                    Navigator.pop(
                                                                        context);
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      const SnackBar(
                                                                        content: Text(
                                                                            'เพิ่มลงตะกร้าแล้ว'),
                                                                      ),
                                                                    );
                                                                  }
                                                                : null,
                                                        child:
                                                            const Text('เพิ่มลงตะกร้า', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    } else {
                                      cartService.addToCart(p, qty: 1);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('เพิ่มลงตะกร้าแล้ว'),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _CustomerProductThumbnail extends StatelessWidget {
  const _CustomerProductThumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 56,
        height: 56,
        color: Colors.brown.shade100,
        child: imageUrl.isNotEmpty
            ? (imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) =>
                        const Icon(Icons.image_not_supported_outlined),
                  )
                : Image.asset(
                    imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) =>
                        const Icon(Icons.image_not_supported_outlined),
                  ))
            : const Icon(Icons.image, color: Color(0xFF6D4C41)),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}