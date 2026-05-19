class LoginResponse {
  final bool success;
  final String? token;
  final int? userId;
  final String? message;

  LoginResponse({
    required this.success,
    this.token,
    this.userId,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool,
      token: json['token'] as String?,
      userId: json['user_id'] as int?,
      message: json['message'] as String?,
    );
  }
}
