import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import 'backend_config.dart';

class StripeConfig {
  static String? _key;
  static const _envPublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static Future<void> ensureInitialized() async {
    if (_key != null && _key!.isNotEmpty) return;
    if (_envPublishableKey.isNotEmpty) {
      _key = _envPublishableKey;
    }
    if (_key == null) {
      for (final origin in _backendOrigins()) {
        try {
          final res = await http
              .get(Uri.parse('$origin/stripe-publishable-key'))
              .timeout(const Duration(seconds: 3));
          if (res.statusCode == 200) {
            final json = jsonDecode(res.body) as Map<String, dynamic>;
            final key = (json['publishableKey'] as String?)?.trim();
            if (key != null && key.isNotEmpty) {
              BackendConfig.cacheWorkingOrigin(origin);
              _key = key;
              break;
            }
          }
        } catch (_) {
          // ignore and try next origin
        }
      }
    }
    if (_key == null || _key!.isEmpty) {
      throw StateError(
        'Stripe publishable key ไม่ถูกตั้งค่า: โปรดกำหนด STRIPE_PUBLISHABLE_KEY หรือให้ backend คืนค่า /stripe-publishable-key.',
      );
    }
    Stripe.publishableKey = _key!;
    await Stripe.instance.applySettings();
  }

  static List<String> _backendOrigins() {
    return BackendConfig.candidateOrigins();
  }
}
