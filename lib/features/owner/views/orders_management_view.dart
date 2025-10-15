import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersManagementView extends StatefulWidget {
  const OrdersManagementView({super.key});

  @override
  State<OrdersManagementView> createState() => _OrdersManagementViewState();
}

class _OrdersManagementViewState extends State<OrdersManagementView> {
  String selectedFilter = 'all';
  
  @override
  Widget build(BuildContext context) {
    final Color darkBrown = const Color(0xFF4E342E);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF3EF),
        elevation: 0,
        title: Text('จัดการคำสั่งซื้อ', style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: darkBrown),
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ทั้งหมด', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('รอยืนยัน', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('กำลังทำ', 'preparing'),
                  const SizedBox(width: 8),
                  _buildFilterChip('เสร็จแล้ว', 'completed'),
                ],
              ),
            ),
          ),
          // Orders list
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                      ],
                    ),
                  );
                }
                
                final allDocs = snapshot.data?.docs ?? [];
                final docs = _filterOrders(allDocs);
                
                // Debug: แสดงจำนวนและสถานะของคำสั่งซื้อ
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          selectedFilter == 'all' 
                            ? 'ยังไม่มีคำสั่งซื้อ' 
                            : 'ไม่มีคำสั่งซื้อที่มีสถานะ "${_getFilterDisplayName(selectedFilter)}"',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        if (selectedFilter != 'all' && allDocs.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '(มีคำสั่งซื้อทั้งหมด ${allDocs.length} รายการ)',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data();
                    return _buildOrderCard(doc.id, data);
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: docs.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    final Color mediumBrown = const Color(0xFF8D6E63);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = value;
        });
      },
      selectedColor: mediumBrown.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? mediumBrown : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
  
  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'all': return 'ทั้งหมด';
      case 'pending': return 'รอยืนยัน';
      case 'preparing': return 'กำลังทำ';
      case 'ready': return 'พร้อมส่ง';
      case 'completed': return 'เสร็จแล้ว';
      case 'cancelled': return 'ยกเลิก';
      case 'paid': return 'ชำระเงินแล้ว';
      default: return filter;
    }
  }
  
  Stream<QuerySnapshot<Map<String, dynamic>>> _getOrdersStream() {
    // ดึงข้อมูลทั้งหมดแล้ว filter ฝั่ง client เพื่อไม่ต้องสร้าง composite index
    return FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs
  ) {
    if (selectedFilter == 'all') {
      return docs;
    }
    return docs.where((doc) {
      final status = doc.data()['status'] as String?;
      return status == selectedFilter;
    }).toList();
  }
  
  Widget _buildOrderCard(String orderId, Map<String, dynamic> data) {
    final Color darkBrown = const Color(0xFF4E342E);
    final Color lightBorder = const Color(0xFFD7CCC8);
    final Color mediumBrown = const Color(0xFF8D6E63);
    
    final customerName = (data['name'] ?? 'ลูกค้า') as String;
    final status = (data['status'] ?? 'pending') as String;
    final totalAmount = (data['finalTotal'] ?? data['total'] ?? 0).toDouble();
    final items = (data['items'] ?? []) as List;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final notes = (data['notes'] ?? '') as String;
    final phone = (data['phone'] ?? '') as String;
    
    String statusText = _getStatusText(status);
    Color statusColor = _getStatusColor(status);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'คำสั่งซื้อ #${orderId.substring(0, 8)}',
                        style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(customerName, style: TextStyle(color: Colors.grey[600])),
                      if (phone.isNotEmpty) Text('Tel: $phone', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Items
            ...items.map((item) {
              final name = item['name'] ?? '';
              final variant = item['variant'] ?? '';
              final quantity = item['quantity'] ?? 0;
              final price = (item['price'] ?? 0).toDouble();
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('$name${variant.isNotEmpty ? ' ($variant)' : ''}', style: const TextStyle(fontSize: 14)),
                    ),
                    Text('x$quantity', style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 16),
                    Text('฿${(price * quantity).toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
            
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(child: Text(notes, style: TextStyle(color: Colors.grey[700]))),
                  ],
                ),
              ),
            ],
            
            const Divider(),
            
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'รวม: ฿${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (createdAt != null)
                        Text(
                          '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (status != 'completed' && status != 'cancelled')
                  Flexible(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mediumBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 4,
                      ),
                      onPressed: () => _updateOrderStatus(orderId, status),
                      child: Text(
                        _getNextStatusText(status),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status == 'completed' ? 'เสร็จสิ้น' : 'ยกเลิก',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'รอยืนยัน';
      case 'preparing':
        return 'กำลังทำ';
      case 'ready':
        return 'พร้อม';
      case 'completed':
        return 'เสร็จแล้ว';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getNextStatusText(String status) {
    switch (status) {
      case 'pending':
      case 'paid':
        return 'ยืนยัน';
      case 'preparing':
        return 'เสร็จแล้ว';
      default:
        return 'อัปเดต';
    }
  }
  
  Future<void> _updateOrderStatus(String orderId, String currentStatus) async {
    String nextStatus;
    String notificationTitle;
    String notificationBody;
    
    switch (currentStatus) {
      case 'pending':
      case 'paid':
        nextStatus = 'preparing';
        notificationTitle = '🎉 คำสั่งซื้อของคุณได้รับการยืนยันแล้ว';
        notificationBody = 'ร้านกำลังเตรียมสินค้าให้คุณ รอติดตามได้เลยนะคะ';
        break;
      case 'preparing':
        nextStatus = 'completed';
        notificationTitle = '✅ คำสั่งซื้อของคุณเสร็จแล้ว!';
        notificationBody = 'สินค้าของคุณพร้อมแล้ว ขอบคุณที่อุดหนุนค่ะ 💕';
        break;
      default:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ไม่สามารถอัปเดตสถานะ "$currentStatus" ได้'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
    }
    
    try {
      // 1. อัปเดตสถานะใน Firebase
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': nextStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // 2. ส่งการแจ้งเตือนไปหาลูกค้า (in-app notification)
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      
      final orderData = orderDoc.data();
      final userId = orderData?['userId'] as String?;
      
      if (userId != null) {
        // สร้าง in-app notification
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add({
          'title': notificationTitle,
          'body': notificationBody,
          'orderId': orderId,
          'type': 'order_status',
          'status': nextStatus,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('อัปเดตสถานะเป็น ${_getStatusText(nextStatus)} และแจ้งเตือนลูกค้าแล้ว'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}