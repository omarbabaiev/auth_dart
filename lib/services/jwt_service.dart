import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class JwtService {
  static const String _secret =
      'your-super-secret-jwt-key-change-in-production';
  static const int _expirationTime = 3600; // 1 saat
  static const int _refreshExpirationTime = 604800; // 7 gün

  static String generateToken(int userId, String email) {
    final header = {'alg': 'HS256', 'typ': 'JWT'};

    final payload = {
      'user_id': userId,
      'email': email,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + _expirationTime,
    };

    final encodedHeader = _base64UrlEncode(jsonEncode(header));
    final encodedPayload = _base64UrlEncode(jsonEncode(payload));
    final signature = _generateSignature('$encodedHeader.$encodedPayload');

    return '$encodedHeader.$encodedPayload.$signature';
  }

  static String generateRefreshToken(int userId) {
    final header = {'alg': 'HS256', 'typ': 'JWT'};

    final payload = {
      'user_id': userId,
      'type': 'refresh',
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp':
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) +
          _refreshExpirationTime,
    };

    final encodedHeader = _base64UrlEncode(jsonEncode(header));
    final encodedPayload = _base64UrlEncode(jsonEncode(payload));
    final signature = _generateSignature('$encodedHeader.$encodedPayload');

    return '$encodedHeader.$encodedPayload.$signature';
  }

  static Map<String, dynamic>? verifyToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final header = jsonDecode(_base64UrlDecode(parts[0]));
      final payload = jsonDecode(_base64UrlDecode(parts[1]));
      final signature = parts[2];

      // Signature doğrulama
      final expectedSignature = _generateSignature('${parts[0]}.${parts[1]}');
      if (signature != expectedSignature) return null;

      // Expiration kontrolü
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (payload['exp'] < currentTime) return null;

      return payload;
    } catch (e) {
      return null;
    }
  }

  static String _generateSignature(String data) {
    final key = utf8.encode(_secret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return _base64UrlEncode(digest.bytes);
  }

  static String _base64UrlEncode(dynamic data) {
    String base64;
    if (data is List<int>) {
      base64 = base64Encode(data);
    } else {
      base64 = base64Encode(utf8.encode(data.toString()));
    }
    return base64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
  }

  static String _base64UrlDecode(String str) {
    String base64 = str.replaceAll('-', '+').replaceAll('_', '/');

    // Padding ekleme
    switch (base64.length % 4) {
      case 0:
        break;
      case 2:
        base64 += '==';
        break;
      case 3:
        base64 += '=';
        break;
      default:
        throw Exception('Invalid base64url string');
    }

    return utf8.decode(base64Decode(base64));
  }
}
