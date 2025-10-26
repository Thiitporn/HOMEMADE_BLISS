import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/dialog_utils.dart';
import '../../notifications/notification_service.dart' as in_app_notifications;

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF6ECE5), Color(0xFFEFE3D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ทั้งหมด', 'all'),
                    const SizedBox(width: 10),
                    _buildFilterChip('รอยืนยัน', 'pending'),
                    const SizedBox(width: 10),
                    _buildFilterChip('กำลังทำ', 'preparing'),
                    const SizedBox(width: 10),
                    _buildFilterChip('เสร็จแล้ว', 'completed'),
                  ],
                ),
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
                final summary = _buildStatusSummary(allDocs);
                
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      final doc = docs[0];
                      final data = doc.data();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (summary.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _StatusOverview(summary: summary),
                            ),
                          _buildOrderCard(doc.id, data),
                        ],
                      );
                    }
                    final doc = docs[i];
                    final data = doc.data();
                    return _buildOrderCard(doc.id, data);
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
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
    final Color unselected = const Color(0xFFCCC0B8);

    return ChoiceChip(
      label: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() => selectedFilter = value);
      },
      backgroundColor: Colors.white.withOpacity(0.6),
      selectedColor: mediumBrown,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : unselected,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected ? mediumBrown : Colors.white.withOpacity(0.0),
        ),
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

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
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

  List<_StatusMetric> _buildStatusSummary(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) {
      return const [];
    }
    final counts = <String, int>{};
    for (final doc in docs) {
      final status = (doc.data()['status'] ?? 'unknown').toString();
      counts.update(status, (value) => value + 1, ifAbsent: () => 1);
    }
    final total = docs.length;
    final List<_StatusMetric> metrics = [
      _StatusMetric(
        label: 'ทั้งหมด',
        count: total,
        color: const Color(0xFF8D6E63),
        icon: Icons.list_alt,
      ),
    ];
    const statusOrder = ['pending', 'preparing', 'ready', 'completed'];
    for (final status in statusOrder) {
      final count = counts[status] ?? 0;
      if (count == 0) continue;
      metrics.add(
        _StatusMetric(
          label: _getStatusText(status),
          count: count,
          color: _getStatusColor(status),
          icon: _statusIcon(status),
        ),
      );
    }
    final remaining = counts.keys
        .where((status) => !statusOrder.contains(status))
        .toList();
    for (final status in remaining) {
      final count = counts[status] ?? 0;
      if (count == 0) continue;
      metrics.add(
        _StatusMetric(
          label: _getStatusText(status),
          count: count,
          color: _getStatusColor(status),
          icon: _statusIcon(status),
        ),
      );
    }
    return metrics;
  }
  
  Widget _buildOrderCard(String orderId, Map<String, dynamic> data) {
    final Color darkBrown = const Color(0xFF4E342E);
    final Color lightBorder = const Color(0xFFD7CCC8);
    final Color mediumBrown = const Color(0xFF8D6E63);
    
    final customerName = (data['name'] ?? 'ลูกค้า') as String;
    final status = (data['status'] ?? 'pending') as String;
  final totalAmount = _toDouble(data['finalTotal'] ?? data['total']);
    final items = (data['items'] ?? []) as List;
  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final notes = (data['notes'] ?? '') as String;
    final phone = (data['phone'] ?? '') as String;
    
    String statusText = _getStatusText(status);
    Color statusColor = _getStatusColor(status);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [Colors.white, statusColor.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: lightBorder.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final showInlineChip = constraints.maxWidth > 320;

                    Widget buildStatusChip() {
                      return Container(
                        constraints: const BoxConstraints(maxWidth: 120),
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(status), size: 12, color: statusColor),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                statusText,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'คำสั่งซื้อ #${orderId.substring(0, 8)}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: darkBrown,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline, size: 13, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          customerName,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 11,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (phone.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.phone_outlined, size: 12, color: Colors.grey[500]),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            phone,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (showInlineChip) ...[
                              const SizedBox(width: 12),
                              buildStatusChip(),
                            ],
                          ],
                        ),
                        if (!showInlineChip)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: buildStatusChip(),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (items.isNotEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < items.length; i++)
                          _OrderItemRow(
                            data: items[i] as Map<String, dynamic>,
                            accent: statusColor,
                            toDouble: _toDouble,
                            isLast: i == items.length - 1,
                          ),
                      ],
                    ),
                  ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _OrderNote(notes: notes),
                ],
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ยอดรวม',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '฿${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: darkBrown,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          if (createdAt != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDate(createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (status != 'completed' && status != 'cancelled')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mediumBrown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final confirmed = await showConfirmDialog(
                            context,
                            'อัปเดตคำสั่งซื้อ',
                            'คุณต้องการอัปเดตสถานะคำสั่งซื้อนี้หรือไม่?',
                          );
                          if (!confirmed) return;
                          await _updateOrderStatus(orderId, status);
                        },
                        child: Text(
                          _getNextStatusText(status),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          status == 'completed' ? 'เสร็จสิ้น' : 'ยกเลิก',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_outlined;
      case 'preparing':
        return Icons.local_fire_department_outlined;
      case 'ready':
        return Icons.delivery_dining_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
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
        await in_app_notifications.NotificationService.addNotification(
          userId: userId,
          title: notificationTitle,
          body: notificationBody,
          orderId: orderId,
          type: 'order_status',
          status: nextStatus,
        );
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

class _StatusMetric {
  const _StatusMetric({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
}

class _StatusOverview extends StatelessWidget {
  const _StatusOverview({required this.summary});

  final List<_StatusMetric> summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBF2EA), Color(0xFFF0E3D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            const SizedBox(width: 4),
            for (int i = 0; i < summary.length; i++) ...[
              _StatusMetricTile(data: summary[i], theme: theme),
              if (i != summary.length - 1) const SizedBox(width: 12),
            ],
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _StatusMetricTile extends StatelessWidget {
  const _StatusMetricTile({required this.data, required this.theme});

  final _StatusMetric data;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: data.color.withOpacity(0.16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            data.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4E342E),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${data.count} รายการ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF7A6F66),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.data,
    required this.accent,
    required this.toDouble,
    required this.isLast,
  });

  final Map<String, dynamic> data;
  final Color accent;
  final double Function(dynamic value) toDouble;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? '').toString();
    final variant = (data['variant'] ?? '').toString();
    final quantityRaw = data['quantity'];
    final quantity = quantityRaw is num
        ? quantityRaw
        : int.tryParse(quantityRaw?.toString() ?? '0') ?? 0;
    final price = toDouble(data['price'] ?? data['finalPrice']);
    final quantityColor = _darken(accent, amount: 0.18);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Color(0xFF3F372F),
                      ),
                    ),
                    if (variant.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          variant,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.end,
                    runAlignment: WrapAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'x$quantity',
                          style: TextStyle(
                            color: quantityColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        '฿${(price * quantity).toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4E342E),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 0,
            thickness: 1,
            color: Colors.grey.withOpacity(0.1),
          ),
      ],
    );
  }

  Color _darken(Color color, {double amount = .1}) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

class _OrderNote extends StatelessWidget {
  const _OrderNote({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EFE9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.note_alt_outlined, size: 16, color: Color(0xFF8D6E63)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notes,
              style: const TextStyle(
                color: Color(0xFF5C5149),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}