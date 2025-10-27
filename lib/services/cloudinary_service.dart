import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../common/backend_config.dart';

/// Wrapper that hits the backend `/upload-image` endpoint to store images in
/// Cloudinary. Keeps API secrets on the server instead of the client.
class CloudinaryService {
  CloudinaryService({String? backendBaseUrl})
      : _backendBaseUrl = backendBaseUrl != null && backendBaseUrl.trim().isNotEmpty
            ? _normalizeBase(backendBaseUrl)
            : BackendConfig.resolveBaseUrl();

  final String _backendBaseUrl;

  Future<String> uploadFile(File file, {String? folder}) async {
    final bytes = await file.readAsBytes();
    final ext = file.path.split('.').last.toLowerCase();
    final mimeType = _guessMime(ext);
    final dataUri = 'data:$mimeType;base64,${base64Encode(bytes)}';

    final uri = Uri.parse('$_backendBaseUrl/upload-image');
    final body = jsonEncode({
      'image': dataUri,
      if (folder != null && folder.isNotEmpty) 'folder': folder,
    });

    try {
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final url = payload['url'] as String?;
        if (url == null || url.isEmpty) {
          throw Exception('Upload response missing url field');
        }
        return url;
      }

      throw Exception('Cloudinary upload failed: HTTP ${response.statusCode} ${response.body}');
    } on SocketException catch (e) {
      throw Exception('เชื่อมต่อไปยัง backend ไม่ได้ ($_backendBaseUrl): ${e.message}');
    } on TimeoutException {
      throw Exception('Backend ไม่ตอบสนอง ($_backendBaseUrl)');
    }
  }

  String _guessMime(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  static String _normalizeBase(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('backendBaseUrl cannot be empty');
    }
    final normalizedHost = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'^https?://'), '')
        .split('/')
        .first;
    if (normalizedHost == 'your-backend') {
      throw ArgumentError('Replace "your-backend" with your actual backend hostname.');
    }
    var withScheme = trimmed;
    if (!withScheme.startsWith('http://') && !withScheme.startsWith('https://')) {
      withScheme = 'https://$withScheme';
    }
    final normalized = withScheme.endsWith('/') ? withScheme.substring(0, withScheme.length - 1) : withScheme;
    BackendConfig.cacheWorkingOrigin(normalized);
    return normalized;
  }
}
