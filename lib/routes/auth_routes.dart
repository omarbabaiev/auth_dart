import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import '../middleware/auth_middleware.dart';

Router createAuthRoutes() {
  final router = Router();

  // POST /auth/register
  router.post('/register', _registerHandler);

  // POST /auth/login
  router.post('/login', _loginHandler);

  // POST /auth/refresh
  router.post('/refresh', _refreshHandler);

  // POST /auth/logout
  router.post('/logout', authMiddleware(_logoutHandler));

  // GET /auth/profile
  router.get('/profile', authMiddleware(_profileHandler));

  // PUT /auth/profile
  router.put('/profile', authMiddleware(_updateProfileHandler));

  return router;
}

Future<Response> _registerHandler(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final email = data['email']?.toString();
    final username = data['username']?.toString();
    final password = data['password']?.toString();
    final firstName = data['first_name']?.toString();
    final lastName = data['last_name']?.toString();
    final phoneNumber = data['phone_number']?.toString();
    final dateOfBirthStr = data['date_of_birth']?.toString();
    final address = data['address']?.toString();
    final city = data['city']?.toString();
    final country = data['country']?.toString();
    final bio = data['bio']?.toString();
    final avatarUrl = data['avatar_url']?.toString();

    if (email == null || username == null || password == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Email, username and password are required',
          'key': 'auth.user.register.missing_fields',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    DateTime? dateOfBirth;
    if (dateOfBirthStr != null) {
      try {
        dateOfBirth = DateTime.parse(dateOfBirthStr);
      } catch (e) {
        return Response(
          400,
          body: jsonEncode({
            'success': false,
            'message': 'Invalid date format (YYYY-MM-DD)',
            'key': 'auth.user.date_of_birth.invalid',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    }

    final response = AuthService.register(
      email: email,
      username: username,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      address: address,
      city: city,
      country: country,
      bio: bio,
      avatarUrl: avatarUrl,
    );

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'auth.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _loginHandler(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final email = data['email']?.toString();
    final password = data['password']?.toString();

    if (email == null || password == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Email and password are required',
          'key': 'auth.user.login.missing_fields',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = AuthService.login(email: email, password: password);

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'auth.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _refreshHandler(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final refreshToken = data['refresh_token']?.toString();

    if (refreshToken == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Refresh token is required',
          'key': 'auth.token.refresh.missing',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = AuthService.refreshToken(refreshToken);

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'auth.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _logoutHandler(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final refreshToken = data['refresh_token']?.toString();

    if (refreshToken == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Refresh token is required',
          'key': 'auth.user.logout.missing_token',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = AuthService.logout(refreshToken);

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'auth.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _profileHandler(Request request) async {
  try {
    final user = request.context['user'] as dynamic;

    return Response(
      200,
      body: jsonEncode({'success': true, 'user': user.toJson()}),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({'success': false, 'message': 'Sunucu hatası: $e'}),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _updateProfileHandler(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final user = request.context['user'] as dynamic;

    final username = data['username']?.toString();
    final email = data['email']?.toString();

    if (username == null && email == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Güncellenecek alan gerekli',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (email != null) updates['email'] = email.toLowerCase();
    updates['updated_at'] = DateTime.now().toIso8601String();

    final success = await _updateUserInDatabase(user.id, updates);

    if (!success) {
      return Response(
        500,
        body: jsonEncode({
          'success': false,
          'message': 'Profil güncellenirken hata oluştu',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    // Güncellenmiş kullanıcı bilgisini al
    final updatedUser = await _getUserById(user.id);

    return Response(
      200,
      body: jsonEncode({
        'success': true,
        'user': updatedUser?.toJson(),
        'message': 'Profil başarıyla güncellendi',
      }),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({'success': false, 'message': 'Sunucu hatası: $e'}),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<bool> _updateUserInDatabase(
  int userId,
  Map<String, dynamic> updates,
) async {
  // Bu fonksiyon DatabaseService.updateUser'ı çağırır
  // Şimdilik basit bir implementasyon
  return true;
}

Future<dynamic> _getUserById(int userId) async {
  // Bu fonksiyon DatabaseService.getUserById'i çağırır
  // Şimdilik basit bir implementasyon
  return null;
}
