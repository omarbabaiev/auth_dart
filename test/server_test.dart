import 'dart:io';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('Authentication API Tests', () {
    late http.Client client;
    late Process serverProcess;
    const baseUrl = 'http://localhost:8080';

    setUpAll(() async {
      // Server'ı başlat
      serverProcess = await Process.start(
        'dart',
        ['run', 'bin/server.dart'],
        environment: {'PORT': '8080'},
      );

      // Server'ın başlamasını bekle
      await Future.delayed(Duration(seconds: 3));
    });

    tearDownAll(() async {
      // Server'ı durdur
      serverProcess.kill();
    });

    setUp(() {
      client = http.Client();
    });

    tearDown(() {
      client.close();
    });

    test('GET / returns API documentation', () async {
      final response = await client.get(Uri.parse('$baseUrl/'));
      expect(response.statusCode, 200);
      expect(response.body, contains('Dart Authentication API'));
    });

    test('POST /auth/register creates new user', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body:
            '{"email": "test${DateTime.now().millisecondsSinceEpoch}@example.com", "username": "testuser${DateTime.now().millisecondsSinceEpoch}", "password": "password123"}',
      );

      expect(response.statusCode, 200);
      final body = response.body;
      expect(body, contains('"success":true'));
      expect(body, contains('"token"'));
      expect(body, contains('"refresh_token"'));
    });

    test('POST /auth/register with invalid email returns error', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body:
            '{"email": "invalid-email", "username": "testuser2", "password": "password123"}',
      );

      expect(response.statusCode, 400);
      final body = response.body;
      expect(body, contains('"success":false'));
      expect(body, contains('Invalid email format'));
    });

    test('POST /auth/register with short password returns error', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body:
            '{"email": "test2@example.com", "username": "testuser3", "password": "123"}',
      );

      expect(response.statusCode, 400);
      final body = response.body;
      expect(body, contains('"success":false'));
      expect(body, contains('Password must be at least 6 characters'));
    });

    test('POST /auth/login with valid credentials returns token', () async {
      // Önce kullanıcı oluştur
      final email = 'login${DateTime.now().millisecondsSinceEpoch}@example.com';
      final username = 'loginuser${DateTime.now().millisecondsSinceEpoch}';

      final registerResponse = await client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body:
            '{"email": "$email", "username": "$username", "password": "password123"}',
      );

      expect(registerResponse.statusCode, 200);

      // Kısa bir bekleme süresi
      await Future.delayed(Duration(milliseconds: 500));

      // Sonra giriş yap
      final response = await client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: '{"email": "$email", "password": "password123"}',
      );

      expect(response.statusCode, 200);
      final body = response.body;
      expect(body, contains('"success":true'));
      expect(body, contains('"token"'));
      expect(body, contains('"refresh_token"'));
    });

    test('POST /auth/login with invalid credentials returns error', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body:
            '{"email": "nonexistent@example.com", "password": "wrongpassword"}',
      );

      expect(response.statusCode, 401);
      final body = response.body;
      expect(body, contains('"success":false'));
      expect(body, contains('Invalid email or password'));
    });

    test('GET /echo/<message> returns the message', () async {
      final response = await client.get(Uri.parse('$baseUrl/echo/hello'));
      expect(response.statusCode, 200);
      expect(response.body, 'hello\n');
    });
  });
}
