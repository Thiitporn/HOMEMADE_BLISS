import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_view.dart';

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
      appBar: AppBar(
        title: const Text('ชำระเงิน'),
        backgroundColor: Colors.brown[700],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // สรุปรายการสินค้า
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('สรุปรายการสินค้า', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const Divider(),
                        ...widget.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: () {
                                  final asset = item['imageAsset']?.toString() ?? '';
                                  final url = item['imageUrl']?.toString() ?? '';
                                  if (asset.isNotEmpty) {
                                    return Image.asset(
                                      asset,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(Icons.image),
                                    );
                                  }
                                  if (url.isNotEmpty) {
                                    return Image.network(
                                      url,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Image.asset(
                                        'assets/images/logo.png',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  }
                                  return const Icon(Icons.image, size: 40);
                                }(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                                    Text('฿${item['price']} × ${item['quantity']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text('฿${(item['price'] * item['quantity']).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // ข้อมูลการจัดส่ง
                const Text('ข้อมูลการจัดส่ง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อ-นามสกุล',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกชื่อ' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'เบอร์โทร',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกเบอร์โทร' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'ที่อยู่จัดส่ง',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกที่อยู่' : null,
                ),
                const SizedBox(height: 20),
                
                // คูปองส่วนลด
                _loadingCoupons
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedCoupon,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'เลือกคูปองส่วนลด',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.local_offer),
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
                const SizedBox(height: 20),
                
                // สรุปราคา
                Card(
                  elevation: 2,
                  color: Colors.brown[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ยอดรวม'),
                            Text('฿${widget.totalPrice.toStringAsFixed(2)}'),
                          ],
                        ),
                        if (_discount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ส่วนลด', style: TextStyle(color: Colors.green)),
                              Text('-฿${_discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                            ],
                          ),
                        ],
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ยอดสุทธิ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text(
                              '฿${(widget.totalPrice - _discount).toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown[700]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // ปุ่มชำระเงิน
                ElevatedButton.icon(
                  icon: const Icon(Icons.credit_card, size: 24),
                  label: const Text('ชำระเงินด้วยบัตรเครดิต', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: Colors.brown[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
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
                              'items': widget.items,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}