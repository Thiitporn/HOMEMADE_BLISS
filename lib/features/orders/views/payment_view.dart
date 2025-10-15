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
        backgroundColor: Colors.brown[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ยอดเงิน
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('ยอดที่ต้องชำระ', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      '฿${order['finalTotal'].toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.brown[700]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // ข้อมูลบัตร
            const Text('ข้อมูลบัตรเครดิต', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            CardField(
              onCardChanged: (card) {
                setState(() => _card = card);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 16),
              numberHintText: '4242 4242 4242 4242',
              expirationHintText: 'MM/YY',
              cvcHintText: 'CVC',
            ),
            const SizedBox(height: 8),
            Text(
              'ทดสอบ: ใช้เลขบัตร 4242 4242 4242 4242',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 32),
            
            // ปุ่มชำระเงิน
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.credit_card, size: 24),
                    label: const Text('ชำระเงิน', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: Colors.brown[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (_card?.complete == true && !_loading) ? _payWithCard : null,
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
        Uri.parse('http://172.20.10.11:3000/create-stripe-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': widget.orderData['finalTotal'],
          'orderId': widget.orderData['id'],
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
          final order = OrderModel(
            id: orderId,
            userId: user.uid,
            name: widget.orderData['name'] ?? '',
            phone: widget.orderData['phone'] ?? '',
            address: widget.orderData['address'] ?? '',
            items: List<Map<String, dynamic>>.from(widget.orderData['items'] ?? []),
            total: (widget.orderData['total'] ?? 0).toDouble(),
            discount: (widget.orderData['discount'] ?? 0).toDouble(),
            finalTotal: (widget.orderData['finalTotal'] ?? 0).toDouble(),
            coupon: widget.orderData['coupon'],
            slipUrl: '',
            status: OrderStatus.paid,
            createdAt: DateTime.now(), // Will be overwritten by serverTimestamp below
          );
          await OrdersController().createOrder(order);
          // ลด stock สินค้าทุกชิ้นในออเดอร์
          for (final item in order.items) {
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
