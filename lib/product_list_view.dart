import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'product_controller.dart';

class ProductListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productController = Provider.of<ProductController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Product List'),
      ),
      body: FutureBuilder(
        future: productController.fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return ListView.builder(
              itemCount: productController.products.length,
              itemBuilder: (context, index) {
                final product = productController.products[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('\$${product.price}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}