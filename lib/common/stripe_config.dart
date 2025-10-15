import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeConfig {
  static String? _key;
  // local fallback (must match the same Stripe account as backend)
  static const _fallbackKey = 'pk_test_51SI8SqH0YKCnZGn55sDwlKMz1XWL9zxKUQA30Pqg5gz218neg5hm0JQWCN8xPQ7AxXjNVPp81TQCtf0JvFaoIaEQ00wWp8DEP2';

  static Future<void> ensureInitialized() async {
    if (_key != null && _key!.isNotEmpty) return;
    try {
      final res = await http
          .get(Uri.parse('http://172.20.10.11:3000/stripe-publishable-key'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final key = (json['publishableKey'] as String?)?.trim();
        if (key != null && key.isNotEmpty) {
          _key = key;
        }
      }
    } catch (_) {
      // ignore and fallback
    }
    _key ??= _fallbackKey;
    Stripe.publishableKey = _key!;
    await Stripe.instance.applySettings();
  }
}
