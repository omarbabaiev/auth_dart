# 🔐 Dart Authentication API

A comprehensive authentication backend system built with Dart and Shelf framework. Features JWT authentication, user management, and secure password handling.

## 🌟 Features

- **JWT Authentication** - Secure token-based authentication
- **User Management** - Register, login, logout, profile management
- **Password Security** - BCrypt password hashing
- **Database Support** - SQLite for development, PostgreSQL ready for production
- **CORS Support** - Cross-origin resource sharing enabled
- **Rate Limiting** - Built-in request rate limiting
- **Comprehensive API** - RESTful endpoints with proper error handling
- **Localization Ready** - Response keys for multi-language support

## 🚀 Quick Start

### Prerequisites

- Dart SDK (3.0 or higher)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/auth_dart.git
   cd auth_dart
   ```

2. **Install dependencies**
   ```bash
   dart pub get
   ```

3. **Run the server**
   ```bash
   dart run bin/server.dart
   ```

4. **Test the API**
   ```bash
   curl http://localhost:8080/
   ```

## 📚 API Documentation

### Base URL
```
http://localhost:8080
```

### Authentication Endpoints

#### Register User
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "username": "username",
  "password": "password123",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+905551234567",
  "date_of_birth": "1990-01-01",
  "address": "123 Main Street",
  "city": "Istanbul",
  "country": "Turkey",
  "bio": "Software Developer",
  "avatar_url": "https://example.com/avatar.jpg"
}
```

#### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

#### Refresh Token
```http
POST /auth/refresh
Content-Type: application/json

{
  "refresh_token": "your_refresh_token"
}
```

#### Logout
```http
POST /auth/logout
Authorization: Bearer your_access_token
Content-Type: application/json

{
  "refresh_token": "your_refresh_token"
}
```

### User Management

#### Get Profile
```http
GET /auth/profile
Authorization: Bearer your_access_token
```

#### Update Profile
```http
PUT /auth/profile
Authorization: Bearer your_access_token
Content-Type: application/json

{
  "username": "newusername",
  "email": "newemail@example.com",
  "first_name": "Updated",
  "last_name": "Name",
  "phone_number": "+905551111111",
  "city": "Izmir",
  "country": "Turkey",
  "bio": "Updated bio"
}
```

## 🛠️ Project Structure

```
auth_dart/
├── bin/
│   └── server.dart          # Main server entry point
├── lib/
│   ├── models/
│   │   ├── user.dart        # User data model
│   │   └── auth_response.dart # API response model
│   ├── services/
│   │   ├── auth_service.dart    # Authentication logic
│   │   ├── database_service.dart # Database operations
│   │   └── jwt_service.dart     # JWT token handling
│   ├── middleware/
│   │   └── auth_middleware.dart # Authentication middleware
│   └── routes/
│       └── auth_routes.dart     # API route definitions
├── test/
│   └── server_test.dart     # Integration tests
├── database/                # Database files (gitignored)
├── pubspec.yaml            # Dependencies
├── Dockerfile              # Docker configuration
└── README.md              # This file
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
# Server Configuration
PORT=8080
HOST=0.0.0.0

# JWT Configuration
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRY=24h
REFRESH_TOKEN_EXPIRY=7d

# Database Configuration
DATABASE_URL=sqlite:///database/auth.db
# For PostgreSQL: postgresql://user:password@localhost:5432/auth_db
```

### Database Setup

The application uses SQLite by default. For production, you can switch to PostgreSQL by updating the `DATABASE_URL` in your environment variables.

## 🧪 Testing

Run the test suite:

```bash
dart test
```

Or run specific tests:

```bash
dart test test/server_test.dart
```

## 🐳 Docker Support

Build and run with Docker:

```bash
# Build the image
docker build -t auth_dart .

# Run the container
docker run -p 8080:8080 auth_dart
```

## 📦 Postman Collection

Import the included `postman_collection.json` file into Postman for easy API testing.

## 🔒 Security Features

- **JWT Tokens** - Secure authentication with access and refresh tokens
- **Password Hashing** - BCrypt for secure password storage
- **CORS Protection** - Configurable cross-origin resource sharing
- **Input Validation** - Comprehensive request validation
- **Error Handling** - Secure error responses without sensitive information

## 🌍 Localization Support

All API responses include localization keys for multi-language support:

```json
{
  "success": true,
  "message": "User registered successfully",
  "key": "auth.user.register.success"
}
```

### Common Response Keys

- `auth.user.register.success` - Registration successful
- `auth.user.login.success` - Login successful
- `auth.user.email.invalid` - Invalid email format
- `auth.user.password.too_short` - Password too short
- `auth.user.username.exists` - Username already exists

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Shelf](https://pub.dev/packages/shelf) - Web server framework
- [JWT Decoder](https://pub.dev/packages/jwt_decoder) - JWT token handling
- [BCrypt](https://pub.dev/packages/bcrypt) - Password hashing
- [SQLite3](https://pub.dev/packages/sqlite3) - Database operations

## 📞 Support

If you have any questions or need help, please open an issue on GitHub.

---

**Made with ❤️ using Dart and Shelf**
