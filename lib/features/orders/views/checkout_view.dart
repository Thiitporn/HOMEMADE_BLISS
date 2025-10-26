import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final coupon = _availableCoupons.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {},
    );
    setState(() {
      if (coupon.isNotEmpty && code != null) {
        if (coupon['discountType'] == 'percentage') {
          _discount = (coupon['discountValue'] ?? 0) / 100 * widget.totalPrice;
        } else {
          _discount = (coupon['discountValue'] ?? 0).toDouble();
        }
      } else {
        _discount = 0;
      }
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
  backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(
        title: const Text('ชำระเงิน'),
        backgroundColor: const Color(0xFF8D6E63),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white,
                  shadowColor: Colors.brown.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, color: Color(0xFF6D4C41), size: 26),
                            const SizedBox(width: 8),
                            const Text('สรุปรายการสินค้า', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF5D4037))),
                          ],
                        ),
                        const Divider(height: 24, thickness: 1),
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
                                  color: const Color(0xFFF8F4F0),
                                  boxShadow: [BoxShadow(color: Colors.brown.shade100.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
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
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF5D4037)),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '฿${item['price']} × ${item['quantity']}',
                                      style: const TextStyle(color: Color(0xFF8D6E63), fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '฿${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8D6E63)),
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
                Row(
                  children: [
                    const Icon(Icons.local_shipping, color: Color(0xFF6D4C41), size: 24),
                    SizedBox(width: 8),
                    const Text('ข้อมูลการจัดส่ง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF5D4037))),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: Colors.white,
                  shadowColor: Colors.brown.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'ชื่อ-นามสกุล',
                        labelStyle: const TextStyle(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF6D4C41), size: 22),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกชื่อ' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 8),
                Card(
                  elevation: 1,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: Colors.white,
                  shadowColor: Colors.brown.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'เบอร์โทร',
                        labelStyle: const TextStyle(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.phone, color: Color(0xFF6D4C41), size: 22),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      ),
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
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 8),
                Card(
                  elevation: 1,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: Colors.white,
                  shadowColor: Colors.brown.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextFormField(
                      controller: _addressController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'ที่อยู่จัดส่ง',
                        labelStyle: const TextStyle(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.location_on, color: Color(0xFF6D4C41), size: 22),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      ),
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกที่อยู่' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // คูปองส่วนลด
                _loadingCoupons
                    ? const Center(child: CircularProgressIndicator())
                    : Card(
                        elevation: 1,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        color: Colors.white,
                        shadowColor: Colors.brown.shade100,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCoupon,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'เลือกคูปองส่วนลด',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.local_offer, color: Color(0xFF6D4C41), size: 22),
                            ),
                            items: <DropdownMenuItem<String>>[
                              const DropdownMenuItem(value: null, child: Text('ไม่ใช้คูปอง')),
                              ..._availableCoupons.map((c) => DropdownMenuItem(
                                    value: c['code'],
                                    child: Text(
                                      '${c['code']} - ${c['description'] ?? ''}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )),
                            ],
                            onChanged: _applyCoupon,
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                
                // สรุปราคา
                Card(
                  elevation: 1,
                  color: const Color(0xFFF8F4F0),
                  shadowColor: Colors.brown.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF5D4037))),
                            Text('฿${widget.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8D6E63))),
                          ],
                        ),
                        if (_discount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount', style: TextStyle(color: Colors.green, fontSize: 11)),
                              Text('-฿${_discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 11)),
                            ],
                          ),
                        ],
                        const Divider(height: 16, thickness: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Final Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF5D4037))),
                            Text(
                              '฿${(widget.totalPrice - _discount).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF8D6E63)),
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
                    icon: const Icon(Icons.check_circle_outline, size: 22, color: Color(0xFF6D4C41)),
                    label: const Text('ยืนยันการสั่งซื้อ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(32),
                      backgroundColor: const Color(0xFF8D6E63),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      shadowColor: Colors.brown.shade200,
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaymentView(
                              orderData: {
                                'id': orderId,
                                'name': _nameController.text,
                                'phone': _phoneController.text,
                                'address': _addressController.text,
                                'items': widget.items
                                    .map((item) => item is Map<String, dynamic> ? item : (item as dynamic).toMap())
                                    .toList(),
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
}