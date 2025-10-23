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
    return Scaffold(
      appBar: AppBar(title: const Text('สินค้า')),
      body: products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: p.imageUrl.startsWith('http')
                            ? Image.network(
                                p.imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Image.asset('assets/images/logo.png', width: 56, height: 56, fit: BoxFit.cover),
                              )
                            : Image.asset(
                                p.imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Image.asset('assets/images/logo.png', width: 56, height: 56, fit: BoxFit.cover),
                              ),
                        title: Text(p.name),
                        subtitle: Text('${p.description}\n${p.variants.join(', ')}'),
                        trailing: Text('฿${p.price.toStringAsFixed(2)}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, right: 16.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Add to Cart'),
                            onPressed: () {
                              if (p.variants.isNotEmpty) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  builder: (context) {
                                    ProductVariant? selectedVariant;
                                    int qty = 1;
                                    return StatefulBuilder(
                                      builder: (context, setState) {
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            bottom: MediaQuery.of(context).viewInsets.bottom,
                                            left: 16, right: 16, top: 24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('เลือกตัวเลือกสินค้า', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                              const SizedBox(height: 12),
                                              ...p.variants.map((v) {
                                                final isAvailable = v.stock > 0;
                                                return ListTile(
                                                  title: Text(v.name),
                                                  subtitle: Text('ราคา: ฿${v.price.toStringAsFixed(2)} | สต็อก: ${v.stock}'),
                                                  leading: Radio<ProductVariant>(
                                                    value: v,
                                                    groupValue: selectedVariant,
                                                    onChanged: isAvailable
                                                        ? (val) {
                                                            setState(() {
                                                              selectedVariant = val;
                                                              qty = 1;
                                                            });
                                                          }
                                                        : null,
                                                  ),
                                                  enabled: isAvailable,
                                                );
                                              }).toList(),
                                              const SizedBox(height: 12),
                                              if (selectedVariant != null)
                                                Row(
                                                  children: [
                                                    const Text('จำนวน: '),
                                                    IconButton(
                                                      icon: const Icon(Icons.remove),
                                                      onPressed: qty > 1
                                                          ? () => setState(() => qty--)
                                                          : null,
                                                    ),
                                                    Text('$qty'),
                                                    IconButton(
                                                      icon: const Icon(Icons.add),
                                                      onPressed: qty < (selectedVariant!.stock < 10 ? selectedVariant!.stock : 10)
                                                          ? () => setState(() => qty++)
                                                          : null,
                                                    ),
                                                    Text('(สูงสุด ${selectedVariant!.stock < 10 ? selectedVariant!.stock : 10})'),
                                                  ],
                                                ),
                                              const SizedBox(height: 20),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: selectedVariant != null
                                                      ? () {
                                                          cartService.addToCart(
                                                            p,
                                                            variant: selectedVariant,
                                                            qty: qty,
                                                          );
                                                          Navigator.pop(context);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('เพิ่มลงตะกร้าแล้ว')),
                                                          );
                                                        }
                                                      : null,
                                                  child: const Text('เพิ่มลงตะกร้า'),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              } else {
                                // ไม่มี variants, เพิ่มลงตะกร้าเลย
                                cartService.addToCart(p, qty: 1);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('เพิ่มลงตะกร้าแล้ว')),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}