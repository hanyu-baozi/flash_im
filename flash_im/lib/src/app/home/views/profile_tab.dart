import 'package:flutter/material.dart';
import 'package:flash_auth/flash_auth.dart';
import 'edit_profile_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _repo = AuthRepository();
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _repo.getProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error.toString());
        }
        final profile = snapshot.data;
        if (profile == null) {
          return const Center(child: Text('获取用户信息失败'));
        }
        return _buildContent(profile);
      },
    );
  }

  Widget _buildContent(UserProfile profile) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(profile),
              const SizedBox(height: 8),
              _buildActionList(profile),
              const SizedBox(height: 16),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: InkWell(
        onTap: () => _navigateToEditProfile(profile),
        child: Row(
          children: [
            _buildAvatar(profile),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.nickname,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF191919),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '闪讯号: ${profile.userId}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                  if (profile.signature?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      profile.signature!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFB2B2B2), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserProfile profile) {
    final seed = _resolveSeed(profile);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: PatternAvatar(seed: seed, size: 56, borderRadius: 6),
    );
  }

  int _resolveSeed(UserProfile profile) {
    final seed = PatternAvatar.getPatternSeed(profile);
    return seed ?? profile.userId;
  }

  Widget _buildActionList(UserProfile profile) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildSimpleTile(
            icon: Icons.lock_outline,
            title: '设置密码',
            onTap: profile.hasPassword
                ? _showChangePasswordDialog
                : _showSetupPasswordDialog,
            isLast: false,
          ),
          _buildSimpleTile(
            icon: Icons.settings_outlined,
            title: '设置',
            onTap: () {},
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTile({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    required bool isLast,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF191919),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: Color(0xFFB2B2B2)),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 48,
            color: Color(0xFFE5E5E5),
          ),
      ],
    );
  }

  void _refreshProfile() {
    final future = _repo.getProfile();
    setState(() { _profileFuture = future; });
  }

  Future<void> _navigateToEditProfile(UserProfile profile) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(profile: profile)),
    );
    if (result == true && mounted) {
      _refreshProfile();
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ChangePasswordDialog(),
    );
  }

  void _showSetupPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PasswordDialog(
        onSetupSuccess: () {
          _refreshProfile();
        },
        onSkip: () {},
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: InkWell(
        onTap: _handleLogout,
        child: Center(
          child: Text(
            '退出登录',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFFF3B30),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确认退出当前账号？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _repo.clearToken();
              if (context.mounted) {
                final navigator = Navigator.of(context);
                navigator.pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => LoginPage(
                      onLoginSuccess: () {
                        navigator.pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const ProfileTab()),
                        );
                      },
                    ),
                  ),
                );
              }
            },
            child: const Text(
              '确认退出',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              size: 48, color: Color(0xFF999999)),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: Color(0xFF999999))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _refreshProfile();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}