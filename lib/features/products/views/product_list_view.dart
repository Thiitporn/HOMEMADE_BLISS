import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('สินค้า')),
      body: products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                return Card(
                  child: ListTile(
                    leading: Image.network(p.imageUrl, width: 56, height: 56, fit: BoxFit.cover),
                    title: Text(p.name),
                    subtitle: Text('${p.description}\n${p.variants.join(', ')}'),
                    trailing: Text('฿${p.price.toStringAsFixed(2)}'),
                  ),
                );
              },
            ),
    );
  }
}