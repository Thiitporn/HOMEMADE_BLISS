import 'package:flutter/material.dart';
import '../../../common/in_app_notification.dart';
import '../../chat/chat_view.dart';
import '../../chat/chat_inbox_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'orders_management_view.dart';
import 'coupons_management_view.dart';
import '../../authentication/views/edit_profile_view.dart';

class OwnerDashboardView extends StatefulWidget {
  const OwnerDashboardView({Key? key}) : super(key: key);

  @override
  State<OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboardView> {
  void _showAddProductSheet(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String name = '';
  final List<String> categories = [
    'Cakes',
    'Breads',
    'Tarts',
    'Cookies',
  ];
  String? selectedCategory = categories.isNotEmpty ? categories[0] : null;
    String description = '';
  String imageUrl = '';
    final List<Map<String, dynamic>> variants = [
      {'name': '', 'price': '', 'stock': ''},
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('เพิ่มสินค้าใหม่', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'URL รูปสินค้า (https://...)',
                      prefixIcon: Icon(Icons.image),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'กรุณาใส่ URL รูปสินค้า' : null,
                    onSaved: (v) => imageUrl = v ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'ชื่อสินค้า'),
                    validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกชื่อสินค้า' : null,
                    onSaved: (v) => name = v ?? '',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: categories
                              .map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ))
                              .toList(),
                          onChanged: (v) => setModalState(() => selectedCategory = v),
                          validator: (v) => v == null ? 'Select category' : null,
                          onSaved: (v) => selectedCategory = v,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'เพิ่มหมวดหมู่ใหม่',
                        onPressed: () async {
                          final controller = TextEditingController();
                          final result = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('เพิ่มหมวดหมู่ใหม่'),
                              content: TextField(
                                controller: controller,
                                autofocus: true,
                                decoration: const InputDecoration(hintText: 'ชื่อหมวดหมู่'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('ยกเลิก'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final text = controller.text.trim();
                                    if (text.isNotEmpty && !categories.contains(text)) {
                                      Navigator.pop(context, text);
                                    }
                                  },
                                  child: const Text('เพิ่ม'),
                                ),
                              ],
                            ),
                          );
                          if (result != null && result.isNotEmpty) {
                            final exists = categories.any((cat) => cat.toLowerCase() == result.toLowerCase());
                            if (!exists) {
                              setModalState(() {
                                categories.add(result);
                                selectedCategory = result;
                              });
                            } else {
                              final idx = categories.indexWhere((cat) => cat.toLowerCase() == result.toLowerCase());
                              if (idx != -1) {
                                setModalState(() {
                                  selectedCategory = categories[idx];
                                });
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'รายละเอียด'),
                    maxLines: 2,
                    onSaved: (v) => description = v ?? '',
                  ),
                  const SizedBox(height: 20),
                  Text('ตัวเลือกสินค้า', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: variants.length,
                    itemBuilder: (context, i) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  decoration: const InputDecoration(labelText: 'ชื่อตัวเลือก'),
                                  initialValue: variants[i]['name'],
                                  validator: (v) => v == null || v.isEmpty ? 'กรอกชื่อตัวเลือก' : null,
                                  onChanged: (v) => setModalState(() => variants[i]['name'] = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  decoration: const InputDecoration(labelText: 'ราคา'),
                                  initialValue: variants[i]['price'],
                                  keyboardType: TextInputType.number,
                                  validator: (v) => v == null || v.isEmpty ? 'กรอกราคา' : null,
                                  onChanged: (v) => setModalState(() => variants[i]['price'] = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  decoration: const InputDecoration(labelText: 'สต็อก'),
                                  initialValue: variants[i]['stock'],
                                  keyboardType: TextInputType.number,
                                  validator: (v) => v == null || v.isEmpty ? 'กรอกสต็อก' : null,
                                  onChanged: (v) => setModalState(() => variants[i]['stock'] = v),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: variants.length > 1
                                    ? () => setModalState(() => variants.removeAt(i))
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('เพิ่มตัวเลือก'),
                      onPressed: () => setModalState(() => variants.add({'name': '', 'price': '', 'stock': ''})),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('ยกเลิก'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            _formKey.currentState?.save();
                            // เตรียมข้อมูลตัวเลือก
                            final List<Map<String, dynamic>> variantList = variants
                                .where((v) => v['name'].toString().trim().isNotEmpty)
                                .map((v) => {
                                      'name': v['name'],
                                      'price': double.tryParse(v['price'].toString()) ?? 0,
                                      'stock': int.tryParse(v['stock'].toString()) ?? 0,
                                    })
                                .toList();
                            // คำนวณราคาต่ำสุดและรวม stock
                            double minPrice = variantList.isNotEmpty
                                ? variantList.map((v) => v['price'] as double).reduce((a, b) => a < b ? a : b)
                                : 0;
                            int totalStock = variantList.fold(0, (sum, v) => sum + (v['stock'] as int));
                            // บันทึกลง Firestore
                            await FirebaseFirestore.instance.collection('products').add({
                              'name': name,
                              'category': selectedCategory ?? '',
                              'description': description,
                              'imageUrl': imageUrl,
                              'variants': variantList,
                              'basePrice': minPrice,
                              'totalStock': totalStock,
                              'price': minPrice, // For customer view compatibility
                              'stock': totalStock, // For customer view compatibility
                              'createdAt': FieldValue.serverTimestamp(),
                              'isActive': true, // เพิ่ม field นี้
                            });
                            Navigator.pop(context);
                            InAppNotification.show(context, 'เพิ่มสินค้า "$name" เรียบร้อย', color: Colors.green);
                          }
                        },
                        child: const Text('บันทึก'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  int _tabIndex = 0;

  final Color darkBrown = const Color(0xFF4E342E);
  final Color mediumBrown = const Color(0xFF8D6E63); // ต้องการเปลี่ยนธีมสำหรับเจ้าของร้าน ปรับค่าสีตรงนี้
  final List<Widget> pages = const [
  OwnerDashboardTab(),
  OwnerProductsTab(),
  OwnerOrdersTab(),
  ChatInboxView(),
  OwnerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF3EF),
        elevation: 0,
        title: Text(
          'Owner Dashboard', // เปลี่ยนชื่อข้อความนี้เมื่ออยากรีแบรนด์หน้าควบคุมร้าน
          style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold),
        ),
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
class OwnerDashboardTab extends StatelessWidget {
  const OwnerDashboardTab();
  @override
  Widget build(BuildContext context) {
  final Color darkBrown = const Color(0xFF4E342E);
  final Color mediumBrown = const Color(0xFF8D6E63);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          Row(
            children: [
              Expanded(child: _buildStatCard('สินค้าทั้งหมด', 'products', Icons.inventory_2, mediumBrown)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('คำสั่งซื้อวันนี้', 'orders_today', Icons.shopping_cart, Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('คูปองส่วนลด', 'coupons', Icons.discount, Colors.purple)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('รายได้วันนี้', 'revenue_today', Icons.monetization_on, Colors.green)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Quick Actions
          Text('การจัดการด่วน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBrown)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'จัดการคำสั่งซื้อ',
                  Icons.local_shipping,
                  mediumBrown,
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersManagementView())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'จัดการคูปอง',
                  Icons.discount,
                  Colors.purple,
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CouponsManagementView())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'รายงานยอดขาย',
                  Icons.bar_chart,
                  Colors.blue,
                  () {
                    // TODO: Navigate to sales report
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'จัดการสต็อก',
                  Icons.inventory,
                  Colors.orange,
                  () {
                    // Navigate to products tab (stock management)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไปที่แท็บ Products เพื่อจัดการสต็อก')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String type, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7CCC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              StreamBuilder<QuerySnapshot>(
                stream: _getStatStream(type),
                builder: (context, snapshot) {
                  if (type == 'revenue_today') {
                    final docs = snapshot.data?.docs ?? [];
                    double revenue = 0;
                    for (final doc in docs) {
                      final data = doc.data() as Map<String, dynamic>?;
                      if (data != null && data['totalPrice'] != null) {
                        final val = data['totalPrice'];
                        if (val is int) revenue += val.toDouble();
                        else if (val is double) revenue += val;
                        else if (val is String) revenue += double.tryParse(val) ?? 0;
                      }
                    }
                    return Text(
                      revenue.toStringAsFixed(0),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                    );
                  } else {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Text(
                      '$count',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  
  Stream<QuerySnapshot> _getStatStream(String type) {
    switch (type) {
      case 'products':
        return FirebaseFirestore.instance.collection('products').snapshots();
      case 'orders_today':
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        return FirebaseFirestore.instance
            .collection('orders')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .snapshots();
      case 'coupons':
        return FirebaseFirestore.instance
            .collection('coupons')
            .where('isActive', isEqualTo: true)
            .snapshots();
      default:
        return FirebaseFirestore.instance.collection('products').snapshots();
    }
  }
}

class OwnerProductsTab extends StatelessWidget {
  const OwnerProductsTab();
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
            final basePrice = (data['basePrice'] ?? data['price'] ?? 0).toDouble();
            final totalStock = (data['totalStock'] ?? data['stock'] ?? 0) as num;
            final imageUrl = (data['imageUrl'] ?? '') as String;
            final category = (data['category'] ?? '') as String;
            final variants = (data['variants'] ?? []) as List;
            // Display variant info if available
            String variantInfo = '';
            if (variants.isNotEmpty) {
              final variantNames = variants.map((v) => v['name'] ?? '').where((name) => name.isNotEmpty).join(', ');
              if (variantNames.isNotEmpty) {
                variantInfo = ' • $variantNames';
              }
            }
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
                subtitle: Text('เริ่มต้น ฿${basePrice.toStringAsFixed(2)}  •  สต็อก: $totalStock${category.isNotEmpty ? '  •  $category' : ''}$variantInfo'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'delete') {
                      await FirebaseFirestore.instance.collection('products').doc(doc.id).delete();
                    } else if (v == 'edit') {
                      // Show edit bottom sheet with update logic
                      final _formKey = GlobalKey<FormState>();
                      String editName = name;
                      String editImageUrl = imageUrl;
                      String editDescription = (data['description'] ?? '') as String;
                      List<String> categories = ['Cakes', 'Breads', 'Tarts', 'Cookies'];
                      String? editCategory = category.isNotEmpty ? category : (categories.isNotEmpty ? categories[0] : null);
                      if (editCategory != null && !categories.contains(editCategory)) categories.add(editCategory);
                      final List<Map<String, dynamic>> editVariants = [
                        for (final v in variants)
                          {
                            'name': v['name'] ?? '',
                            'price': v['price']?.toString() ?? '',
                            'stock': v['stock']?.toString() ?? '',
                          }
                      ];
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) => StatefulBuilder(
                          builder: (context, setModalState) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                              left: 16, right: 16, top: 24),
                            child: Form(
                              key: _formKey,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('แก้ไขสินค้า', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: editImageUrl,
                                      decoration: InputDecoration(
                                        labelText: 'URL รูปสินค้า (https://...)',
                                        prefixIcon: Icon(Icons.image),
                                      ),
                                      validator: (v) => v == null || v.isEmpty ? 'กรุณาใส่ URL รูปสินค้า' : null,
                                      onSaved: (v) => editImageUrl = v ?? '',
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: editName,
                                      decoration: InputDecoration(labelText: 'ชื่อสินค้า'),
                                      validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกชื่อสินค้า' : null,
                                      onSaved: (v) => editName = v ?? '',
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: editCategory,
                                            decoration: const InputDecoration(labelText: 'Category'),
                                            items: categories
                                                .map((cat) => DropdownMenuItem(
                                                      value: cat,
                                                      child: Text(cat),
                                                    ))
                                                .toList(),
                                            onChanged: (v) => setModalState(() => editCategory = v),
                                            validator: (v) => v == null || v.isEmpty ? 'Select category' : null,
                                            onSaved: (v) => editCategory = v,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          tooltip: 'เพิ่มหมวดหมู่ใหม่',
                                          onPressed: () async {
                                            final controller = TextEditingController();
                                            final result = await showDialog<String>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('เพิ่มหมวดหมู่ใหม่'),
                                                content: TextField(
                                                  controller: controller,
                                                  autofocus: true,
                                                  decoration: const InputDecoration(hintText: 'ชื่อหมวดหมู่'),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('ยกเลิก'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      final text = controller.text.trim();
                                                      if (text.isNotEmpty && !categories.contains(text)) {
                                                        Navigator.pop(context, text);
                                                      }
                                                    },
                                                    child: const Text('เพิ่ม'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (result != null && result.isNotEmpty) {
                                              final exists = categories.any((cat) => cat.toLowerCase() == result.toLowerCase());
                                              if (!exists) {
                                                setModalState(() {
                                                  categories.add(result);
                                                  editCategory = result;
                                                });
                                              } else {
                                                final idx = categories.indexWhere((cat) => cat.toLowerCase() == result.toLowerCase());
                                                if (idx != -1) {
                                                  setModalState(() {
                                                    editCategory = categories[idx];
                                                  });
                                                }
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      initialValue: editDescription,
                                      decoration: InputDecoration(labelText: 'รายละเอียด'),
                                      maxLines: 2,
                                      onSaved: (v) => editDescription = v ?? '',
                                    ),
                                    const SizedBox(height: 20),
                                    Text('ตัวเลือกสินค้า', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: editVariants.length,
                                      itemBuilder: (context, i) {
                                        return Card(
                                          margin: const EdgeInsets.symmetric(vertical: 4),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: TextFormField(
                                                    decoration: const InputDecoration(labelText: 'ชื่อตัวเลือก'),
                                                    initialValue: editVariants[i]['name'],
                                                    validator: (v) => v == null || v.isEmpty ? 'กรอกชื่อตัวเลือก' : null,
                                                    onChanged: (v) => setModalState(() => editVariants[i]['name'] = v),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  flex: 1,
                                                  child: TextFormField(
                                                    decoration: const InputDecoration(labelText: 'ราคา'),
                                                    initialValue: editVariants[i]['price'],
                                                    keyboardType: TextInputType.number,
                                                    validator: (v) => v == null || v.isEmpty ? 'กรอกราคา' : null,
                                                    onChanged: (v) => setModalState(() => editVariants[i]['price'] = v),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  flex: 1,
                                                  child: TextFormField(
                                                    decoration: const InputDecoration(labelText: 'สต็อก'),
                                                    initialValue: editVariants[i]['stock'],
                                                    keyboardType: TextInputType.number,
                                                    validator: (v) => v == null || v.isEmpty ? 'กรอกสต็อก' : null,
                                                    onChanged: (v) => setModalState(() => editVariants[i]['stock'] = v),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: editVariants.length > 1
                                                      ? () => setModalState(() => editVariants.removeAt(i))
                                                      : null,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        icon: const Icon(Icons.add),
                                        label: const Text('เพิ่มตัวเลือก'),
                                        onPressed: () => setModalState(() => editVariants.add({'name': '', 'price': '', 'stock': ''})),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('ยกเลิก'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            if (_formKey.currentState?.validate() ?? false) {
                                              _formKey.currentState?.save();
                                              final List<Map<String, dynamic>> variantList = editVariants
                                                  .where((v) => v['name'].toString().trim().isNotEmpty)
                                                  .map((v) => {
                                                        'name': v['name'],
                                                        'price': double.tryParse(v['price'].toString()) ?? 0,
                                                        'stock': int.tryParse(v['stock'].toString()) ?? 0,
                                                      })
                                                  .toList();
                                              double minPrice = variantList.isNotEmpty
                                                  ? variantList.map((v) => v['price'] as double).reduce((a, b) => a < b ? a : b)
                                                  : 0;
                                              int totalStock = variantList.fold(0, (sum, v) => sum + (v['stock'] as int));
                                              await FirebaseFirestore.instance.collection('products').doc(doc.id).update({
                                                'name': editName,
                                                'category': editCategory ?? '',
                                                'description': editDescription,
                                                'imageUrl': editImageUrl,
                                                'variants': variantList,
                                                'basePrice': minPrice,
                                                'totalStock': totalStock,
                                                'price': minPrice,
                                                'stock': totalStock,
                                              });
                                              Navigator.pop(context);
                                              // ignore: use_build_context_synchronously
                                              InAppNotification.show(context, 'แก้ไขสินค้า "$editName" เรียบร้อย', color: Colors.green);
                                            }
                                          },
                                          child: const Text('บันทึก'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
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

class OwnerOrdersTab extends StatelessWidget {
  const OwnerOrdersTab();
  @override
  Widget build(BuildContext context) {
    return const OrdersManagementView();
  }
}

class OwnerMessagesTab extends StatelessWidget {
  const OwnerMessagesTab();
  @override
  Widget build(BuildContext context) {
    final ownerUid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('ownerUid', isEqualTo: ownerUid)
          .orderBy('lastTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('ยังไม่มีข้อความจากลูกค้า'));
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final chatId = docs[i].id;
            final customerName = data['customerName'] ?? 'ลูกค้า';
            final lastMessage = data['lastMessage'] ?? '';
            return ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF4E342E)),
              title: Text(customerName),
              subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChatView(chatId: chatId, peerName: customerName),
                ));
              },
            );
          },
        );
      },
    );
  }
}

class OwnerProfileTab extends StatelessWidget {
  const OwnerProfileTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ListTile(
          leading: const Icon(Icons.store, size: 40, color: Color(0xFF4E342E)),
          title: const Text('ข้อมูลร้าน/โปรไฟล์'),
          subtitle: const Text('ดูและแก้ไขข้อมูลร้าน/เจ้าของร้าน'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('แก้ไขโปรไฟล์'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileView()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('ออกจากระบบ'),
          onTap: () async => FirebaseAuth.instance.signOut(),
        ),
      ],
    );
  }
}
