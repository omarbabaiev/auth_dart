class AuthResponse {
  final bool success;
  final String? token;
  final String? refreshToken;
  final Map<String, dynamic>? user;
  final String? message;
  final String? key;
  final int? statusCode;

  AuthResponse({
    required this.success,
    this.token,
    this.refreshToken,
    this.user,
    this.message,
    this.key,
    this.statusCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (token != null) 'token': token,
      if (refreshToken != null) 'refresh_token': refreshToken,
      if (user != null) 'user': user,
      if (message != null) 'message': message,
      if (key != null) 'key': key,
      if (statusCode != null) 'status_code': statusCode,
    };
  }

  factory AuthResponse.success({
    String? token,
    String? refreshToken,
    Map<String, dynamic>? user,
    String? message,
    String? key,
  }) {
    return AuthResponse(
      success: true,
      token: token,
      refreshToken: refreshToken,
      user: user,
      message: message,
      key: key,
    );
  }

  factory AuthResponse.error({String? message, String? key, int? statusCode}) {
    return AuthResponse(
      success: false,
      message: message,
      key: key,
      statusCode: statusCode,
    );
  }
}
