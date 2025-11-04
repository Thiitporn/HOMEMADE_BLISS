import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_view.dart';
import '../../../common/dialog_utils.dart';

class CheckoutView extends StatefulWidget {
  final double totalPrice;
  final List<Map<String, dynamic>> items;
  const CheckoutView({Key? key, required this.totalPrice, required this.items}) : super(key: key);

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedCoupon;
  double _discount = 0;
  List<Map<String, dynamic>> _availableCoupons = [];
  bool _loadingCoupons = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _applyCoupon(String? code) {
    if (code == null) {
      setState(() {
        _discount = 0;
        _selectedCoupon = null;
      });
      return;
    }

    final coupon = _availableCoupons.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {},
    );

    if (coupon.isEmpty) {
      setState(() {
        _discount = 0;
        _selectedCoupon = null;
      });
      return;
    }

    String? errorMessage;
    final orderTotal = widget.totalPrice;
    final minOrderAmount = (coupon['minOrderAmount'] ?? 0).toDouble();
    if (orderTotal < minOrderAmount) {
      errorMessage = 'ยอดสั่งซื้อขั้นต่ำสำหรับคูปองนี้คือ ฿${minOrderAmount.toStringAsFixed(2)}';
    }

    if (errorMessage == null) {
      final expiry = coupon['expiryDate'];
      if (expiry is Timestamp && expiry.toDate().isBefore(DateTime.now())) {
        errorMessage = 'คูปองนี้หมดอายุแล้ว';
      }
    }

    if (errorMessage == null) {
      final usageLimit = (coupon['usageLimit'] ?? 0) as num;
      final usedCount = (coupon['usedCount'] ?? 0) as num;
      if (usageLimit > 0 && usedCount >= usageLimit) {
        errorMessage = 'คูปองนี้ครบโควต้าแล้ว';
      }
    }

    if (errorMessage != null) {
      setState(() {
        _discount = 0;
        _selectedCoupon = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
      return;
    }

    final discountType = (coupon['discountType'] ?? 'percentage') as String;
    final rawDiscountValue = (coupon['discountValue'] ?? 0).toDouble();
    double calculatedDiscount;
    if (discountType == 'percentage') {
      calculatedDiscount = orderTotal * (rawDiscountValue / 100);
    } else {
      calculatedDiscount = rawDiscountValue;
    }
    calculatedDiscount = calculatedDiscount.clamp(0, orderTotal);

    setState(() {
      _discount = calculatedDiscount;
      _selectedCoupon = code;
    });
  }

  Future<void> _fetchCoupons() async {
    setState(() => _loadingCoupons = true);
    final now = DateTime.now();
    final snap = await FirebaseFirestore.instance
        .collection('coupons')
        .where('isActive', isEqualTo: true)
        .get();
    final coupons = snap.docs.map((doc) {
      final data = doc.data();
      final expiry = data['expiryDate'];
      final used = (data['usedCount'] ?? 0) as int;
      final limit = (data['usageLimit'] ?? 0) as int;
      bool expired = false;
      if (expiry != null && expiry is Timestamp) {
        expired = expiry.toDate().isBefore(now);
      }
      bool exhausted = used >= limit;
      if (!expired && !exhausted) {
        return data;
      }
      return null;
    }).whereType<Map<String, dynamic>>().toList();
    setState(() {
      _availableCoupons = coupons;
      _loadingCoupons = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2ED),
      appBar: AppBar(
        title: const Text('ชำระเงิน'),
        backgroundColor: const Color(0xFF9E857A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // สรุปรายการสินค้า
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: Colors.white,
                  shadowColor: Colors.brown.shade100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, color: Color(0xFF9E857A), size: 26),
                            const SizedBox(width: 10),
                            const Text('สรุปรายการสินค้า', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF5D4037))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 20, thickness: 1),
                        ...widget.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFF2E7E1),
                                  boxShadow: [BoxShadow(color: Colors.brown.shade100.withOpacity(0.12), blurRadius: 5, offset: const Offset(0, 2))],
                                ),
                                child: ClipOval(
                                  child: () {
                                    final asset = item['imageAsset']?.toString() ?? '';
                                    final url = item['imageUrl']?.toString() ?? '';
                                    if (asset.isNotEmpty) {
                                      return Image.asset(
                                        asset,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(Icons.image, size: 32),
                                      );
                                    }
                                    if (url.isNotEmpty) {
                                      return Image.network(
                                        url,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Image.asset(
                                          'assets/images/logo.png',
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    }
                                    return const Icon(Icons.image, size: 32);
                                  }(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF5D4037)),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '฿${item['price']} × ${item['quantity']}',
                                      style: const TextStyle(color: Color(0xFF8D6E63), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '฿${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF8D6E63)),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // ข้อมูลการจัดส่ง
                _buildSectionHeader(Icons.local_shipping, 'ข้อมูลการจัดส่ง'),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration('ชื่อ-นามสกุล', Icons.person),
                  validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกชื่อ' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  decoration: _buildInputDecoration('เบอร์โทร', Icons.phone),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'กรุณากรอกเบอร์โทร';
                    if (v.length != 10) return 'กรุณากรอกเบอร์โทร 10 หลัก';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  decoration: _buildInputDecoration('ที่อยู่จัดส่ง', Icons.location_on),
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกที่อยู่' : null,
                ),
                const SizedBox(height: 22),
                
                // คูปองส่วนลด
                _loadingCoupons
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String?>(
                        initialValue: _selectedCoupon,
                        isExpanded: true,
                        decoration: _buildInputDecoration('เลือกคูปองส่วนลด', Icons.local_offer),
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem(value: null, child: Text('ไม่ใช้คูปอง')),
                          ..._availableCoupons.map((c) => DropdownMenuItem<String?>(
                                value: c['code'],
                                child: Text(
                                  '${c['code']} - ${c['description'] ?? ''}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        ],
                        onChanged: _applyCoupon,
                      ),
                const SizedBox(height: 22),
                
                // สรุปราคา
                Card(
                  elevation: 1,
                  color: const Color(0xFFFDF9F4),
                  shadowColor: Colors.brown.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ยอดรวมสินค้า', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF5D4037))),
                            Text('฿${widget.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF8D6E63))),
                          ],
                        ),
                        if (_discount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ส่วนลดคูปอง', style: TextStyle(color: Colors.green, fontSize: 13)),
                              Text('-฿${_discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 13)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(height: 20, thickness: 1.1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ยอดที่ต้องชำระ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF5D4037))),
                            Text(
                              '฿${(widget.totalPrice - _discount).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF8D6E63)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // ปุ่มชำระเงิน
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 22),
                    label: Text(
                      'ยืนยันการสั่งซื้อ',
                      style: GoogleFonts.kanit(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: const Color(0xFF9E857A),
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.kanit(fontWeight: FontWeight.w700, fontSize: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      shadowColor: Colors.brown.withOpacity(0.3),
                    ),
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        'ยืนยันการสั่งซื้อ',
                        'คุณต้องการยืนยันการสั่งซื้อหรือไม่?',
                      );
                      if (!confirmed) return;
                      if (_formKey.currentState?.validate() ?? false) {
                        final orderId = DateTime.now().millisecondsSinceEpoch.toString();
                        final orderItems = widget.items
                            .map((item) => Map<String, dynamic>.from(item))
                            .toList();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaymentView(
                              orderData: {
                                'id': orderId,
                                'name': _nameController.text,
                                'phone': _phoneController.text,
                                'address': _addressController.text,
                                'items': orderItems,
                                'total': widget.totalPrice,
                                'discount': _discount,
                                'finalTotal': widget.totalPrice - _discount,
                                'coupon': _selectedCoupon,
                              },
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF9E857A), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6D4C41)),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    const baseIconColor = Color(0xFF9E857A);
    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: baseIconColor.withOpacity(0.18), width: 1),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF8D6E63), width: 1.4),
    );
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: baseIconColor, size: 22),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      enabledBorder: enabledBorder,
      focusedBorder: focusedBorder,
      border: enabledBorder,
    );
  }
}