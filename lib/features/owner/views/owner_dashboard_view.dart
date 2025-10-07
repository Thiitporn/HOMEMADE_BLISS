import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerDashboardView extends StatefulWidget {
  const OwnerDashboardView({super.key});

  @override
  State<OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboardView> {
  int _tabIndex = 0;

  Future<void> _showAddProductSheet(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter product name' : null,
                ),
                TextFormField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price (THB)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (double.tryParse(v ?? '') == null) ? 'Enter valid price' : null,
                ),
                TextFormField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(labelText: 'Image URL or Asset path'),
                ),
                TextFormField(
                  controller: stockCtrl,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (int.tryParse(v ?? '') == null) ? 'Enter valid stock' : null,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      await FirebaseFirestore.instance.collection('products').add({
                        'name': nameCtrl.text.trim(),
                        'price': double.parse(priceCtrl.text.trim()),
                        'imageUrl': imageCtrl.text.trim(),
                        'stock': int.parse(stockCtrl.text.trim()),
                        'description': '',
                        'variants': [],
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (mounted) Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color darkBrown = const Color(0xFF4E342E);
    final Color mediumBrown = const Color(0xFF8D6E63);
    final Color cream = const Color(0xFFFAF3EF);

    final pages = <Widget>[
      const _OwnerDashboardTab(),
      const _OwnerProductsTab(),
      const _OwnerOrdersTab(),
      const _OwnerMessagesTab(),
      const _OwnerProfileTab(),
    ];

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        title: Text(
          'Owner Dashboard',
          style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: darkBrown,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: pages[_tabIndex],
      floatingActionButton: _tabIndex == 1
          ? FloatingActionButton.extended(
              backgroundColor: mediumBrown,
              foregroundColor: Colors.white,
              onPressed: () => _showAddProductSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        selectedItemColor: mediumBrown,
        unselectedItemColor: darkBrown,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}


// --- Owner Tabs ---
class _OwnerDashboardTab extends StatelessWidget {
  const _OwnerDashboardTab();
  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real dashboard widgets (stats, charts, quick links)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.bar_chart, size: 60, color: Color(0xFF4E342E)),
          SizedBox(height: 16),
          Text('Dashboard: Sales summary, analytics, quick links',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _OwnerProductsTab extends StatelessWidget {
  const _OwnerProductsTab();
  @override
  Widget build(BuildContext context) {
    final Color darkBrown = const Color(0xFF4E342E);
    final Color lightBorder = const Color(0xFFD7CCC8);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No products yet. Tap + to add.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data();
            final name = (data['name'] ?? '') as String;
            final price = (data['price'] ?? 0).toDouble();
            final stock = (data['stock'] ?? 0) as num;
            final imageUrl = (data['imageUrl'] ?? '') as String;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightBorder),
              ),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? (imageUrl.startsWith('http')
                          ? Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.image))
                          : Image.asset(imageUrl, width: 48, height: 48, fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.image)))
                      : const Icon(Icons.image),
                ),
                title: Text(name, style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
                subtitle: Text('฿${price.toStringAsFixed(2)}  •  Stock: $stock'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'delete') {
                      await FirebaseFirestore.instance.collection('products').doc(doc.id).delete();
                    } else if (v == 'edit') {
                      // TODO: implement edit flow
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: docs.length,
        );
      },
    );
  }
}

class _OwnerOrdersTab extends StatelessWidget {
  const _OwnerOrdersTab();
  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real order management UI
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.local_shipping, size: 60, color: Color(0xFF4E342E)),
          SizedBox(height: 16),
          Text('Orders: View, update, manage all orders',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _OwnerMessagesTab extends StatelessWidget {
  const _OwnerMessagesTab();
  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real chat/notification UI
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.chat_bubble_outline, size: 60, color: Color(0xFF4E342E)),
          SizedBox(height: 16),
          Text('Messages: Chat with customers, notifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _OwnerProfileTab extends StatelessWidget {
  const _OwnerProfileTab();
  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real shop profile UI
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.person, size: 60, color: Color(0xFF4E342E)),
          SizedBox(height: 16),
          Text('Profile: Shop info, edit profile, settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
