import 'dart:io';
import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import '../lib/routes/auth_routes.dart';
import '../lib/routes/social_routes.dart';
import '../lib/services/auth_service.dart';

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..mount('/auth/', createAuthRoutes())
  ..mount('/social/', createSocialRoutes());

Response _rootHandler(Request req) {
  return Response.ok(
    '''
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dart Authentication API</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 30px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        h1 {
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        .endpoint {
            background: rgba(255, 255, 255, 0.1);
            margin: 15px 0;
            padding: 20px;
            border-radius: 10px;
            border-left: 4px solid #4CAF50;
        }
        .method {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 5px;
            font-weight: bold;
            margin-right: 10px;
        }
        .post { background: #4CAF50; }
        .get { background: #2196F3; }
        .put { background: #FF9800; }
        .delete { background: #f44336; }
        .url {
            font-family: 'Courier New', monospace;
            background: rgba(0, 0, 0, 0.3);
            padding: 5px 10px;
            border-radius: 5px;
            color: #FFD700;
        }
        .description {
            margin-top: 10px;
            color: #E0E0E0;
        }
        .status {
            margin-top: 20px;
            padding: 15px;
            border-radius: 5px;
            font-weight: bold;
        }
        .online {
            background: rgba(76, 175, 80, 0.3);
            color: #4CAF50;
        }
        .test-section {
            margin-top: 30px;
            padding: 20px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
        }
        .code-block {
            background: rgba(0, 0, 0, 0.3);
            padding: 15px;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
            margin: 10px 0;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔐 Dart Authentication API</h1>
        
        <div class="status online">
            ✅ Server çalışıyor - http://localhost:8080
        </div>

        <h2>📚 API Endpoints</h2>
        
        <div class="endpoint">
            <span class="method post">POST</span>
            <span class="url">/auth/register</span>
            <div class="description">Yeni kullanıcı kaydı oluşturur</div>
        </div>

        <div class="endpoint">
            <span class="method post">POST</span>
            <span class="url">/auth/login</span>
            <div class="description">Kullanıcı girişi yapar</div>
        </div>

        <div class="endpoint">
            <span class="method post">POST</span>
            <span class="url">/auth/refresh</span>
            <div class="description">Token yeniler</div>
        </div>

        <div class="endpoint">
            <span class="method post">POST</span>
            <span class="url">/auth/logout</span>
            <div class="description">Kullanıcı çıkışı yapar</div>
        </div>

        <div class="endpoint">
            <span class="method get">GET</span>
            <span class="url">/auth/profile</span>
            <div class="description">Kullanıcı profil bilgilerini getirir</div>
        </div>

        <div class="endpoint">
            <span class="method put">PUT</span>
            <span class="url">/auth/profile</span>
            <div class="description">Kullanıcı profil bilgilerini günceller</div>
        </div>

        <div class="endpoint">
            <span class="method get">GET</span>
            <span class="url">/echo/&lt;message&gt;</span>
            <div class="description">Test endpoint</div>
        </div>

        <div class="test-section">
            <h3>🧪 Test Örnekleri</h3>
            
            <h4>Register Test:</h4>
            <div class="code-block">
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "username": "testuser", "password": "password123"}'
            </div>

            <h4>Login Test:</h4>
            <div class="code-block">
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123"}'
            </div>

            <h4>Echo Test:</h4>
            <div class="code-block">
curl http://localhost:8080/echo/hello
            </div>
        </div>
    </div>
</body>
</html>
''',
    headers: {'content-type': 'text/html'},
  );
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests and adds CORS headers.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);

  print('🚀 Authentication Server başlatıldı! (Token düzeltildi)');
  print('📍 Server adresi: http://${server.address.host}:${server.port}');
  print('📚 API dokümantasyonu: http://${server.address.host}:${server.port}/');

  // Periyodik olarak expired token'ları temizle
  Timer.periodic(Duration(hours: 1), (timer) {
    AuthService.cleanupExpiredTokens();
  });
}
