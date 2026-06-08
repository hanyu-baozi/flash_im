# 用户个人信息编辑 + 密码管理 — 客户端任务清单

基于 [design.md](./design.md) 设计，列出需要创建/修改的具体细节。

**全局约束：**
- 状态管理：不引入额外框架，使用 `setState` + `FutureBuilder`
- 风格参考：参考已有 `PasswordDialog` 的样式和代码结构
- 头像图案：6×6 网格水平轴对称，`CustomPainter` 实现
- `hasPassword` 字段需要从后端 `GET /user/profile` 返回并在 model 中解析

---

## 执行顺序

1. ⬜ 任务 1 — 服务端：新增 `PUT /user/profile` 接口 + `hasPassword` 返回字段（无依赖）
2. ⬜ 任务 2 — `api_config.dart`：新增路径常量（无依赖）
3. ⬜ 任务 3 — `user_profile.dart`：新增 `hasPassword` 字段（无依赖）
4. ⬜ 任务 4 — `auth_api_service.dart`：新增 `changePassword` / `updateProfile` 方法（依赖任务 2、3）
5. ⬜ 任务 5 — `auth_repository.dart`：新增 `changePassword` / `updateProfile` 方法（依赖任务 4）
6. ⬜ 任务 6 — `pattern_avatar.dart`：新建对称方块图案头像组件（无依赖）
7. ⬜ 任务 7 — `change_password_dialog.dart`：新建修改密码弹窗（依赖任务 5）
8. ⬜ 任务 8 — `edit_profile_page.dart`：新建编辑资料页面（依赖任务 5、6）
9. ⬜ 任务 9 — `profile_tab.dart`：重构 — 接入图案头像、编辑/密码入口、刷新逻辑（依赖任务 5、6、7、8）
10. ⬜ 任务 10 — `flash_auth.dart`：导出新增文件（依赖任务 6、7）
11. ⬜ 最后 — 编译验证

---

## 任务 1：`user.rs` + `lib.rs` — 服务端新增 `PUT /user/profile` + `hasPassword` 返回 `⬜ 待处理`

文件：`e:\flutter_project\client\IM\server\modules\flash_auth\src\user.rs`（修改）
文件：`e:\flutter_project\client\IM\server\modules\flash_auth\src\lib.rs`（修改）

> 注：此任务为服务端改动，不在客户端清单中展开子任务。仅列出所需的接口契约供 client 端对齐。

### 1.1 新增 `PUT /user/profile` 处理器 `⬜`

- 接收 `{ "nickname": "string", "avatar": "string" }`（两个字段均可选）
- 从 Authorization header 解析 JWT token，获取 phone
- 根据 phone 查询用户，存在则更新 `nickname` / `avatar_url` 字段（只更新传入的字段）
- 返回 `{ "success": true, "message": "资料更新成功" }`

### 1.2 `GET /user/profile` 返回增加 `has_password` 字段 `⬜`

- 在 `ProfileResponse` 中 `has_password` 字段已定义，确认返回逻辑正确
- 确保空密码时返回 `false`

### 1.3 注册路由 `⬜`

- 在 `lib.rs` 的 `routes()` 中添加 `.route("/user/profile", put(user::update_profile))`

---

## 任务 2：`api_config.dart` — 新增路径常量 `⬜ 待处理`

文件：`e:\flutter_project\client\modules\flash_auth\lib\src\config\api_config.dart`

### 2.1 新增路径常量 `⬜`

```dart
static const String changePasswordPath = '/auth/password';
static const String updateProfilePath = '/user/profile';
```

> **理由**：`changePasswordPath` 指向已有的 `POST /auth/password`；`updateProfilePath` 指向新增的 `PUT /user/profile`。

---

## 任务 3：`user_profile.dart` — 新增 `hasPassword` 字段 `⬜ 待处理`

文件：`e:\flutter_project\client\modules\flash_auth\lib\src\models\user_profile.dart`

### 3.1 新增字段与工厂方法适配 `⬜`

```dart
class UserProfile {
  final int userId;
  final String nickname;
  final String avatar;
  final String phone;
  final bool hasPassword;  // 新增

  UserProfile({
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.phone,
    this.hasPassword = false,  // 默认 false
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      hasPassword: json['has_password'] as bool? ?? false,  // 新增
    );
  }
}
```

> **注意**：`toJson()` 不需要添加 `hasPassword`（只读字段，不回传给服务端）。

---

## 任务 4：`auth_api_service.dart` — 新增 `changePassword` / `updateProfile` 方法 `⬜ 待处理`

文件：`e:\flutter_project\client\modules\flash_auth\lib\src\services\auth_api_service.dart`

### 4.1 新增 `changePassword` 方法 `⬜`

```dart
Future<bool> changePassword(
  String oldPassword,
  String newPassword,
  String token,
) async {
  // 1. POST ApiConfig.changePasswordPath
  // 2. body: { 'old_password': oldPassword, 'new_password': newPassword }
  // 3. headers: { 'Authorization': 'Bearer $token' }
  // 4. 解析 response.data['success'] == true → return true
  // 5. 失败时 throw Exception(data['message'])
  // 6. DioException 用 _handleDioError 处理
}
```

### 4.2 新增 `updateProfile` 方法 `⬜`

```dart
Future<bool> updateProfile({
  String? nickname,
  String? avatar,
  required String token,
}) async {
  // 1. PUT ApiConfig.updateProfilePath
  // 2. body: { if (nickname != null) 'nickname': nickname, if (avatar != null) 'avatar': avatar }
  // 3. headers: { 'Authorization': 'Bearer $token' }
  // 4. 解析 response.data['success'] == true → return true
  // 5. 失败时 throw Exception(data['message'])
  // 6. DioException 用 _handleDioError 处理
}
```

> **注意**：Dio 的 `_dio.put(...)` 方法，body 与 post 传参方式一致。

---

## 任务 5：`auth_repository.dart` — 新增 `changePassword` / `updateProfile` 方法 `⬜ 待处理`

文件：`e:\flutter_project\client\modules\flash_auth\lib\src\repositories\auth_repository.dart`

### 5.1 新增 `changePassword` 方法 `⬜`

```dart
Future<bool> changePassword(String oldPassword, String newPassword) async {
  // 1. final token = await getToken();
  // 2. if (token == null) throw Exception('未登录');
  // 3. return _apiService.changePassword(oldPassword, newPassword, token);
}
```

### 5.2 新增 `updateProfile` 方法 `⬜`

```dart
Future<bool> updateProfile({String? nickname, String? avatar}) async {
  // 1. final token = await getToken();
  // 2. if (token == null) throw Exception('未登录');
  // 3. return _apiService.updateProfile(nickname: nickname, avatar: avatar, token: token);
}
```

---

## 任务 6：`pattern_avatar.dart` — 新建对称方块图案头像组件 `⬜ 待处理`

文件：`e:\flutter_project\client\modules\flash_auth\lib\src\widgets\pattern_avatar.dart`（新建）

### 6.1 `PatternPainter` — CustomPainter 绘制逻辑 `⬜`

```dart
class PatternPainter extends CustomPainter {
  final int seed;
  final int gridSize;    // 默认 6
  final Color fillColor; // 默认 0xFF4F46E5
  final Color bgColor;   // 默认 Colors.white

  // shouldRepaint: old.seed != seed || old.gridSize != gridSize

  // paint() 逻辑：
  // 1. final rng = Random(seed);
  // 2. 计算 cellSize = size.width / gridSize
  // 3. 计算半边列数 halfCols = (gridSize / 2).ceil()
  // 4. 遍历每行 (0..gridSize)，每行遍历左半边列 (0..halfCols):
  //    a. rng.nextBool() 决定是否填充
  //    b. 左列: col * cellSize → 绘制方形
  //    c. 右列(镜像): (gridSize - 1 - col) * cellSize → 绘制同色方形
  // 5. fillColor 填充实心格，bgColor 填充空心格
}
```

### 6.2 `PatternAvatar` — StatelessWidget 封装 `⬜`

```dart
class PatternAvatar extends StatelessWidget {
  final int seed;
  final double size;
  final int gridSize;
  final double borderRadius;

  // build():
  //   return ClipRRect(
  //     borderRadius: borderRadius,
  //     child: CustomPaint(
  //       size: Size(size, size),
  //       painter: PatternPainter(seed: seed, gridSize: gridSize),
  //     ),
  //   );
}
```

### 6.3 从 `UserProfile` 解析种子 `⬜`

在合适位置（可在 `PatternAvatar` 上提供静态方法，或在 UserProfile 上添加 getter）：

```dart
/// 从 profile 获取头像种子
/// - 如果 avatar 是纯数字字符串 → 解析为 patternSeed
/// - 如果是 http URL → 使用自定义头像（返回 null，PatternAvatar 不可用）
/// - 如果是空字符串 → 使用 userId 作为默认种子
static int? getPatternSeed(UserProfile profile) {
  final avatar = profile.avatar.trim();
  if (avatar.isEmpty) return profile.userId;
  final seed = int.tryParse(avatar);
  if (seed != null) return seed;
  return null; // 自定义 URL 头像
}
```

---

## 任务 7：`change_password_dialog.dart` — 新建修改密码弹窗 `⬜ 待处理`

文件：`e:\flutter_project\client\modules\flash_auth\lib\src\views\change_password_dialog.dart`（新建）

### 7.1 `ChangePasswordDialog` StatefulWidget `⬜`

```dart
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}
```

参考 `PasswordDialog` 结构，差异如下：
- **三个输入框**：原密码、新密码、确认新密码（每个带 obscureText 切换）
- **content**：使用 `Column(mainAxisSize: MainAxisSize.min)` 排列三个 TextField
- **校验逻辑**：
  1. 原密码非空
  2. 新密码 ≥ 6 位
  3. 新密码 ≠ 原密码（提示不要与原密码相同）
  4. 确认新密码与 newPassword 一致
- **actions**：`取消`（Navigator.pop）+ `确认`（调用 `_handleChange`）
- **loading 状态**：确认过程中禁用按钮、显示 CircularProgressIndicator
- **错误提示**：通过 SnackBar 显示（与 PasswordDialog 一致）

### 7.2 `_handleChange` 方法 `⬜`

```dart
final _repo = AuthRepository();

Future<void> _handleChange() async {
  // 1. 执行上述校验
  // 2. setState(() => _isLoading = true)
  // 3. await _repo.changePassword(oldPassword, newPassword)
  // 4. 成功 → Navigator.pop(context)
  // 5. 失败 → SnackBar 显示错误 → setState(() => _isLoading = false)
}
```

---

## 任务 8：`edit_profile_page.dart` — 新建编辑资料页面 `⬜ 待处理`

文件：`e:\flutter_project\client\flash_im\lib\src\app\home\views\edit_profile_page.dart`（新建）

### 8.1 `EditProfilePage` StatefulWidget `⬜`

```dart
class EditProfilePage extends StatefulWidget {
  final UserProfile profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}
```

### 8.2 状态初始化 `⬜`

```dart
class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nicknameCtrl;
  late int _currentSeed;       // 当前图案种子
  final _repo = AuthRepository();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.profile.nickname);
    _currentSeed = _resolveSeed(widget.profile);
  }

  int _resolveSeed(UserProfile p) {
    final seed = PatternAvatar.getPatternSeed(p);
    return seed ?? p.userId;
  }

  void _randomizeAvatar() {
    setState(() => _currentSeed = DateTime.now().millisecondsSinceEpoch);
  }
}
```

### 8.3 UI 结构 `⬜`

```dart
// build() → Scaffold(
//   backgroundColor: Color(0xFFF8F8F8),
//   appBar: AppBar(
//     title: '编辑资料',
//     backgroundColor: Colors.white,
//   ),
//   body: SingleChildScrollView → Column:
//     1. SizedBox(height: 32)
//     2. 居中 PatternAvatar(size: 100, seed: _currentSeed)
//     3. SizedBox(height: 12)
//     4. TextButton('随机更换', onPressed: _randomizeAvatar)
//     5. SizedBox(height: 32)
//     6. Container(白色卡片, margin: 16, borderRadius: 12):
//        Padding → TextField(
//          controller: _nicknameCtrl,
//          decoration: InputDecoration(labelText: '昵称', border: OutlineInputBorder(...)),
//        )
//     7. SizedBox(height: 32)
//     8. Padding(margin: 16) → SizedBox(width: double.infinity, height: 48):
//        ElevatedButton('保存', onPressed: _isSaving ? null : _handleSave)
// )
```

### 8.4 `_handleSave` 方法 `⬜`

```dart
Future<void> _handleSave() async {
  final nickname = _nicknameCtrl.text.trim();
  if (nickname.isEmpty) {
    _showSnackBar('昵称不能为空');
    return;
  }
  setState(() => _isSaving = true);
  try {
    await _repo.updateProfile(
      nickname: nickname,
      avatar: _currentSeed.toString(),
    );
    if (mounted) Navigator.pop(context, true);
  } catch (e) {
    if (mounted) {
      _showSnackBar(e.toString());
      setState(() => _isSaving = false);
    }
  }
}
```

---

## 任务 9：`profile_tab.dart` — 重构：接入图案头像、新增入口、刷新逻辑 `⬜ 待处理`

文件：`e:\flutter_project\client\flash_im\lib\src\app\home\views\profile_tab.dart`

### 9.1 新增 import `⬜`

```dart
import 'package:flash_auth/flash_auth.dart';
// PatternAvatar、ChangePasswordDialog、PasswordDialog 均从 flash_auth 导入
import 'edit_profile_page.dart';
```

### 9.2 将 `_buildAvatar` 替换为使用 `PatternAvatar` `⬜`

```dart
Widget _buildAvatar(UserProfile profile) {
  final seed = _resolveSeed(profile);

  if (seed == null) {
    // 自定义 URL 头像（暂不实现，保留兜底逻辑：使用首字母 fallback）
    return _buildFallbackAvatar(profile);
  }

  return Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: PatternAvatar(seed: seed, size: 80, borderRadius: 20),
  );
}

// 从 profile.avatar 解析：int? → 种子，null → 自定义 URL
int? _resolveSeed(UserProfile profile) {
  final avatar = profile.avatar.trim();
  if (avatar.isEmpty) return profile.userId;
  return int.tryParse(avatar);
}
```

### 9.3 新增「编辑资料」按钮 `⬜`

在信息卡片与退出登录之间插入（复用 `_buildActionButton` 样式）：

```dart
Widget _buildEditProfileButton(UserProfile profile) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 24),
    child: SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _navigateToEditProfile(profile),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('编辑资料'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: const Color(0xFF4F46E5),
        ),
      ),
    ),
  );
}
```

### 9.4 新增「设置密码」/「修改密码」按钮（根据 `hasPassword` 切换）`⬜`

```dart
Widget _buildPasswordButton(UserProfile profile) {
  final hasPassword = profile.hasPassword;
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 24),
    child: SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: hasPassword ? _showChangePasswordDialog : _showSetupPasswordDialog,
        icon: Icon(hasPassword ? Icons.lock_outline : Icons.lock_open_outlined, size: 18),
        label: Text(hasPassword ? '修改密码' : '设置密码'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: const Color(0xFF4F46E5),
        ),
      ),
    ),
  );
}
```

### 9.5 `_navigateToEditProfile` 方法 `⬜`

```dart
Future<void> _navigateToEditProfile(UserProfile profile) async {
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => EditProfilePage(profile: profile)),
  );
  if (result == true) {
    setState(() => _profileFuture = _repo.getProfile());
  }
}
```

### 9.6 `_showChangePasswordDialog` 方法 `⬜`

```dart
void _showChangePasswordDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const ChangePasswordDialog(),
  );
}
```

### 9.7 `_showSetupPasswordDialog` 方法 `⬜`

```dart
void _showSetupPasswordDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PasswordDialog(
      onSetupSuccess: () {
        setState(() => _profileFuture = _repo.getProfile());
      },
      onSkip: () {},
    ),
  );
}
```

### 9.8 调整 `_buildContent` 布局 `⬜`

在 `_buildInfoCard` 和 `_buildLogoutButton` 之间插入：
```dart
const SizedBox(height: 16),
_buildEditProfileButton(profile),
const SizedBox(height: 12),
_buildPasswordButton(profile),
const SizedBox(height: 12),
```

### 9.9 更新信息卡片中头像展示 `⬜`

信息卡片中的「头像」行 value 改为「对称方块图案」或直接展示 seed 值：

```dart
// 原来: value: profile.avatar
// 改为:
value: _resolveSeed(profile) != null ? '对称方块图案' : profile.avatar,
```

---

## 任务 10：`flash_auth.dart` — 导出新增文件 `⬜ 待处理`

文件：`e:\flutter_project\client\modules\flash_auth\lib\flash_auth.dart`

### 10.1 新增导出 `⬜`

```dart
export 'src/views/change_password_dialog.dart';
export 'src/widgets/pattern_avatar.dart';
```

---

## 最后：编译验证

```bash
cd e:\flutter_project\client\flash_im
flutter analyze
```

确保无编译错误和 lint 警告。
