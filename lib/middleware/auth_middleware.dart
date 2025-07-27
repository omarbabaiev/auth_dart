import 'package:shelf/shelf.dart';
import '../services/auth_service.dart';
import '../services/jwt_service.dart';

Handler authMiddleware(Handler innerHandler) {
  return (Request request) async {
    // Authorization header'ını al
    final authHeader = request.headers['authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(
        401,
        body: '{"success": false, "message": "Authorization header gerekli"}',
        headers: {'content-type': 'application/json'},
      );
    }

    // Token'ı çıkar
    final token = authHeader.substring(7);

    // Token'ı doğrula
    final payload = JwtService.verifyToken(token);
    if (payload == null) {
      return Response(
        401,
        body: '{"success": false, "message": "Geçersiz token"}',
        headers: {'content-type': 'application/json'},
      );
    }

    // Kullanıcıyı al
    final user = AuthService.getCurrentUser(token);
    if (user == null) {
      return Response(
        401,
        body: '{"success": false, "message": "Kullanıcı bulunamadı"}',
        headers: {'content-type': 'application/json'},
      );
    }

    // Kullanıcı bilgisini request'e ekle
    final updatedRequest = request.change(
      context: {'user': user, 'user_id': user.id, 'email': user.email},
      headers: {...request.headers, 'user-id': user.id.toString()},
    );

    return innerHandler(updatedRequest);
  };
}

Handler optionalAuthMiddleware(Handler innerHandler) {
  return (Request request) async {
    final authHeader = request.headers['authorization'];

    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring(7);
      final payload = JwtService.verifyToken(token);

      if (payload != null) {
        final user = AuthService.getCurrentUser(token);
        if (user != null) {
          final updatedRequest = request.change(
            context: {'user': user, 'user_id': user.id, 'email': user.email},
            headers: {...request.headers, 'user-id': user.id.toString()},
          );
          return innerHandler(updatedRequest);
        }
      }
    }

    return innerHandler(request);
  };
}
