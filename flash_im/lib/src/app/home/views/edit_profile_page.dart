import 'package:flutter/material.dart';
import 'package:flash_auth/flash_auth.dart';
import 'edit_signature_page.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late int _currentSeed;
  late String _currentName;
  late String? _currentSignature;
  final _repo = AuthRepository();
  bool _isSavingAvatar = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _currentSeed = _resolveSeed(widget.profile);
    _currentName = widget.profile.nickname;
    _currentSignature = widget.profile.signature;
  }

  int _resolveSeed(UserProfile p) {
    final seed = PatternAvatar.getPatternSeed(p);
    return seed ?? p.userId;
  }

  Future<void> _randomizeAvatar() async {
    final newSeed = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _currentSeed = newSeed;
      _isSavingAvatar = true;
      _hasChanges = true;
    });
    try {
      await _repo.updateProfile(
        nickname: _currentName,
        avatar: newSeed.toString(),
        signature: _currentSignature,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _currentSeed = _resolveSeed(widget.profile));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('头像更新失败: $e'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _hasChanges);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          title: const Text('个人资料'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0.5,
        ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildAvatarItem(),
                  _buildInfoItem(
                    title: '名字',
                    value: _currentName,
                    onTap: _showNicknameDialog,
                  ),
                  _buildInfoItem(
                    title: '手机号',
                    value: _maskPhone(widget.profile.phone),
                    onTap: null,
                  ),
                  _buildInfoItem(
                    title: '闪讯号',
                    value: widget.profile.userId.toString(),
                    onTap: null,
                  ),
                  _buildInfoItem(
                    title: '签名',
                    value: _currentSignature?.isNotEmpty == true
                        ? _currentSignature!
                        : '未设置签名',
                    onTap: _navigateToEditSignature,
                    valueColor: _currentSignature?.isNotEmpty == true
                        ? const Color(0xFF999999)
                        : const Color(0xFFCCCCCC),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildAvatarItem() {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: _randomizeAvatar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Text(
                '头像',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF191919),
                ),
              ),
              const Spacer(),
              if (_isSavingAvatar)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: PatternAvatar(
                    seed: _currentSeed,
                    size: 48,
                    borderRadius: 4,
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  size: 18, color: Color(0xFFB2B2B2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required String title,
    required String value,
    required VoidCallback? onTap,
    Color? valueColor,
  }) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF191919),
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? const Color(0xFF999999),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    size: 18, color: Color(0xFFB2B2B2)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length < 11) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }

  void _showNicknameDialog() {
    final ctrl = TextEditingController(text: _currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改名字'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入名字',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final nickname = ctrl.text.trim();
              if (nickname.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('名字不能为空'),
                    backgroundColor: Color(0xFFFF3B30),
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop();
              await _saveProfile(nickname, _currentSignature);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEditSignature() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => EditSignaturePage(
          signature: _currentSignature ?? '',
        ),
      ),
    );
    if (result != null && mounted) {
      await _saveProfile(_currentName, result);
    }
  }

  Future<void> _saveProfile(String nickname, String? signature) async {
    try {
      await _repo.updateProfile(
        nickname: nickname,
        avatar: _currentSeed.toString(),
        signature: signature,
      );
      if (mounted) {
        setState(() {
          _currentName = nickname;
          _currentSignature = signature;
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }
}
