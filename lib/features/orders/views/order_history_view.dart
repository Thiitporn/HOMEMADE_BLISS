import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homemade_bliss/util/theme/theme.dart';
import '../controllers/orders_controller.dart';
import '../models/order_model.dart';
import '../../chat/chat_view.dart';

class OrderHistoryView extends StatelessWidget {
  const OrderHistoryView({Key? key}) : super(key: key);

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'รอยืนยัน';
      case 'preparing':
        return 'กำลังเตรียม';
      case 'ready':
        return 'พร้อมส่ง';
      case 'completed':
        return 'เสร็จสิ้น';
      case 'cancelled':
        return 'ยกเลิก';
      case 'paid':
        return 'ชำระเงินแล้ว';
      default:
        return status;
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
      case 'paid':
        return Colors.teal;
      default:
        return kPrimaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('กรุณาเข้าสู่ระบบ')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติคำสั่งซื้อ', style: TextStyle(fontWeight: FontWeight.bold)),
  backgroundColor: const Color(0xFF9E857A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
  backgroundColor: const Color(0xFFF8F2ED),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrdersController().userOrders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data;
          if (orders == null || orders.isEmpty) {
            return const Center(child: Text('ยังไม่มีประวัติคำสั่งซื้อ'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final o = orders[i];
              String orderId = o.id.length >= 8 ? o.id.substring(0, 8) : o.id;
              String status = o.status;
              String statusText = _getStatusText(status);
              Color statusColor = _getStatusColor(status);
              String finalTotal = o.finalTotal.toStringAsFixed(2);
              String dateStr = '';
              try {
                dateStr = '${o.createdAt.day}/${o.createdAt.month}/${o.createdAt.year}';
              } catch (_) {}
              Color cardColor = Colors.white;
              return Card(
                elevation: 2,
                color: cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (sheetCtx) {
                        final items = o.items;
                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: FractionallySizedBox(
                              heightFactor: 0.88,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 24,
                                      offset: const Offset(0, -4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 10),
                                    Center(
                                      child: Container(
                                        width: 48,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0D5C6),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Order #$orderId',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: kPrimaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today, size: 18, color: kPrimaryColor),
                                                const SizedBox(width: 8),
                                                Text(
                                                  dateStr,
                                                  style: const TextStyle(fontSize: 13, color: Color(0xFF6D4C41)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 18),
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF4EBE0),
                                                borderRadius: BorderRadius.circular(18),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.info_outline, size: 20, color: statusColor),
                                                      const SizedBox(width: 8),
                                                      const Text('สถานะ', style: TextStyle(fontWeight: FontWeight.w600)),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        statusText,
                                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.attach_money, size: 20, color: kPrimaryColor),
                                                      const SizedBox(width: 8),
                                                      const Text('ยอดสุทธิ', style: TextStyle(fontWeight: FontWeight.w600)),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '฿$finalTotal',
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 22),
                                            const Text(
                                              'รายการสินค้า',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5D4037)),
                                            ),
                                            const SizedBox(height: 10),
                                            if (items.isEmpty)
                                              const Text('ไม่พบรายการสินค้า', style: TextStyle(color: kPrimaryColor)),
                                            ...items.map((item) {
                                              final name = (item['name'] ?? '-').toString();
                                              final qty = item['quantity'] ?? 1;
                                              final variant = item['variant'];
                                              final price = item['price'];
                                              String? priceText;
                                              if (price is num) {
                                                priceText = '฿${price.toStringAsFixed(2)}';
                                              }
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 10),
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFF8F0),
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFE0CAB5),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: const Icon(Icons.cookie, color: Colors.white, size: 18),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5D4037))),
                                                          if (variant != null && variant.toString().isNotEmpty)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 2),
                                                              child: Text('ตัวเลือก: ${variant.toString()}', style: const TextStyle(fontSize: 12, color: Color(0xFF8D6E63))),
                                                            ),
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 4),
                                                            child: Text('จำนวน: $qty', style: const TextStyle(fontSize: 12, color: Color(0xFF6D4C41))),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (priceText != null)
                                                      Text(priceText, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6D4C41))),
                                                  ],
                                                ),
                                              );
                                            }),
                                            const SizedBox(height: 18),
                                            const Text(
                                              'ข้อมูลการติดต่อ',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5D4037)),
                                            ),
                                            const SizedBox(height: 10),
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF6EFE6),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Icon(Icons.person, color: Color(0xFF9E857A)),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text('ชื่อ: ${o.name}', style: const TextStyle(fontSize: 14, color: Color(0xFF5D4037))),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Icon(Icons.location_on, color: Color(0xFF9E857A)),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text('ที่อยู่: ${o.address}', style: const TextStyle(fontSize: 14, color: Color(0xFF5D4037))),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.phone, color: Color(0xFF9E857A)),
                                                      const SizedBox(width: 10),
                                                      Text('เบอร์: ${o.phone}', style: const TextStyle(fontSize: 14, color: Color(0xFF5D4037))),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF9E857A),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                          icon: const Icon(Icons.chat_bubble_outline),
                                          label: const Text('ทักแชทร้าน'),
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            final result = await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => ChatView(
                                                  chatId: o.id,
                                                  peerName: 'ร้านค้า',
                                                ),
                                              ),
                                            );
                                            if (!context.mounted) return;
                                            if (result == 'archived') {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('ซ่อนแชทแล้ว')),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFAF8F6F),
                          child: const Icon(Icons.receipt_long, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('สถานะ: $statusText', style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                              Text('ยอดสุทธิ: ฿$finalTotal', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(dateStr, style: const TextStyle(fontSize: 12, color: kPrimaryColor)),
                            const SizedBox(height: 8),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: kPrimaryColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
