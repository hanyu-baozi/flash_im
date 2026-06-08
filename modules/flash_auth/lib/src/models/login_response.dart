class LoginResponse {
  final bool success;
  final String? loginType;
  final String? token;
  final int? userId;
  final String? nickname;
  final String? avatar;
  final bool? hasPassword;
  final String? message;

  LoginResponse({
    required this.success,
    this.loginType,
    this.token,
    this.userId,
    this.nickname,
    this.avatar,
    this.hasPassword,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool,
      loginType: json['login_type'] as String?,
      token: json['token'] as String?,
      userId: json['user_id'] as int?,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      hasPassword: json['has_password'] as bool?,
      message: json['message'] as String?,
    );
  }
}