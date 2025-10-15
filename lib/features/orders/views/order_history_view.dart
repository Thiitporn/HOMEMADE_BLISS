import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        return const Color(0xFF74512D);
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
        backgroundColor: const Color(0xFF74512D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F4E1),
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
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      backgroundColor: Colors.white,
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF74512D))),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 18, color: Colors.brown[300]),
                                  const SizedBox(width: 6),
                                  Text(dateStr, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.info_outline, size: 18, color: statusColor),
                                  const SizedBox(width: 6),
                                  Text('สถานะ: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.attach_money, size: 18, color: Colors.brown[300]),
                                  const SizedBox(width: 6),
                                  Text('ยอดสุทธิ: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('฿$finalTotal', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(height: 24),
                              const Text('รายการสินค้า:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ...o.items.map((item) {
                                final name = item['name'] ?? '-';
                                final qty = item['quantity'] ?? 1;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text('- $name x$qty'),
                                );
                              }).toList(),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Color(0xFF74512D)),
                                  const SizedBox(width: 6),
                                  Text('ชื่อ: ${o.name}', style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0xFF74512D)),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text('ที่อยู่: ${o.address}', style: const TextStyle(fontSize: 14))),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.phone, color: Color(0xFF74512D)),
                                  const SizedBox(width: 6),
                                  Text('เบอร์: ${o.phone}', style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF74512D),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.chat),
                                    label: const Text('ทักแชทร้าน'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ChatView(
                                            chatId: o.id,
                                            peerName: 'ร้านค้า',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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
                            Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.brown)),
                            const SizedBox(height: 8),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.brown),
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
