class UserProfile {
  final int userId;
  final String nickname;
  final String avatar;
  final String phone;
  final String? signature;
  final bool hasPassword;

  UserProfile({
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.phone,
    this.signature,
    this.hasPassword = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      signature: json['signature'] as String?,
      hasPassword: json['has_password'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nickname': nickname,
      'avatar': avatar,
      'phone': phone,
      'signature': signature,
    };
  }
}