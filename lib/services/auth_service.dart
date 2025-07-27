import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import 'database_service.dart';
import 'jwt_service.dart';

class AuthService {
  static AuthResponse register({
    required String email,
    required String username,
    required String password,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    String? country,
    String? bio,
    String? avatarUrl,
  }) {
    // Email format validation
    if (!_isValidEmail(email)) {
      return AuthResponse.error(
        message: 'Invalid email format',
        key: 'auth.user.email.invalid',
        statusCode: 400,
      );
    }

    // Password security validation
    if (password.length < 6) {
      return AuthResponse.error(
        message: 'Password must be at least 6 characters',
        key: 'auth.user.password.too_short',
        statusCode: 400,
      );
    }

    // Username validation
    if (username.length < 3) {
      return AuthResponse.error(
        message: 'Username must be at least 3 characters',
        key: 'auth.user.username.too_short',
        statusCode: 400,
      );
    }

    // Check if email already exists
    final existingUserByEmail = DatabaseService.getUserByEmail(email);
    if (existingUserByEmail != null) {
      return AuthResponse.error(
        message: 'Email already exists',
        key: 'auth.user.email.exists',
        statusCode: 409,
      );
    }

    // Check if username already exists
    final existingUserByUsername = DatabaseService.getUserByUsername(username);
    if (existingUserByUsername != null) {
      return AuthResponse.error(
        message: 'Username already exists',
        key: 'auth.user.username.exists',
        statusCode: 409,
      );
    }

    // Hash password
    final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

    // Create new user
    final user = User(
      email: email.toLowerCase(),
      username: username,
      passwordHash: passwordHash,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      address: address,
      city: city,
      country: country,
      bio: bio,
      avatarUrl: avatarUrl,
      createdAt: DateTime.now(),
    );

    try {
      final userId = DatabaseService.createUser(user);
      final createdUser = DatabaseService.getUserById(userId);

      if (createdUser == null) {
        return AuthResponse.error(
          message: 'Failed to create user',
          key: 'auth.user.create.failed',
          statusCode: 500,
        );
      }

      // Generate JWT token
      final token = JwtService.generateToken(userId, createdUser.email);
      final refreshToken = JwtService.generateRefreshToken(userId);

      // Save refresh token to database
      final expiresAt = DateTime.now().add(Duration(days: 7));
      DatabaseService.saveRefreshToken(userId, refreshToken, expiresAt);

      return AuthResponse.success(
        token: token,
        refreshToken: refreshToken,
        user: createdUser.toJson(),
        message: 'User registered successfully',
        key: 'auth.user.register.success',
      );
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to create user: $e',
        key: 'auth.user.create.error',
        statusCode: 500,
      );
    }
  }

  static AuthResponse login({required String email, required String password}) {
    // Find user
    final user = DatabaseService.getUserByEmail(email.toLowerCase());
    if (user == null) {
      return AuthResponse.error(
        message: 'Invalid email or password',
        key: 'auth.user.login.invalid_credentials',
        statusCode: 401,
      );
    }

    // Verify password
    final isValidPassword = BCrypt.checkpw(password, user.passwordHash);
    if (!isValidPassword) {
      return AuthResponse.error(
        message: 'Invalid email or password',
        key: 'auth.user.login.invalid_credentials',
        statusCode: 401,
      );
    }

    // Generate JWT token
    final token = JwtService.generateToken(user.id!, user.email);
    final refreshToken = JwtService.generateRefreshToken(user.id!);

    // Save refresh token to database
    final expiresAt = DateTime.now().add(Duration(days: 7));
    DatabaseService.saveRefreshToken(user.id!, refreshToken, expiresAt);

    return AuthResponse.success(
      token: token,
      refreshToken: refreshToken,
      user: user.toJson(),
      message: 'Login successful',
      key: 'auth.user.login.success',
    );
  }

  static AuthResponse refreshToken(String refreshToken) {
    // Verify refresh token
    final payload = JwtService.verifyToken(refreshToken);
    if (payload == null) {
      return AuthResponse.error(
        message: 'Invalid refresh token',
        key: 'auth.token.refresh.invalid',
        statusCode: 401,
      );
    }

    // Check refresh token in database
    if (!DatabaseService.validateRefreshToken(refreshToken)) {
      return AuthResponse.error(
        message: 'Invalid refresh token',
        key: 'auth.token.refresh.invalid',
        statusCode: 401,
      );
    }

    final userId = payload['user_id'] as int;
    final user = DatabaseService.getUserById(userId);

    if (user == null) {
      return AuthResponse.error(
        message: 'User not found',
        key: 'auth.user.not_found',
        statusCode: 404,
      );
    }

    // Generate new tokens
    final newToken = JwtService.generateToken(userId, user.email);
    final newRefreshToken = JwtService.generateRefreshToken(userId);

    // Delete old refresh token
    DatabaseService.deleteRefreshToken(refreshToken);

    // Save new refresh token
    final expiresAt = DateTime.now().add(Duration(days: 7));
    DatabaseService.saveRefreshToken(userId, newRefreshToken, expiresAt);

    return AuthResponse.success(
      token: newToken,
      refreshToken: newRefreshToken,
      user: user.toJson(),
      message: 'Token refreshed successfully',
      key: 'auth.token.refresh.success',
    );
  }

  static AuthResponse logout(String refreshToken) {
    DatabaseService.deleteRefreshToken(refreshToken);
    return AuthResponse.success(
      message: 'Logout successful',
      key: 'auth.user.logout.success',
    );
  }

  static User? getCurrentUser(String token) {
    final payload = JwtService.verifyToken(token);
    if (payload == null) return null;

    final userId = payload['user_id'] as int;
    return DatabaseService.getUserById(userId);
  }

  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  static void cleanupExpiredTokens() {
    DatabaseService.deleteExpiredRefreshTokens();
  }
}
