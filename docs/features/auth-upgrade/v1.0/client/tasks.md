# 认证系统升级 — 客户端任务清单

基于 [design.md](./design.md) 设计，列出需要创建/修改的具体细节。

**全局约束**：
- 状态管理沿用 `ChangeNotifier`（`AuthViewModel`），不引入新状态库
- UI 风格参考现有 `AuthLoginPage` / `AuthProfilePage` 的微信风格
- 网络请求继续使用 `AuthService`（Dio），Bearer Token 从 SharedPreferences 读取
- 新页面路由使用 `Navigator.push` / `pushReplacement`，不引入命名路由

---

## 执行顺序

1. ⬜ 任务 1 — 更新数据模型（无依赖）
2. ⬜ 任务 2 — 更新 AuthConfig 配置（无依赖）
3. ⬜ 任务 3 — 扩展 AuthService 网络层（依赖任务 1）
4. ⬜ 任务 4 — 扩展 AuthViewModel 状态层（依赖任务 1、3）
5. ⬜ 任务 5 — 创建 PasswordSetupPage（依赖任务 4）
6. ⬜ 任务 6 — 创建 PasswordChangePage（依赖任务 4）
7. ⬜ 任务 7 — 修改 AuthLoginPage 登录跳转逻辑（依赖任务 4、5）
8. ⬜ 任务 8 — 修改 AuthProfilePage 新增修改密码入口（依赖任务 6）
9. ⬜ 任务 9 — 更新测试用例（依赖任务 1-8）
10. ⬜ 最后 — 编译验证 + 完整流程测试

---

## 任务 1：更新数据模型 `⬜ 待处理`

### 1.1 `LoginResponse` — 新增 `hasPassword` 字段 `⬜`

文件：`flash_im/lib/src/playground/features/auth/models/login_response.dart`（修改）

```dart
class LoginResponse {
  final bool success;
  final String? loginType;
  final String? token;
  final int? userId;
  final String? nickname;
  final String? avatar;
  final bool hasPassword;   // 新增
  final String? message;

  LoginResponse({
    required this.success,
    this.loginType,
    this.token,
    this.userId,
    this.nickname,
    this.avatar,
    this.hasPassword = false,  // 新增，默认 false
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      // ... 现有字段不变 ...
      hasPassword: json['has_password'] as bool? ?? false,  // 新增
    );
  }
}
```

### 1.2 `UserProfile` — 新增 `hasPassword` 字段 `⬜`

文件：`flash_im/lib/src/playground/features/auth/models/user_profile.dart`（修改）

```dart
class UserProfile {
  final int userId;
  final String nickname;
  final String avatar;
  final String phone;
  final bool hasPassword;   // 新增

  UserProfile({
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.phone,
    this.hasPassword = false,  // 新增
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      // ... 现有字段不变 ...
      hasPassword: json['has_password'] as bool? ?? false,  // 新增
    );
  }

  // toJson 中同样追加 'has_password': hasPassword
}
```

---

## 任务 2：更新 AuthConfig 配置 `⬜ 待处理`

文件：`flash_im/lib/src/playground/features/auth/config/auth_config.dart`（修改）

### 2.1 新增接口路径常量 `⬜`

```dart
class AuthConfig {
  // ... 现有常量不变 ...

  static const String passwordSetupPath = '/auth/password/setup';      // 新增
  static const String passwordChangePath = '/auth/password';           // 新增

  // 新增对应的 URL getter
  static String get passwordSetupUrl => '$baseUrl$passwordSetupPath';
  static String get passwordChangeUrl => '$baseUrl$passwordChangePath';
}
```

---

## 任务 3：扩展 AuthService 网络层 `⬜ 待处理`

文件：`flash_im/lib/src/playground/features/auth/services/auth_service.dart`（修改）

### 3.1 新增 `setupPassword()` 方法 `⬜`

```dart
Future<bool> setupPassword(String password) async {
  // 1. 调用 getToken() 获取 Bearer Token
  // 2. token 为空则 throw Exception
  // 3. _dio.post(AuthConfig.passwordSetupPath, data: {'password': password},
  //      options: Options(headers: {'Authorization': 'Bearer $token'}))
  // 4. 解析响应 data['success'] as bool
  // 5. 成功返回 true，失败 throw Exception(data['message'] ...)
}
```

### 3.2 新增 `changePassword()` 方法 `⬜`

```dart
Future<bool> changePassword(String oldPassword, String newPassword) async {
  // 1. 调用 getToken() 获取 Bearer Token
  // 2. token 为空则 throw Exception
  // 3. _dio.put(AuthConfig.passwordChangePath, data: {
  //      'old_password': oldPassword,
  //      'new_password': newPassword,
  //    }, options: Options(headers: {'Authorization': 'Bearer $token'}))
  // 4. 解析响应 data['success'] as bool
  // 5. 成功返回 true，失败 throw Exception(data['message'] ...)
  // 6. DioException 异常处理复用现有 _handleDioError 模式
}
```

---

## 任务 4：扩展 AuthViewModel 状态层 `⬜ 待处理`

文件：`flash_im/lib/src/playground/features/auth/viewmodel/auth_viewmodel.dart`（修改）

### 4.1 新增 `_lastLoginResponse` 存储最近一次登录响应 `⬜`

```dart
LoginResponse? _lastLoginResponse;   // 新增
```

登录方法（`login()` / `loginWithPassword()`）在成功时将 `response` 赋值给 `_lastLoginResponse`。

### 4.2 新增 `hasPassword` getter `⬜`

```dart
bool get hasPassword => _lastLoginResponse?.hasPassword ?? false;
```

> 用于登录页判断是否需要跳转密码设置。

### 4.3 新增 `setupPassword()` 方法 `⬜`

```dart
Future<void> setupPassword(String password) async {
  // 1. _isLoading = true, _errorMessage = null, notifyListeners()
  // 2. try { await _service.setupPassword(password); }
  // 3. catch (e) { _errorMessage = e.toString(); }
  // 4. finally { _isLoading = false; notifyListeners(); }
  // 5. 返回是否成功（调用方根据 errorMessage 判断）
}
```

### 4.4 新增 `changePassword()` 方法 `⬜`

```dart
Future<void> changePassword(String oldPassword, String newPassword) async {
  // 1. _isLoading = true, _errorMessage = null, notifyListeners()
  // 2. try { await _service.changePassword(oldPassword, newPassword); }
  // 3. catch (e) { _errorMessage = e.toString(); }
  // 4. finally { _isLoading = false; notifyListeners(); }
}
```

### 4.5 更新 `logout()` — 清理 `_lastLoginResponse` `⬜`

在现有 `logout()` 方法中追加：

```dart
_lastLoginResponse = null;
```

---

## 任务 5：创建密码设置页面 `⬜ 待处理`

文件：`flash_im/lib/src/playground/features/auth/views/password_setup_page.dart`（新建）

### 5.1 页面结构 `⬜`

```
PasswordSetupPage (StatefulWidget)
  ├── Scaffold (backgroundColor: #F8F8F8)
  │   ├── AppBar: 标题 "设置密码"
  │   └── Body: Column
  │       ├── 说明文案（Text: "为保障账号安全，请设置登录密码"）
  │       ├── 新密码输入框（obscureText: true, 带眼睛切换）
  │       ├── 确认密码输入框（obscureText: true）
  │       ├── 确认设置按钮（微信绿 #07C160，满宽圆角）
  │       └── 暂不设置（TextButton: "暂不设置"）
```

### 5.2 交互逻辑 `⬜`

- 使用自身 `AuthViewModel`（`AuthViewModel()`，复用现有 ViewModel）
- "确认设置"点击：校验两次密码一致 + 长度 ≥ 6，调用 `setupPassword()`
- 成功后 `Navigator.pushReplacement` 到 `AuthProfilePage`
- 失败显示 SnackBar（`_viewModel.errorMessage`）
- "暂不设置"点击：`Navigator.pushReplacement` 到 `AuthProfilePage`

### 5.3 UI 风格参考 `⬜`

- 输入框样式参考 `_InputField`（`auth_login_page.dart` 中的私有 Widget）
- 按钮样式参考微信绿 `Color(0xFF07C160)`

---

## 任务 6：创建密码修改页面 `⬜ 待处理`

文件：`flash_im/lib/src/playground/features/auth/views/password_change_page.dart`（新建）

### 6.1 页面结构 `⬜`

```
PasswordChangePage (StatefulWidget)
  ├── Scaffold (backgroundColor: #F8F8F8)
  │   ├── AppBar: 标题 "修改密码"
  │   └── Body: Column
  │       ├── 原密码输入框（obscureText: true）
  │       ├── 新密码输入框（obscureText: true）
  │       ├── 确认新密码输入框（obscureText: true）
  │       └── 确认修改按钮（微信绿，满宽圆角）
```

### 6.2 交互逻辑 `⬜`

- 使用自身 `AuthViewModel`
- 点击确认：校验两次新密码一致 + 长度 ≥ 6
- 调用 `changePassword(oldPassword, newPassword)`
- 成功后 `Navigator.pop()` 回退到 ProfilePage
- 失败显示 SnackBar

---

## 任务 7：修改 AuthLoginPage — 登录跳转逻辑 `⬜ 待处理`

文件：`flash_im/lib/src/playground/features/auth/views/auth_login_page.dart`（修改）

### 7.1 短信登录成功后根据 `hasPassword` 分流 `⬜`

修改 `_handleLogin()` 方法：

```dart
Future<void> _handleLogin() async {
  await _viewModel.login();
  if (mounted && _viewModel.isLoggedIn) {
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    } else if (!_viewModel.hasPassword) {
      // 未设置密码 → 引导设置密码
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PasswordSetupPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthProfilePage()),
      );
    }
  }
}
```

### 7.2 新增 `import` 语句 `⬜`

```dart
import 'password_setup_page.dart';
```

---

## 任务 8：修改 AuthProfilePage — 新增修改密码入口 `⬜ 待处理`

文件：`flash_im/lib/src/playground/features/auth/views/auth_profile_page.dart`（修改）

### 8.1 在信息卡片中新增"修改密码"行 `⬜`

在 `_buildInfoCard()` 的 `Column` children 中，现有 `_buildInfoItem` 行之后，追加：

```dart
_buildChangePasswordItem(),
```

### 8.2 新增 `_buildChangePasswordItem()` 方法 `⬜`

```dart
Widget _buildChangePasswordItem() {
  return GestureDetector(
    onTap: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PasswordChangePage()),
      );
      // 返回后刷新 profile（密码状态可能已变）
      _viewModel.loadProfile();
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      // 白色卡片 + 圆角 + 阴影，风格与 _buildLogoutButton 协调
      // 文案 "修改密码" + 右侧箭头图标
    ),
  );
}
```

### 8.3 新增 `import` 语句 `⬜`

```dart
import 'password_change_page.dart';
```

---

## 任务 9：更新测试用例 `⬜ 待处理`

### 9.1 `auth_models_test.dart` — 新增 `hasPassword` 测试 `⬜`

文件：`flash_im/test/playground/auth/auth_models_test.dart`（修改）

新增 group 或追加到现有 group：

```dart
group('LoginResponse hasPassword', () {
  test('解析 has_password: true', () { ... });
  test('解析 has_password: false', () { ... });
  test('缺少 has_password 字段时默认为 false', () { ... });
});

group('UserProfile hasPassword', () {
  test('解析 has_password: true', () { ... });
  test('解析 has_password: false', () { ... });
  test('缺少 has_password 字段时默认为 false', () { ... });
});
```

### 9.2 `auth_service_test.dart` — 新增密码设置/修改 API 测试 `⬜`

文件：`flash_im/test/playground/auth/auth_service_test.dart`（修改）

新增 group：

```dart
group('setupPassword', () {
  test('设置密码成功', () { ... });   // Mock Dio post 返回 success: true
  test('密码长度不足返回错误', () { ... });
});

group('changePassword', () {
  test('修改密码成功', () { ... });   // Mock Dio put 返回 success: true
  test('原密码错误返回错误', () { ... });
});
```

### 9.3 `auth_viewmodel_test.dart` — 新增 ViewModel 测试 `⬜`

文件：`flash_im/test/playground/auth/auth_viewmodel_test.dart`（修改）

新增 group：

```dart
group('hasPassword', () {
  test('登录后 hasPassword 为 true', () { ... });
  test('登录后 hasPassword 为 false', () { ... });
});

group('setupPassword', () {
  test('设置密码成功', () { ... });
  test('设置密码失败显示错误', () { ... });
});

group('changePassword', () {
  test('修改密码成功', () { ... });
  test('修改密码失败显示错误', () { ... });
});
```

---

## 最后 — 验证 `⬜ 待处理`

- ⬜ `flutter analyze` 无编译错误
- ⬜ `flutter test` 全部通过
- ⬜ App 启动 → 短信登录 → 新用户提示设置密码 → 设置密码 → 跳转个人中心
- ⬜ 个人中心 → 修改密码 → 输入旧/新密码 → 修改成功返回
- ⬜ 修改密码后退出 → 用新密码登录成功
- ⬜ 已有密码用户短信登录 → `hasPassword:true` → 直接进入个人中心
