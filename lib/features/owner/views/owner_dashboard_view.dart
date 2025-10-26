import 'package:flutter/material.dart';
import '../../../common/in_app_notification.dart';
import '../../../common/dialog_utils.dart';
import '../../chat/chat_view.dart';
import '../../chat/chat_inbox_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'orders_management_view.dart';
import 'coupons_management_view.dart';
import '../../authentication/views/edit_profile_view.dart';
import 'sales_report_view.dart';

class OwnerDashboardView extends StatefulWidget {
  const OwnerDashboardView({Key? key}) : super(key: key);

  @override
  State<OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboardView> {
  int _tabIndex = 0;
  final Color darkBrown = const Color(0xFF4E342E);
  final Color mediumBrown = const Color(0xFF8D6E63);

  late final List<Widget> pages = const [
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
          'Owner Dashboard',
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
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void switchToTab(int index) {
    if (!mounted || index == _tabIndex) return;
    setState(() => _tabIndex = index);
  }

  Future<void> _showAddProductSheet(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String description = '';
    String imageUrl = '';
    String? selectedCategory;
    final categories = [
      'Cakes',
      'Breads',
      'Tarts',
      'Cookies',
    ];
    final variants = <Map<String, String>>[
      {'name': '', 'price': '', 'stock': ''},
    ];

    InputDecoration fieldDecoration(
      String label, {
      IconData? icon,
      String? hintText,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF8D6E63)),
        ),
      );
    }

    Widget buildVariantCard(
      int index,
      void Function(void Function()) setModalState,
    ) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ตัวเลือกที่ ${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: variants[index]['name'],
                      decoration:
                          fieldDecoration('ชื่อ', icon: Icons.label_outline),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'กรอกชื่อ'
                              : null,
                      onChanged: (value) =>
                          setModalState(() => variants[index]['name'] = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: variants.length > 1
                        ? () async {
                            final confirmed = await showConfirmDialog(
                              context,
                              'ลบตัวเลือกสินค้า',
                              'คุณต้องการลบตัวเลือกนี้จริงหรือไม่?',
                            );
                            if (!confirmed) return;
                            setModalState(() => variants.removeAt(index));
                          }
                        : null,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: variants[index]['price'],
                      decoration:
                          fieldDecoration('ราคา', icon: Icons.sell_outlined),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'กรอกราคา'
                              : null,
                      onChanged: (value) =>
                          setModalState(() => variants[index]['price'] = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: variants[index]['stock'],
                      decoration: fieldDecoration('สต็อก',
                          icon: Icons.inventory_2_outlined),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: false),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'กรอกสต็อก'
                              : null,
                      onChanged: (value) =>
                          setModalState(() => variants[index]['stock'] = value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 54,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.brown.shade200,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'เพิ่มสินค้าใหม่',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: fieldDecoration(
                          'URL รูปสินค้า',
                          icon: Icons.image_outlined,
                          hintText: 'https://example.com/image.jpg',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'กรุณาใส่ URL รูปภาพ'
                                : null,
                        onSaved: (value) => imageUrl = value?.trim() ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: fieldDecoration(
                          'ชื่อสินค้า',
                          icon: Icons.cake_outlined,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'กรอกชื่อสินค้า'
                                : null,
                        onSaved: (value) => name = value?.trim() ?? '',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory,
                              decoration: fieldDecoration('หมวดหมู่',
                                  icon: Icons.category_outlined),
                              items: categories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setModalState(() => selectedCategory = value),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'เลือกหมวดหมู่'
                                      : null,
                              onSaved: (value) => selectedCategory = value,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () async {
                              final controller = TextEditingController();
                              final result = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('เพิ่มหมวดหมู่ใหม่'),
                                  content: TextField(
                                    controller: controller,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      hintText: 'ชื่อหมวดหมู่',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('ยกเลิก'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        final value = controller.text.trim();
                                        if (value.isNotEmpty &&
                                            !categories.contains(value)) {
                                          Navigator.pop(context, value);
                                        }
                                      },
                                      child: const Text('เพิ่ม'),
                                    ),
                                  ],
                                ),
                              );
                              if (result != null && result.isNotEmpty) {
                                final exists = categories.any(
                                  (category) =>
                                      category.toLowerCase() ==
                                      result.toLowerCase(),
                                );
                                if (!exists) {
                                  setModalState(() {
                                    categories.add(result);
                                    selectedCategory = result;
                                  });
                                } else {
                                  final matchIndex = categories.indexWhere(
                                    (category) =>
                                        category.toLowerCase() ==
                                        result.toLowerCase(),
                                  );
                                  if (matchIndex != -1) {
                                    setModalState(
                                      () => selectedCategory =
                                          categories[matchIndex],
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            color: const Color(0xFF8D6E63),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: fieldDecoration(
                          'รายละเอียด',
                          icon: Icons.notes_outlined,
                          hintText: 'คำอธิบายสั้น ๆ ของสินค้า',
                        ),
                        maxLines: 3,
                        onSaved: (value) => description = value?.trim() ?? '',
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'ตัวเลือกสินค้า',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: variants.length,
                        itemBuilder: (context, index) =>
                            buildVariantCard(index, setModalState),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => setModalState(
                          () => variants.add(
                            {'name': '', 'price': '', 'stock': ''},
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8D6E63),
                          side: const BorderSide(color: Color(0xFF8D6E63)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('เพิ่มตัวเลือก'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final confirmed = await showConfirmDialog(
                                context,
                                'ยกเลิก',
                                'คุณต้องการยกเลิกการเพิ่มสินค้านี้หรือไม่?',
                              );
                              if (!confirmed) return;
                              Navigator.pop(context);
                            },
                            child: const Text('ยกเลิก'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8D6E63),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              final confirmed = await showConfirmDialog(
                                context,
                                'บันทึกสินค้า',
                                'คุณต้องการบันทึกสินค้านี้หรือไม่?',
                              );
                              if (!confirmed) return;
                              if (formKey.currentState?.validate() ?? false) {
                                formKey.currentState?.save();
                                final variantList = variants
                                    .where(
                                  (variant) =>
                                      (variant['name'] ?? '').trim().isNotEmpty,
                                )
                                    .map((variant) {
                                  final price = double.tryParse(
                                        variant['price'] ?? '',
                                      ) ??
                                      0;
                                  final stock = int.tryParse(
                                        variant['stock'] ?? '',
                                      ) ??
                                      0;
                                  return {
                                    'name': variant['name'],
                                    'price': price,
                                    'stock': stock,
                                  };
                                }).toList();

                                final minPrice = variantList.isNotEmpty
                                    ? variantList
                                        .map((variant) =>
                                            (variant['price'] as double))
                                        .reduce(
                                          (a, b) => a < b ? a : b,
                                        )
                                    : 0.0;

                                final totalStock = variantList.fold<int>(
                                  0,
                                  (sum, variant) =>
                                      sum + (variant['stock'] as int),
                                );

                                await FirebaseFirestore.instance
                                    .collection('products')
                                    .add({
                                  'name': name,
                                  'category': selectedCategory ?? '',
                                  'description': description,
                                  'imageUrl': imageUrl,
                                  'variants': variantList,
                                  'basePrice': minPrice,
                                  'totalStock': totalStock,
                                  'price': minPrice,
                                  'stock': totalStock,
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'isActive': true,
                                });

                                if (!mounted) return;

                                Navigator.pop(context);
                                InAppNotification.show(
                                  context,
                                  'เพิ่มสินค้า "$name" เรียบร้อย',
                                  color: Colors.green,
                                );
                              }
                            },
                            child: const Text('บันทึก'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class OwnerDashboardTab extends StatelessWidget {
  const OwnerDashboardTab();

  @override
  Widget build(BuildContext context) {
    final Color mediumBrown = const Color(0xFF8D6E63);
    final Color darkBrown = const Color(0xFF4E342E);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewSection(
            context: context,
            mediumBrown: mediumBrown,
            darkBrown: darkBrown,
          ),
          const SizedBox(height: 28),
          _buildQuickActionsSection(
            context: context,
            mediumBrown: mediumBrown,
            darkBrown: darkBrown,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection({
    required BuildContext context,
    required Color mediumBrown,
    required Color darkBrown,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: mediumBrown.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.dashboard_customize_outlined,
                  color: mediumBrown,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ภาพรวมร้าน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: darkBrown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final maxWidth = constraints.maxWidth;
              final crossAxisCount = maxWidth >= 340 ? 2 : 1;
              final itemWidth = crossAxisCount == 1
                  ? maxWidth
                  : (maxWidth - spacing) / 2;
              final cards = [
                _buildStatCard(
                  context,
                  title: 'สินค้าทั้งหมด',
                  type: 'products',
                  icon: Icons.inventory_2,
                  color: mediumBrown,
                ),
                _buildStatCard(
                  context,
                  title: 'คำสั่งซื้อวันนี้',
                  type: 'orders_today',
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  context,
                  title: 'คูปองส่วนลด',
                  type: 'coupons',
                  icon: Icons.discount,
                  color: Colors.purple,
                ),
                _buildStatCard(
                  context,
                  title: 'รายได้วันนี้',
                  type: 'revenue_today',
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
              ];
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: cards.map((card) {
                  return SizedBox(
                    width: itemWidth,
                    child: card,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection({
    required BuildContext context,
    required Color mediumBrown,
    required Color darkBrown,
  }) {
    final quickActions = [
      _QuickAction(
        title: 'จัดการคำสั่งซื้อ',
        icon: Icons.local_shipping,
        color: mediumBrown,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const OrdersManagementView(),
          ),
        ),
      ),
      _QuickAction(
        title: 'จัดการคูปอง',
        icon: Icons.discount,
        color: Colors.purple,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CouponsManagementView(),
          ),
        ),
      ),
      _QuickAction(
        title: 'รายงานยอดขาย',
        icon: Icons.bar_chart,
        color: Colors.blue,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SalesReportView(),
          ),
        ),
      ),
      _QuickAction(
        title: 'จัดการสต็อก',
        icon: Icons.inventory,
        color: Colors.orange,
        onTap: () {
          final ownerState =
              context.findAncestorStateOfType<_OwnerDashboardViewState>();
          if (ownerState != null) {
            ownerState.switchToTab(1);
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const OwnerDashboardView(),
              ),
            );
          }
        },
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'การจัดการด่วน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkBrown,
                  ),
                ),
              ),
              Container(
                height: 4,
                width: 60,
                decoration: BoxDecoration(
                  color: mediumBrown.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 14.0;
              final maxWidth = constraints.maxWidth;
              final crossAxisCount = maxWidth >= 340 ? 2 : 1;
              final itemWidth = crossAxisCount == 1
                  ? maxWidth
                  : (maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: quickActions.map((item) {
                  final tileHeight = itemWidth * 1.12;
                  return SizedBox(
                    width: itemWidth,
                    height: tileHeight,
                    child: _buildQuickActionCard(item),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String type,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.18),
            Colors.white,
          ],
        ),
  borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            offset: const Offset(0, 8),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              if (type == 'revenue_today')
                StreamBuilder<QuerySnapshot>(
                  stream: _getStatStream(type),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 36,
                        height: 22,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final docs = snapshot.data?.docs ?? [];
                    double revenue = 0;
                    for (final doc in docs) {
                      final data = doc.data() as Map<String, dynamic>?;
                      if (data != null &&
                          data['status'] == 'paid' &&
                          data['totalPrice'] != null) {
                        final value = data['totalPrice'];
                        if (value is int) {
                          revenue += value.toDouble();
                        } else if (value is double) {
                          revenue += value;
                        } else if (value is String) {
                          revenue += double.tryParse(value) ?? 0;
                        }
                      }
                    }
                    final text =
                        revenue > 0 ? '฿${revenue.toStringAsFixed(0)}' : '฿0';
                    return Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    );
                  },
                )
              else
                StreamBuilder<QuerySnapshot>(
                  stream: _getStatStream(type),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.brown.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: action.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                action.color.withOpacity(0.08),
              ],
            ),
            border: Border.all(color: action.color.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: action.color.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color, size: 20),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    action.title,
                    style: TextStyle(
                      color: action.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'แตะเพื่อเริ่ม',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
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
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .snapshots();
      case 'revenue_today':
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay =
            DateTime(today.year, today.month, today.day, 23, 59, 59, 999);
        return FirebaseFirestore.instance
            .collection('orders')
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('createdAt',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
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

class _QuickAction {
  const _QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class OwnerProductsTab extends StatelessWidget {
  const OwnerProductsTab();
  @override
  Widget build(BuildContext context) {
    final Color darkBrown = const Color(0xFF4E342E);
    final Color lightBorder = const Color(0xFFD7CCC8);
    final Color accent = const Color(0xFF8D6E63);
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
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data();
            final name = (data['name'] ?? '') as String;
            final basePrice =
                (data['basePrice'] ?? data['price'] ?? 0).toDouble();
            final totalStock =
                (data['totalStock'] ?? data['stock'] ?? 0) as num;
            final imageUrl = (data['imageUrl'] ?? '') as String;
            final category = (data['category'] ?? '') as String;
            final variants = (data['variants'] ?? []) as List;
            final description = (data['description'] ?? '') as String;
            final stockValue = totalStock.toDouble();
            final stockLabel = stockValue == stockValue.roundToDouble()
                ? stockValue.toInt().toString()
                : stockValue.toStringAsFixed(1);
            final List<Map<String, dynamic>> typedVariants = [
              for (final dynamic v in variants)
                if (v is Map<String, dynamic>)
                  {
                    'name': (v['name'] ?? '').toString(),
                    'price': v['price'],
                    'stock': v['stock'],
                  }
            ];
            final variantChips = typedVariants
                .where((v) => (v['name'] as String).isNotEmpty)
                .map((v) {
              final variantName = v['name'] as String;
              final dynamic variantPrice = v['price'];
              String label = variantName;
              if (variantPrice is num) {
                final priceValue = variantPrice.toDouble();
                final formatted = priceValue == priceValue.roundToDouble()
                    ? priceValue.toInt().toString()
                    : priceValue.toStringAsFixed(2);
                label = '$variantName ฿$formatted';
              }
              return _InfoPill(
                label: label,
                icon: Icons.analytics_outlined,
                color: accent,
              );
            }).toList();
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductThumbnail(imageUrl: imageUrl),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: darkBrown,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                iconSize: 20,
                                elevation: 4,
                                onSelected: (v) async {
                                  if (v == 'delete') {
                                    final confirmed = await showConfirmDialog(
                                      context,
                                      'ลบสินค้า',
                                      'คุณต้องการลบสินค้านี้จริงหรือไม่?',
                                    );
                                    if (!confirmed) return;
                                    await FirebaseFirestore.instance
                                        .collection('products')
                                        .doc(doc.id)
                                        .delete();
                                  } else if (v == 'edit') {
                                    final confirmed = await showConfirmDialog(
                                      context,
                                      'แก้ไขสินค้า',
                                      'คุณต้องการแก้ไขสินค้านี้ใช่หรือไม่?',
                                    );
                                    if (!confirmed) return;
                                    final _formKey = GlobalKey<FormState>();
                                    String editName = name;
                                    String editImageUrl = imageUrl;
                                    String editDescription =
                                        (data['description'] ?? '') as String;
                                    List<String> categories = [
                                      'Cakes',
                                      'Breads',
                                      'Tarts',
                                      'Cookies'
                                    ];
                                    String? editCategory = category.isNotEmpty
                                        ? category
                                        : (categories.isNotEmpty
                                            ? categories[0]
                                            : null);
                                    if (editCategory != null &&
                                        !categories.contains(editCategory)) {
                                      categories.add(editCategory);
                                    }
                                    final List<Map<String, dynamic>>
                                        editVariants = [
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
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24)),
                                      ),
                                      builder: (context) => StatefulBuilder(
                                        builder: (context, setModalState) =>
                                            Padding(
                                          padding: EdgeInsets.only(
                                              bottom: MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom,
                                              left: 16,
                                              right: 16,
                                              top: 24),
                                          child: Form(
                                            key: _formKey,
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('แก้ไขสินค้า',
                                                      style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  const SizedBox(height: 16),
                                                  TextFormField(
                                                    initialValue: editImageUrl,
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          'URL รูปสินค้า (https://...)',
                                                      prefixIcon:
                                                          Icon(Icons.image),
                                                    ),
                                                    validator: (v) => v ==
                                                                null ||
                                                            v.isEmpty
                                                        ? 'กรุณาใส่ URL รูปสินค้า'
                                                        : null,
                                                    onSaved: (v) =>
                                                        editImageUrl = v ?? '',
                                                  ),
                                                  const SizedBox(height: 16),
                                                  TextFormField(
                                                    initialValue: editName,
                                                    decoration: InputDecoration(
                                                        labelText:
                                                            'ชื่อสินค้า'),
                                                    validator: (v) => v ==
                                                                null ||
                                                            v.isEmpty
                                                        ? 'กรุณากรอกชื่อสินค้า'
                                                        : null,
                                                    onSaved: (v) =>
                                                        editName = v ?? '',
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child:
                                                            DropdownButtonFormField<
                                                                String>(
                                                          value: editCategory,
                                                          decoration:
                                                              const InputDecoration(
                                                                  labelText:
                                                                      'Category'),
                                                          items: categories
                                                              .map((cat) =>
                                                                  DropdownMenuItem(
                                                                    value: cat,
                                                                    child: Text(
                                                                        cat),
                                                                  ))
                                                              .toList(),
                                                          onChanged: (v) =>
                                                              setModalState(() =>
                                                                  editCategory =
                                                                      v),
                                                          validator: (v) => v ==
                                                                      null ||
                                                                  v.isEmpty
                                                              ? 'Select category'
                                                              : null,
                                                          onSaved: (v) =>
                                                              editCategory = v,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.add),
                                                        tooltip:
                                                            'เพิ่มหมวดหมู่ใหม่',
                                                        onPressed: () async {
                                                          final controller =
                                                              TextEditingController();
                                                          final result =
                                                              await showDialog<
                                                                  String>(
                                                            context: context,
                                                            builder:
                                                                (context) =>
                                                                    AlertDialog(
                                                              title: const Text(
                                                                  'เพิ่มหมวดหมู่ใหม่'),
                                                              content:
                                                                  TextField(
                                                                controller:
                                                                    controller,
                                                                autofocus: true,
                                                                decoration:
                                                                    const InputDecoration(
                                                                        hintText:
                                                                            'ชื่อหมวดหมู่'),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          context),
                                                                  child: const Text(
                                                                      'ยกเลิก'),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed:
                                                                      () {
                                                                    final text =
                                                                        controller
                                                                            .text
                                                                            .trim();
                                                                    if (text.isNotEmpty &&
                                                                        !categories
                                                                            .contains(text)) {
                                                                      Navigator.pop(
                                                                          context,
                                                                          text);
                                                                    }
                                                                  },
                                                                  child: const Text(
                                                                      'เพิ่ม'),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                          if (result != null &&
                                                              result
                                                                  .isNotEmpty) {
                                                            final exists = categories
                                                                .any((cat) =>
                                                                    cat.toLowerCase() ==
                                                                    result
                                                                        .toLowerCase());
                                                            if (!exists) {
                                                              setModalState(() {
                                                                categories.add(
                                                                    result);
                                                                editCategory =
                                                                    result;
                                                              });
                                                            } else {
                                                              final idx = categories
                                                                  .indexWhere((cat) =>
                                                                      cat.toLowerCase() ==
                                                                      result
                                                                          .toLowerCase());
                                                              if (idx != -1) {
                                                                setModalState(
                                                                    () {
                                                                  editCategory =
                                                                      categories[
                                                                          idx];
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
                                                    initialValue:
                                                        editDescription,
                                                    decoration: InputDecoration(
                                                        labelText:
                                                            'รายละเอียด'),
                                                    maxLines: 2,
                                                    onSaved: (v) =>
                                                        editDescription =
                                                            v ?? '',
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Text('ตัวเลือกสินค้า',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  const SizedBox(height: 8),
                                                  ListView.builder(
                                                    shrinkWrap: true,
                                                    physics:
                                                        const NeverScrollableScrollPhysics(),
                                                    itemCount:
                                                        editVariants.length,
                                                    itemBuilder: (context, i) {
                                                      return Card(
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            vertical: 4),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                flex: 2,
                                                                child:
                                                                    TextFormField(
                                                                  decoration: const InputDecoration(
                                                                      labelText:
                                                                          'ชื่อตัวเลือก'),
                                                                  initialValue:
                                                                      editVariants[
                                                                              i]
                                                                          [
                                                                          'name'],
                                                                  validator: (v) => v ==
                                                                              null ||
                                                                          v.isEmpty
                                                                      ? 'กรอกชื่อตัวเลือก'
                                                                      : null,
                                                                  onChanged: (v) =>
                                                                      setModalState(() =>
                                                                          editVariants[i]['name'] =
                                                                              v),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Expanded(
                                                                flex: 1,
                                                                child:
                                                                    TextFormField(
                                                                  decoration: const InputDecoration(
                                                                      labelText:
                                                                          'ราคา'),
                                                                  initialValue:
                                                                      editVariants[
                                                                              i]
                                                                          [
                                                                          'price'],
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  validator: (v) => v ==
                                                                              null ||
                                                                          v.isEmpty
                                                                      ? 'กรอกราคา'
                                                                      : null,
                                                                  onChanged: (v) =>
                                                                      setModalState(() =>
                                                                          editVariants[i]['price'] =
                                                                              v),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Expanded(
                                                                flex: 1,
                                                                child:
                                                                    TextFormField(
                                                                  decoration: const InputDecoration(
                                                                      labelText:
                                                                          'สต็อก'),
                                                                  initialValue:
                                                                      editVariants[
                                                                              i]
                                                                          [
                                                                          'stock'],
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  validator: (v) => v ==
                                                                              null ||
                                                                          v.isEmpty
                                                                      ? 'กรอกสต็อก'
                                                                      : null,
                                                                  onChanged: (v) =>
                                                                      setModalState(() =>
                                                                          editVariants[i]['stock'] =
                                                                              v),
                                                                ),
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(
                                                                    Icons
                                                                        .delete,
                                                                    color: Colors
                                                                        .red),
                                                                onPressed: editVariants
                                                                            .length >
                                                                        1
                                  ? () async {
                                    final confirmed = await showConfirmDialog(
                                      context,
                                      'ลบตัวเลือกสินค้า',
                                      'คุณต้องการลบตัวเลือกนี้จริงหรือไม่?',
                                    );
                                    if (!confirmed) return;
                                    setModalState(() =>
                                      editVariants
                                        .removeAt(i));
                                    }
                                                                    : null,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: TextButton.icon(
                                                      icon:
                                                          const Icon(Icons.add),
                                                      label: const Text(
                                                          'เพิ่มตัวเลือก'),
                                                      onPressed: () =>
                                                          setModalState(() =>
                                                              editVariants.add({
                                                                'name': '',
                                                                'price': '',
                                                                'stock': ''
                                                              })),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      TextButton(
                                                        onPressed: () async {
                                                          final confirmed = await showConfirmDialog(
                                                            context,
                                                            'ยกเลิก',
                                                            'คุณต้องการยกเลิกการแก้ไขสินค้านี้หรือไม่?',
                                                          );
                                                          if (!confirmed) return;
                                                          Navigator.pop(context);
                                                        },
                                                        child: const Text(
                                                            'ยกเลิก'),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          final confirmed = await showConfirmDialog(
                                                            context,
                                                            'บันทึกการแก้ไข',
                                                            'คุณต้องการบันทึกการแก้ไขสินค้านี้หรือไม่?',
                                                          );
                                                          if (!confirmed) return;
                                                          if (_formKey
                                                                  .currentState
                                                                  ?.validate() ??
                                                              false) {
                                                            _formKey
                                                                .currentState
                                                                ?.save();
                                                            final List<
                                                                    Map<String,
                                                                        dynamic>>
                                                                variantList =
                                                                editVariants
                                                                    .where((v) => v[
                                                                            'name']
                                                                        .toString()
                                                                        .trim()
                                                                        .isNotEmpty)
                                                                    .map(
                                                                        (v) => {
                                                                              'name': v['name'],
                                                                              'price': double.tryParse(v['price'].toString()) ?? 0,
                                                                              'stock': int.tryParse(v['stock'].toString()) ?? 0,
                                                                            })
                                                                    .toList();
                                                            double minPrice = variantList
                                                                    .isNotEmpty
                                                                ? variantList
                                                                    .map((v) =>
                                                                        v['price']
                                                                            as double)
                                                                    .reduce((a,
                                                                            b) =>
                                                                        a < b
                                                                            ? a
                                                                            : b)
                                                                : 0;
                                                            int totalStock =
                                                                variantList.fold(
                                                                    0,
                                                                    (sum, v) =>
                                                                        sum +
                                                                        (v['stock']
                                                                            as int));
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'products')
                                                                .doc(doc.id)
                                                                .update({
                                                              'name': editName,
                                                              'category':
                                                                  editCategory ??
                                                                      '',
                                                              'description':
                                                                  editDescription,
                                                              'imageUrl':
                                                                  editImageUrl,
                                                              'variants':
                                                                  variantList,
                                                              'basePrice':
                                                                  minPrice,
                                                              'totalStock':
                                                                  totalStock,
                                                              'price': minPrice,
                                                              'stock':
                                                                  totalStock,
                                                            });
                                                            Navigator.pop(
                                                                context);
                                                            // ignore: use_build_context_synchronously
                                                            InAppNotification.show(
                                                                context,
                                                                'แก้ไขสินค้า "$editName" เรียบร้อย',
                                                                color: Colors
                                                                    .green);
                                                          }
                                                        },
                                                        child: const Text(
                                                            'บันทึก'),
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
                                  PopupMenuItem(
                                      value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                          if (category.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _InfoPill(
                                  label: '฿${basePrice.toStringAsFixed(2)}',
                                  icon: Icons.sell_outlined,
                                  color: darkBrown,
                                ),
                                _InfoPill(
                                  label: 'Stock $stockLabel',
                                  icon: Icons.inventory_2_outlined,
                                  color: Colors.teal.shade700,
                                ),
                                ...variantChips,
                              ],
                            ),
                          ),
                          if (description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 11,
                                  height: 1.25,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({required this.imageUrl});

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
                    fit: BoxFit.cover,
                    width: 56,
                    height: 56,
                    errorBuilder: (context, _, __) =>
                        const Icon(Icons.image_not_supported_outlined),
                  )
                : Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: 56,
                    height: 56,
                    errorBuilder: (context, _, __) =>
                        const Icon(Icons.image_not_supported_outlined),
                  ))
            : const Icon(Icons.image, color: Color(0xFF6D4C41)),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(
      {required this.label, required this.icon, required this.color});

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
              subtitle: Text(lastMessage,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () async {
                final owner = FirebaseAuth.instance.currentUser;
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatView(
                      chatId: chatId,
                      peerName: customerName,
                      isOwner: true,
                      ownerUid: owner?.uid,
                      ownerDisplayName: owner?.displayName,
                    ),
                  ),
                );
                if (!context.mounted) return;
                if (result == 'deleted') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ลบแชทแล้ว')),
                  );
                }
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
  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _handleEditProfile(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      'แก้ไขโปรไฟล์',
      'คุณต้องการแก้ไขโปรไฟล์นี้ใช่หรือไม่?',
    );
    if (!confirmed || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfileView()),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      'ออกจากระบบ',
      'คุณต้องการออกจากระบบหรือไม่?',
    );
    if (!confirmed || !context.mounted) return;
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final ownerName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : 'เจ้าของร้าน Homemade Bliss';
    final email = (user?.email?.trim().isNotEmpty ?? false)
        ? user!.email!
        : 'ยังไม่มีอีเมลที่บันทึกไว้';
    final phone = (user?.phoneNumber?.trim().isNotEmpty ?? false)
        ? user!.phoneNumber!
        : null;
    final createdAt = user?.metadata.creationTime;
    final lastSignIn = user?.metadata.lastSignInTime;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF4E7DC), Color(0xFFE8D9CF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withOpacity(0.4),
                      child: const Icon(Icons.storefront, size: 26, color: Color(0xFF6F574B)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ownerName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: const Color(0xFF3C312C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6D625C),
                            ),
                          ),
                          if (phone != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'โทรศัพท์: $phone',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF6D625C),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const _ProfileInfoChip(
                      icon: Icons.verified_user_outlined,
                      text: 'สิทธิ์: เจ้าของร้าน',
                    ),
                    if (createdAt != null)
                      _ProfileInfoChip(
                        icon: Icons.calendar_today_outlined,
                        text: 'เข้าร่วม: ${_formatDate(createdAt)}',
                      ),
                    if (lastSignIn != null)
                      _ProfileInfoChip(
                        icon: Icons.history_toggle_off,
                        text: 'เข้าสู่ระบบล่าสุด: ${_formatDate(lastSignIn)}',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'การจัดการบัญชี',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: const Color(0xFF4E342E),
            ),
          ),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.edit_outlined,
            title: 'แก้ไขโปรไฟล์',
            subtitle: 'ปรับข้อมูลร้านและช่องทางติดต่อให้เป็นปัจจุบัน',
            color: const Color(0xFF9E857A),
            onTap: () => _handleEditProfile(context),
          ),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.logout,
            title: 'ออกจากระบบ',
            subtitle: 'ออกจากระบบเพื่อสลับบัญชีหรือป้องกันการใช้งาน',
            color: const Color(0xFFB98068),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoChip extends StatelessWidget {
  const _ProfileInfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5F4A40)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF5F4A40),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF3E312C),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7A6E64),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF9C8A7F)),
            ],
          ),
        ),
      ),
    );
  }
}
