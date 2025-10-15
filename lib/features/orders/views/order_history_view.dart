import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/orders_controller.dart';
import '../models/order_model.dart';

class OrderHistoryView extends StatelessWidget {
  const OrderHistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('กรุณาเข้าสู่ระบบ')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติคำสั่งซื้อ')),
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
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final o = orders[i];
              String orderId = o.id.length >= 8 ? o.id.substring(0, 8) : o.id;
              String status = o.status;
              String finalTotal = o.finalTotal.toStringAsFixed(2);
              String dateStr = '';
              try {
                dateStr = '${o.createdAt.day}/${o.createdAt.month}/${o.createdAt.year}';
              } catch (_) {}
              return ListTile(
                title: Text('Order #$orderId'),
                subtitle: Text('สถานะ: $status\nยอดสุทธิ: ฿$finalTotal'),
                trailing: Text(dateStr),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Order #$orderId'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ชื่อ: ${o.name}'),
                            Text('ที่อยู่: ${o.address}'),
                            Text('เบอร์: ${o.phone}'),
                            Text('สถานะ: $status'),
                            Text('ยอดสุทธิ: ฿$finalTotal'),
                            const SizedBox(height: 8),
                            const Text('รายการสินค้า:'),
                            ...o.items.map((item) {
                              final name = item['name'] ?? '-';
                              final qty = item['quantity'] ?? 1;
                              return Text('- $name x$qty');
                            }).toList(),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
