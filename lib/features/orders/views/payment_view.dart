import 'order_history_view.dart';
import 'package:provider/provider.dart';
import '../../cart/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../common/stripe_config.dart';
import '../../../common/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import '../controllers/orders_controller.dart';
import '../../products/controllers/product_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class PaymentView extends StatefulWidget {
  final Map<String, dynamic> orderData;
  const PaymentView({Key? key, required this.orderData}) : super(key: key);

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  bool _loading = false;
  CardFieldInputDetails? _card;
  
  @override
  void dispose() {
    // No controllers to dispose when using CardField
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final order = widget.orderData;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ชำระเงินด้วยบัตรเครดิต'),
        backgroundColor: const Color(0xFF6D4C41),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F3F0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card: Payment Summary
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: Color(0xFF8D6E63), size: 28),
                        SizedBox(width: 10),
                        Text('สรุปยอดชำระ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6D4C41))),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 16, color: Colors.black87)),
                        Text('฿${order['total'].toStringAsFixed(2)}', style: TextStyle(fontSize: 16, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:', style: TextStyle(fontSize: 16, color: Colors.green)),
                        Text('-฿${order['discount'].toStringAsFixed(2)}', style: TextStyle(fontSize: 16, color: Colors.green)),
                      ],
                    ),
                    const Divider(height: 28, thickness: 1.2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Final Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6D4C41))),
                        Text('฿${order['finalTotal'].toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6D4C41))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Card: Credit Card Info
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Color(0xFFF3E5E1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.credit_card, color: Color(0xFF8D6E63), size: 22),
                        SizedBox(width: 8),
                        Text('ข้อมูลบัตรเครดิต', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6D4C41))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CardField(
                      onCardChanged: (card) {
                        setState(() => _card = card);
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      ),
                      style: const TextStyle(fontSize: 16, letterSpacing: 1.2),
                      numberHintText: '4242 4242 4242 4242',
                      expirationHintText: 'MM/YY',
                      cvcHintText: 'CVC',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            // ปุ่มชำระเงิน
            _loading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock, size: 26),
                      label: const Text('ชำระเงิน', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D4C41),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: Colors.brown.withOpacity(0.3),
                      ),
                      onPressed: (_card?.complete == true && !_loading) ? _payWithCard : null,
                    ),
                  ),
          ],
        ),
      ),
    );
  }


  Future<void> _payWithCard() async {
    // ให้แน่ใจว่า Stripe ถูกตั้งค่าแล้ว (กรณีเปิดจอโดยตรง)
    await StripeConfig.ensureInitialized();
    // ตรวจสอบข้อมูลบัตรก่อน (ต้องให้ CardField กรอกครบ)
    if (_card?.complete != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลบัตรให้ครบถ้วน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _loading = true);
    try {
      print('กำลังเรียก backend...');
      // 1. ขอ clientSecret จาก backend
      final response = await http.post(
        Uri.parse('http://172.20.10.20:3000/create-stripe-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': widget.orderData['finalTotal'],
          'orderId': widget.orderData['id'],
          'currency': 'thb',
        }),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        throw Exception('สร้าง PaymentIntent ไม่สำเร็จ: ${response.body}');
      }
      final data = jsonDecode(response.body);
      final clientSecret = data['clientSecret'];

      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('ไม่ได้รับ clientSecret จาก backend');
      }

      print('กำลัง confirm payment...');
      // 2. ใช้ข้อมูลจาก CardField (Flutter Stripe จะส่งไปที่ native ให้เอง)

      // 3. Confirm Payment
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: const BillingDetails(),
          ),
        ),
      );
      
      if (mounted) {
        // 1. Create order in Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final orderId = widget.orderData['id'].toString();
          // Clean items as before
          final cleanedItems = (widget.orderData['items'] as List)
              .map((item) {
                final map = item is Map<String, dynamic>
                    ? Map<String, dynamic>.from(item)
                    : (item as dynamic).toMap() as Map<String, dynamic>;
                map.forEach((k, v) {
                  if (v is String) map[k] = v.trim();
                });
                map.removeWhere((k, v) => v == null || k == null || k.toString().trim().isEmpty || (v is! String && v is! num && v is! bool));
                if (map.containsKey('imageUrl')) {
                  var url = map['imageUrl'];
                  if (url is String) {
                    url = url.replaceAll(RegExp(r'\s+'), '');
                    final uri = Uri.tryParse(url);
                    final isValidUrl = url.startsWith('http') && uri != null && uri.hasAbsolutePath;
                    if (!isValidUrl) {
                      map.remove('imageUrl');
                    } else {
                      map['imageUrl'] = url;
                    }
                  } else {
                    map.remove('imageUrl');
                  }
                }
                if (map.containsKey('id')) {
                  final idVal = map['id'];
                  if (idVal is String) map['id'] = idVal.replaceAll(RegExp(r'\s+'), '');
                }
                if (map.containsKey('price')) {
                  final price = map['price'];
                  if (price is num && (!price.isFinite || price.isNaN)) map['price'] = 0;
                }
                if (map.containsKey('quantity')) {
                  final qty = map['quantity'];
                  if (qty is! int || qty <= 0) map['quantity'] = 1;
                }
                if (map.containsKey('createdAt')) map.remove('createdAt');
                return map;
              })
              .toList();
          // Build Firestore order data
          final orderData = <String, dynamic>{
            'id': orderId,
            'userId': user.uid,
            'name': widget.orderData['name'] ?? '',
            'phone': widget.orderData['phone'] ?? '',
            'address': widget.orderData['address'] ?? '',
            'items': cleanedItems,
            'total': ((widget.orderData['total'] ?? 0) is num && (widget.orderData['total'] ?? 0).isFinite)
                ? (widget.orderData['total'] ?? 0).toDouble()
                : 0.0,
            'discount': ((widget.orderData['discount'] ?? 0) is num && (widget.orderData['discount'] ?? 0).isFinite)
                ? (widget.orderData['discount'] ?? 0).toDouble()
                : 0.0,
            'finalTotal': ((widget.orderData['finalTotal'] ?? 0) is num && (widget.orderData['finalTotal'] ?? 0).isFinite)
                ? (widget.orderData['finalTotal'] ?? 0).toDouble()
                : 0.0,
            'coupon': widget.orderData['coupon'],
            'status': 'paid',
            'createdAt': FieldValue.serverTimestamp(),
          };
          // Only include slipUrl if not empty
          if ((widget.orderData['slipUrl'] ?? '').toString().isNotEmpty) {
            orderData['slipUrl'] = widget.orderData['slipUrl'];
          }
          print('DEBUG: Order data to Firestore:');
          print(orderData);
          await FirebaseFirestore.instance.collection('orders').doc(orderId).set(orderData);
          // ลด stock สินค้าทุกชิ้นในออเดอร์
          for (final item in orderData['items'] as List) {
            final productId = item['id'] ?? item['productId'];
            final qty = item['quantity'] ?? 1;
            if (productId != null && qty != null) {
              await ProductController.decrementStock(productId.toString(), qty as int);
            }
          }
          // Overwrite createdAt with serverTimestamp
          await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        setState(() => _loading = false);
        final amountText = (widget.orderData['finalTotal'] as num).toStringAsFixed(2);
        await NotificationService.showPaymentSuccess(
          amount: amountText,
          orderId: widget.orderData['id']?.toString(),
        );
        if (!mounted) return;
        // รีเซ็ตตะกร้าสินค้า
        try {
          final cart = Provider.of<CartController>(context, listen: false);
          cart.clear();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ชำระเงินสำเร็จ! ✓'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // ไปหน้าประวัติคำสั่งซื้อแบบ pushReplacement เพื่อไม่ให้ stack ซ้อน
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OrderHistoryView()),
        );
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ใช้ CardField ของ flutter_stripe แล้ว ไม่ต้องมี custom formatter
