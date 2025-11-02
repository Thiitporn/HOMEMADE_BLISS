import 'order_history_view.dart';
import 'package:provider/provider.dart';
import '../../cart/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../../../common/stripe_config.dart';
import '../../../common/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  static const _envStripeBackendUrl = String.fromEnvironment('STRIPE_BACKEND_URL', defaultValue: '');
  static const _envBackendUrl = String.fromEnvironment('BACKEND_BASE_URL', defaultValue: '');
  
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
  backgroundColor: const Color(0xFF9E857A),
        elevation: 0,
      ),
  backgroundColor: const Color(0xFFF8F2ED),
      body: SingleChildScrollView(
  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              // Card: Payment Summary
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.receipt_long, color: Color(0xFF9E857A), size: 22),
                          SizedBox(width: 6),
                          Text('สรุปยอดชำระ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF6D4C41))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 13, color: Colors.black87)),
                          Text('฿${order['total'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discount:', style: TextStyle(fontSize: 13, color: Colors.green)),
                          Text('-฿${order['discount'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.green)),
                        ],
                      ),
                      const Divider(height: 18, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Final Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7A5F54))),
                          Text('฿${order['finalTotal'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF7A5F54))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            // Card: Credit Card Info
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: const Color(0xFFF3E5E1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.credit_card, color: Color(0xFF9E857A), size: 18),
                        const SizedBox(width: 6),
                        const Text('ข้อมูลบัตรเครดิต', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF7A5F54))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CardField(
                      onCardChanged: (card) {
                        setState(() => _card = card);
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                      style: const TextStyle(fontSize: 13, letterSpacing: 1.05),
                      numberHintText: '4242 4242 4242 4242',
                      expirationHintText: 'MM/YY',
                      cvcHintText: 'CVC',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // ปุ่มชำระเงิน
            _loading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock, size: 22),
                      label: const Text('ชำระเงิน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9E857A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: Colors.brown.withOpacity(0.24),
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
      // 1. ขอ clientSecret จาก backend โดยไล่ลอง host ที่ใช้ใน dev ทั่วไป
      final response = await _requestPaymentIntent({
        'amount': widget.orderData['finalTotal'],
        'orderId': widget.orderData['id'],
        'currency': 'thb',
      });
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
        String? createdOrderId;
        if (user != null) {
          final orderId = _sanitizeDocId(widget.orderData['id']);
          createdOrderId = orderId;
          final cleanedItems = _sanitizeOrderItems(widget.orderData['items']);
          final couponCode = _resolveCoupon(widget.orderData['coupon']);
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
            if (couponCode != null) 'coupon': couponCode,
            'status': 'paid',
            'createdAt': FieldValue.serverTimestamp(),
          };
          // Only include slipUrl if not empty
          if ((widget.orderData['slipUrl'] ?? '').toString().isNotEmpty) {
            orderData['slipUrl'] = widget.orderData['slipUrl'];
          }
          print('DEBUG: Order data to Firestore:');
          print(orderData);
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .set(orderData);
          // ลด stock สินค้าทุกชิ้นในออเดอร์
          for (final dynamic entry in orderData['items'] as List) {
            if (entry is! Map) continue;
            final item = Map<String, dynamic>.from(entry);

            final productId = (item['productId'] ?? item['id'] ?? '').toString().trim();
            if (productId.isEmpty) continue;

            final rawVariant = item['variant'] ?? item['variantName'];
            final variantName = rawVariant == null ? null : rawVariant.toString().trim();
            final rawQty = item['quantity'];
            final qty = rawQty is num && rawQty > 0 ? rawQty.round() : 1;

            await ProductController.decrementStock(
              productId,
              qty,
              variantName: (variantName == null || variantName.isEmpty) ? null : variantName,
            );
          }
          if (couponCode != null) {
            try {
              await _incrementCouponUsage(couponCode);
            } catch (e) {
              debugPrint('เพิ่มจำนวนการใช้คูปองไม่สำเร็จ: $e');
            }
          }
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
        await _showPaymentSuccessSheet(
          amountText: amountText,
          orderId: createdOrderId ?? widget.orderData['id']?.toString() ?? '',
        );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OrderHistoryView()),
          (route) => route.isFirst,
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

  Future<void> _showPaymentSuccessSheet({required String amountText, required String orderId}) async {
    if (!mounted) return;
    final displayOrderId = orderId.trim().isEmpty ? '-' : orderId.trim();
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final heightFactor = constraints.maxHeight < 600 ? 0.9 : 0.75;
              return FractionallySizedBox(
                heightFactor: heightFactor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            offset: const Offset(0, 12),
                            blurRadius: 32,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE8F5E9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 44),
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'ชำระเงินสำเร็จ!',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Order #$displayOrderId',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF5D4037)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ยอดสุทธิ ฿$amountText',
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF6D4C41)),
                                    ),
                                    const SizedBox(height: 18),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF9C4),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFFBC02D), width: 1.2),
                                      ),
                                      child: Column(
                                        children: const [
                                          Text(
                                            'ระบบบันทึกคำสั่งซื้อของคุณเรียบร้อยแล้ว คุณสามารถติดตามสถานะได้ในเมนูประวัติคำสั่งซื้อ',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Color(0xFF5D4037), fontSize: 13, height: 1.35),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '⚠ โปรดตรวจสอบข้อมูลการจัดส่งให้ถูกต้อง',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Color(0xFFD84315), fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.receipt_long),
                                label: const Text('ดูประวัติคำสั่งซื้อ'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6D4C41),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<String> _buildBackendCandidates() {
    final seen = <String>{};
    final urls = <String>[
      _envStripeBackendUrl,
      _envBackendUrl,
      'http://127.0.0.1:3000',
      'http://localhost:3000',
      'http://127.0.0.1:3000',
      'http://172.20.10.20:3000',
      'http://172.20.10.20:3000',
    ];
    return [for (final url in urls) if (url.isNotEmpty && seen.add(url)) url];
  }

  Future<http.Response> _requestPaymentIntent(Map<String, dynamic> payload) async {
    Exception? lastError;
    for (final baseUrl in _buildBackendCandidates()) {
      final uri = Uri.parse('$baseUrl/create-stripe-payment-intent');
      try {
        debugPrint('Trying backend $baseUrl');
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(
              const Duration(seconds: 12),
            );
        if (response.statusCode == 200) {
          print('PaymentIntent created via $baseUrl');
          return response;
        }
        debugPrint('HTTP ${response.statusCode} from $baseUrl: ${response.body}');
        lastError = Exception('HTTP ${response.statusCode}: ${response.body}');
      } on TimeoutException catch (e) {
        debugPrint('Timeout calling $baseUrl: $e');
        lastError = e;
      } on Exception catch (e) {
        debugPrint('Error calling $baseUrl: $e');
        lastError = e;
      }
    }
    throw lastError ?? Exception('ไม่สามารถเชื่อมต่อ backend สำหรับสร้าง PaymentIntent');
  }

  List<Map<String, dynamic>> _sanitizeOrderItems(dynamic rawItems) {
    if (rawItems is! List || rawItems.isEmpty) return <Map<String, dynamic>>[];
    return rawItems.map<Map<String, dynamic>>((item) {
      final base = item is Map<String, dynamic>
          ? Map<String, dynamic>.from(item)
          : Map<String, dynamic>.from((item as dynamic).toMap() as Map);

      String? imageUrl = base['imageUrl']?.toString().trim();
      if (imageUrl != null) {
        final cleaned = imageUrl.replaceAll(RegExp(r'\s+'), '');
        final uri = Uri.tryParse(cleaned);
        if (uri == null || !uri.hasAbsolutePath || !cleaned.startsWith('http')) {
          imageUrl = null;
        } else {
          imageUrl = cleaned;
        }
      }

      final compoundId = (base['legacyId'] ?? base['productId'] ?? base['id'] ?? '')
          .toString()
          .trim();
      String? productId = base['productId']?.toString().trim();
      String? variantName = base['variant']?.toString().trim();

      if ((productId == null || productId.isEmpty) && compoundId.isNotEmpty) {
        final separatorIndex = compoundId.indexOf('_');
        if (separatorIndex > 0) {
          productId = compoundId.substring(0, separatorIndex);
          variantName ??= compoundId.substring(separatorIndex + 1).trim();
        } else {
          productId = compoundId;
        }
      }

      final rawName = base['name']?.toString().trim();

      double price = 0;
      final rawPrice = base['price'];
      if (rawPrice is num && rawPrice.isFinite) {
        price = rawPrice.toDouble();
      }

      int quantity = 1;
      final rawQty = base['quantity'];
      if (rawQty is num && rawQty > 0 && rawQty.isFinite) {
        quantity = rawQty.round();
      }

      final sanitized = <String, dynamic>{
        if (productId != null && productId.isNotEmpty) ...{
          'productId': productId,
          'id': productId,
        },
        if (variantName != null && variantName.isNotEmpty) 'variant': variantName,
        if (rawName != null && rawName.isNotEmpty) 'name': rawName,
        'price': price,
        'quantity': quantity,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      if (compoundId.isNotEmpty) {
        sanitized['legacyId'] = compoundId;
      }

      return sanitized;
    }).where((item) => (item['productId'] ?? '').toString().isNotEmpty).toList(growable: false);
  }

  String? _resolveCoupon(dynamic rawCoupon) {
    if (rawCoupon == null) return null;
    final coupon = rawCoupon.toString().trim();
    if (coupon.isEmpty || coupon.toLowerCase() == 'null') return null;
    return coupon.toUpperCase();
  }

  String _sanitizeDocId(dynamic rawId) {
    final fallback = DateTime.now().millisecondsSinceEpoch.toString();
    if (rawId == null) return fallback;
    final id = rawId.toString().trim();
    if (id.isEmpty) return fallback;
    final sanitized = id.replaceAll(RegExp(r'[\.~*/\[\]]'), '-');
    return sanitized.isEmpty ? fallback : sanitized;
  }

  Future<void> _incrementCouponUsage(String code) async {
    final query = await FirebaseFirestore.instance
        .collection('coupons')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return;

    final docRef = query.docs.first.reference;
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? <String, dynamic>{};
      final currentUsed = (data['usedCount'] is num) ? (data['usedCount'] as num).toInt() : 0;
      final usageLimit = (data['usageLimit'] is num) ? (data['usageLimit'] as num).toInt() : 0;
      final newUsed = currentUsed + 1;

      final updates = <String, dynamic>{'usedCount': newUsed};
      if (usageLimit > 0 && newUsed >= usageLimit) {
        updates['isActive'] = false;
      }

      transaction.update(docRef, updates);
    });
  }
}

// ใช้ CardField ของ flutter_stripe แล้ว ไม่ต้องมี custom formatter
