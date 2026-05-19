class UserProfile {
  final int userId;
  final String nickname;
  final String avatar;
  final String phone;

  UserProfile({
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as int,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String,
      phone: json['phone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nickname': nickname,
      'avatar': avatar,
      'phone': phone,
    };
  }

  @override
  String toString() {
    return 'UserProfile(userId: $userId, nickname: $nickname, phone: $phone)';
  }
}
