import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


enum QrProvider { omise, stripe }

class PromptPayQrView extends StatefulWidget {
  final double amount;
  final String orderId;
  final QrProvider provider;
  const PromptPayQrView({Key? key, required this.amount, required this.orderId, this.provider = QrProvider.stripe}) : super(key: key);

  @override
  State<PromptPayQrView> createState() => _PromptPayQrViewState();
}

class _PromptPayQrViewState extends State<PromptPayQrView> {
  String? qrUrl;
  String? chargeId;
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.provider == QrProvider.stripe) {
      _createStripeQr();
    } else {
      _createPromptPayCharge();
    }
  }

  Future<void> _createPromptPayCharge() async {
    setState(() { loading = true; error = null; });
    try {
      final response = await http.post(
        Uri.parse('http://172.20.10.11:3000/create-promptpay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': widget.amount,
          'orderId': widget.orderId,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          qrUrl = data['qr'];
          chargeId = data['chargeId'];
          loading = false;
        });
      } else {
        setState(() {
          error = 'สร้าง QR ไม่สำเร็จ: ${response.body}';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'เกิดข้อผิดพลาด: $e';
        loading = false;
      });
    }
  }

  Future<void> _createStripeQr() async {
    setState(() { loading = true; error = null; });
    try {
      final response = await http.post(
        Uri.parse('http://172.20.10.11:3000/create-stripe-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': widget.amount,
          'orderId': widget.orderId,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          qrUrl = data['qrUrl'];
          chargeId = data['paymentIntentId'];
          loading = false;
        });
      } else {
        setState(() {
          error = 'สร้าง QR Stripe ไม่สำเร็จ: ${response.body}';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'เกิดข้อผิดพลาด: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget qrWidget;
    if (qrUrl != null) {
      print('qrUrl: $qrUrl');
    }
    if (qrUrl != null && qrUrl!.startsWith('data:image')) {
      try {
        final base64Str = qrUrl!.split(',').last;
        print('base64Str preview: \'${base64Str.substring(0, base64Str.length > 100 ? 100 : base64Str.length)}\'');
        qrWidget = Image.memory(base64Decode(base64Str), width: 220, height: 220);
      } catch (e) {
        qrWidget = Text('QR base64 ผิดรูปแบบ: $e', style: const TextStyle(color: Colors.red));
      }
    } else if (qrUrl != null && qrUrl!.isNotEmpty) {
      qrWidget = Image.network(qrUrl!, width: 220, height: 220, errorBuilder: (c, e, s) => Text('QR URL ผิด: $e', style: const TextStyle(color: Colors.red)));
    } else {
      qrWidget = const Text('ไม่สามารถสร้าง QR ได้', style: TextStyle(color: Colors.red));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('ชำระเงินด้วย PromptPay')),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : error != null
                ? Text(error!, style: const TextStyle(color: Colors.red))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('ยอดเงิน: ฿${widget.amount.toStringAsFixed(2)}'),
                      const SizedBox(height: 16),
                      qrWidget,
                      const SizedBox(height: 16),
                      Text('สแกน QR ด้วยแอปธนาคารเพื่อชำระเงิน'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          if (widget.provider == QrProvider.stripe) {
                            _createStripeQr();
                          } else {
                            _createPromptPayCharge();
                          }
                        },
                        child: Text(widget.provider == QrProvider.stripe ? 'สร้าง QR Stripe ใหม่' : 'สร้าง QR Omise ใหม่'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
