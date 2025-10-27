import 'dart:io';

import 'package:flutter/foundation.dart';

/// Central place to resolve the backend base URL used by Stripe and Cloudinary.
class BackendConfig {
  BackendConfig._();

  static final Set<String> _placeholderHosts = {'your-backend'};
  static String? _cachedOrigin;

  static List<String> candidateOrigins() {
    final seen = <String>{};
    final result = <String>[];

    void addCandidate(String raw) {
      final sanitized = _sanitize(raw);
      if (sanitized != null && seen.add(sanitized)) {
        result.add(sanitized);
      }
    }

    if (_cachedOrigin != null && seen.add(_cachedOrigin!)) {
      result.add(_cachedOrigin!);
    }

    addCandidate(const String.fromEnvironment('STRIPE_BACKEND_URL', defaultValue: ''));
    addCandidate(const String.fromEnvironment('BACKEND_BASE_URL', defaultValue: ''));

    if (!kIsWeb) {
      if (Platform.isAndroid) {
        addCandidate('http://10.0.2.2:3000');
        addCandidate('http://127.0.0.1:3000');
      } else if (Platform.isIOS) {
        addCandidate('http://127.0.0.1:3000');
        addCandidate('http://localhost:3000');
      } else {
        addCandidate('http://127.0.0.1:3000');
        addCandidate('http://localhost:3000');
      }
    } else {
      addCandidate('http://localhost:3000');
    }

    addCandidate('http://172.20.10.20:3000');
    addCandidate('http://172.20.10.11:3000');

    return result;
  }

  static String resolveBaseUrl() {
    if (_cachedOrigin != null) return _cachedOrigin!;
    final origins = candidateOrigins();
    if (origins.isNotEmpty) return origins.first;
    return 'http://127.0.0.1:3000';
  }

  static void cacheWorkingOrigin(String origin) {
    final sanitized = _sanitize(origin);
    if (sanitized != null) {
      _cachedOrigin = sanitized;
    }
  }

  static String? _sanitize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final normalizedHost = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'^https?://'), '')
        .split('/')
        .first;

    if (_placeholderHosts.contains(normalizedHost)) {
      return null;
    }

    var withScheme = trimmed;
    if (!withScheme.startsWith('http://') && !withScheme.startsWith('https://')) {
      withScheme = 'https://$withScheme';
    }
    return withScheme.endsWith('/') ? withScheme.substring(0, withScheme.length - 1) : withScheme;
  }
}
