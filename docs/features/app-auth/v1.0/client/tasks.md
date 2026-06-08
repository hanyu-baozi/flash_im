---
module: app-auth
version: v1.0
date: 2026-05-26
inclusion: manual
---

# 登录认证 + 主框架 — 客户端任务清单

基于 design.md，将认证模块拆解为可逐条执行的任务。

**全局约束**：
- **不使用状态管理框架**。LoginPage 的 UI 状态使用 `mixin` + 模式子类（`_SmsMode` / `_PasswordMode`）分离，`setState` 驱动 UI 更新
- Playground 代码（`lib/src/playground/`）**不动**，仅从中迁移模型到 `app/auth/data/models/`
- 所有新建文件位于 `lib/src/app/` 下，与 playground 平级
- `main_playground.dart` **不动**，仅修改 `main.dart`
- UI 风格参考 Playground 的 `AuthLoginPage`（简约白底 + 渐变色 Logo + 圆角输入框）和 `AuthProfilePage`（渐变色头像 + 信息卡片 + 红色退出按钮）
- 复用 Playground 的接口路径常量（`/auth/sms`、`/auth/login`、`/auth/login/password`、`/auth/password/setup`、`/user/profile`）
- SharedPreferences key 使用 `auth_token` / `auth_user_id`（与 Playground `AuthService` 和 Splash `SplashService` 保持一致）
- Token 读取/写入/清除不直接操作 SharedPreferences，统一通过 `AuthRepository`
- LoginPage 的登录业务逻辑定义在 `LoginLogic` mixin 中，`_LoginPageState` 只负责 UI 构建

---

## 执行顺序

1. ⬜ 任务 1 — [api_config.dart] 新建共享 API 配置（无依赖）
2. ⬜ 任务 2 — [login_response.dart + login_type.dart] 迁移登录响应模型（无依赖）
3. ⬜ 任务 3 — [user_profile.dart] 迁移用户信息模型（无依赖）
4. ⬜ 任务 4 — [auth_api_service.dart] 新建 API 请求封装（依赖任务 1、2、3）
5. ⬜ 任务 5 — [auth_repository.dart] 新建仓库层（依赖任务 2、3、4）
6. ⬜ 任务 6 — [messages_tab.dart + contacts_tab.dart] 新建留白占位 Tab（无依赖）
7. ⬜ 任务 7 — [login_page.dart] 实现登录页（mixin + 模式子类）（依赖任务 5）
8. ⬜ 任务 8 — [password_dialog.dart] 新建密码设置弹窗（依赖任务 5）
9. ⬜ 任务 9 — [profile_tab.dart] 实现我的 Tab（依赖任务 5）
10. ⬜ 任务 10 — [main_page.dart] 实现底部三 Tab 主框架（依赖任务 6、9）
11. ⬜ 任务 11 — [main.dart] 更新路由引用（依赖任务 10）
12. ⬜ 最后 — 编译验证 + flutter analyze（依赖任务 1-11）

---

## 任务 1：[api_config.dart] — 新建共享 API 配置 `⬜ 待处理`

文件：`flash_im/lib/src/app/shared/config/api_config.dart`（新建）

### 1.1 定义 API 配置常量 `⬜`

```dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:3000';

  static const String smsPath = '/auth/sms';
  static const String loginPath = '/auth/login';
  static const String passwordLoginPath = '/auth/login/password';
  static const String passwordSetupPath = '/auth/password/setup';
  static const String profilePath = '/user/profile';

  static const int connectTimeout = 10000;
  static const int countdownSeconds = 60;

  static String get smsUrl => '$baseUrl$smsPath';
  static String get loginUrl => '$baseUrl$loginPath';
  static String get passwordLoginUrl => '$baseUrl$passwordLoginPath';
  static String get passwordSetupUrl => '$baseUrl$passwordSetupPath';
  static String get profileUrl => '$baseUrl$profilePath';
}
```

> **说明**：从 Playground 的 `PlaygroundConfig` + `AuthConfig` 整合而来，作为正式 App 的全局 API 配置。端口 3000，Android 模拟器使用 `10.0.2.2` 访问宿主机。

---

## 任务 2：[login_response.dart + login_type.dart] — 迁移登录响应模型 `⬜ 待处理`

### 2.1 [login_response.dart] 迁移 `⬜`

文件：`flash_im/lib/src/app/auth/data/models/login_response.dart`（新建）

从 Playground `lib/src/playground/features/auth/models/login_response.dart` 复制代码，**保持不变**，仅调整 import 路径：

```dart
import 'login_type.dart';

class LoginResponse {
  final bool success;
  final String? loginType;
  final String? token;
  final int? userId;
  final String? nickname;
  final String? avatar;
  final String? message;

  LoginResponse({
    required this.success,
    this.loginType,
    this.token,
    this.userId,
    this.nickname,
    this.avatar,
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
      message: json['message'] as String?,
    );
  }
}
```

### 2.2 [login_type.dart] 迁移 `⬜`

文件：`flash_im/lib/src/app/auth/data/models/login_type.dart`（新建）

从 Playground `lib/src/playground/features/auth/models/login_type.dart` 复制代码：

```dart
class LoginType {
  static const String sms = 'sms';
  static const String password = 'password';

  static bool isValid(String value) => value == sms || value == password;
}
```

> **说明**：两个文件为纯数据模型，无 ChangeNotifier 依赖，直接复制即可。后续业务代码通过新路径引用。

---

## 任务 3：[user_profile.dart] — 迁移用户信息模型 `⬜ 待处理`

文件：`flash_im/lib/src/app/auth/data/models/user_profile.dart`（新建）

### 3.1 迁移 UserProfile `⬜`

从 Playground `lib/src/playground/features/auth/models/user_profile.dart` 复制代码，**保持纯数据类，不继承 ChangeNotifier**：

```dart
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
      userId: json['user_id'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
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
}
```

---

## 任务 4：[auth_api_service.dart] — 新建 API 请求封装 `⬜ 待处理`

文件：`flash_im/lib/src/app/auth/data/services/auth_api_service.dart`（新建）

### 4.1 定义 ApiService 骨架 `⬜`

```dart
import 'package:dio/dio.dart';
import '../../../shared/config/api_config.dart';
import '../models/login_response.dart';
import '../models/user_profile.dart';

class AuthApiService {
  final Dio _dio;

  AuthApiService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
          receiveTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
        ));
```

### 4.2 实现 sendSms `⬜`

```dart
  Future<String?> sendSms(String phone) async {
    // 1. POST ApiConfig.smsPath, data: {'phone': phone}
    // 2. 状态码 200 + data['success'] == true → 返回 data['code'] as String?
    // 3. 失败抛 Exception(data['message'] ?? '发送验证码失败')
    // 4. DioException → throw _handleDioError(e)
    // 5. 其他异常 → throw Exception('发送验证码失败: $e')
  }
```

> 参考 Playground `AuthService.sendSmsCode()` 实现逻辑。

### 4.3 实现 login `⬜`

```dart
  Future<LoginResponse> login(String phone, String code) async {
    // 1. POST ApiConfig.loginPath, data: {'phone': phone, 'code': code}
    // 2. 状态码 200 → LoginResponse.fromJson(response.data)
    // 3. 失败抛 Exception('登录失败: ${response.statusCode}')
    // 4. DioException → throw _handleDioError(e)
  }
```

> 注意：ApiService 层**不保存 Token**，只负责网络请求。Token 持久化在 Repository 层。

### 4.4 实现 loginWithPassword `⬜`

```dart
  Future<LoginResponse> loginWithPassword(String phone, String password) async {
    // 1. POST ApiConfig.passwordLoginPath, data: {'phone': phone, 'password': password}
    // 2. 状态码 200 → LoginResponse.fromJson(response.data)
    // 3. 失败抛 Exception('密码登录失败: ${response.statusCode}')
    // 4. DioException → throw _handleDioError(e)
  }
```

### 4.5 实现 getProfile `⬜`

```dart
  Future<UserProfile> getProfile(String token) async {
    // 1. GET ApiConfig.profilePath, headers: {'Authorization': 'Bearer $token'}
    // 2. 状态码 200 + data['success'] == true → UserProfile.fromJson(response.data)
    // 3. 401 → throw Exception('Token 已过期，请重新登录')
    // 4. 其他失败 → throw Exception(data['message'] ?? '获取用户信息失败')
    // 5. DioException → throw _handleDioError(e)
  }
```

> ApiService 的 `getProfile` 接收 token 参数由 Repository 传入，自身不持有 token。

### 4.6 实现 setupPassword `⬜`

```dart
  Future<void> setupPassword(String password, String token) async {
    // 1. POST ApiConfig.passwordSetupPath, data: {'password': password}, headers: {'Authorization': 'Bearer $token'}
    // 2. 状态码 200 + data['success'] == true → 返回成功
    // 3. 失败抛 Exception(data['message'] ?? '设置密码失败')
    // 4. DioException → throw _handleDioError(e)
  }
```

### 4.7 实现 _handleDioError `⬜`

```dart
  String _handleDioError(DioException e) {
    // 参考 Playground AuthService._handleDioError() 逻辑
    // switch e.type: connectionTimeout → '连接超时', receiveTimeout → '响应超时', connectionError → '网络连接失败', default → '请求失败: ${e.message}'
  }
```

---

## 任务 5：[auth_repository.dart] — 新建仓库层 `⬜ 待处理`

文件：`flash_im/lib/src/app/auth/data/repositories/auth_repository.dart`（新建）

### 5.1 定义 Repository 骨架 `⬜`

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_response.dart';
import '../models/user_profile.dart';
import '../services/auth_api_service.dart';

class AuthRepository {
  final AuthApiService _apiService;
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'auth_user_id';

  AuthRepository({AuthApiService? apiService})
      : _apiService = apiService ?? AuthApiService();
```

### 5.2 实现 Token 管理方法 `⬜`

```dart
  Future<String?> getToken() async {
    // 1. SharedPreferences.getInstance()
    // 2. prefs.getString(_tokenKey)
  }

  Future<bool> isLoggedIn() async {
    // 1. 获取 token
    // 2. 返回 token != null && token.isNotEmpty
  }

  Future<void> saveToken(String token, int? userId) async {
    // 1. SharedPreferences.getInstance()
    // 2. prefs.setString(_tokenKey, token)
    // 3. if userId != null → prefs.setInt(_userIdKey, userId)
  }

  Future<void> clearToken() async {
    // 1. SharedPreferences.getInstance()
    // 2. prefs.remove(_tokenKey)
    // 3. prefs.remove(_userIdKey)
  }
```

### 5.3 实现业务编排方法 `⬜`

```dart
  Future<String?> sendSms(String phone) async {
    return _apiService.sendSms(phone);
  }

  Future<LoginResponse> login(String phone, String code) async {
    // 1. 调用 _apiService.login(phone, code)
    // 2. 如果 loginResp.success && loginResp.token != null → saveToken(loginResp.token!, loginResp.userId)
    // 3. 返回 loginResp
  }

  Future<LoginResponse> loginWithPassword(String phone, String password) async {
    // 1. 调用 _apiService.loginWithPassword(phone, password)
    // 2. 如果 loginResp.success && loginResp.token != null → saveToken(loginResp.token!, loginResp.userId)
    // 3. 返回 loginResp
  }

  Future<UserProfile> getProfile() async {
    // 1. 获取 token → getToken()
    // 2. if token == null → throw Exception('未登录')
    // 3. 调用 _apiService.getProfile(token)
    // 4. 401 异常由 ApiService 抛出，Repository 透传
  }

  Future<void> setupPassword(String password) async {
    // 1. 获取 token → getToken()
    // 2. if token == null → throw Exception('未登录')
    // 3. 调用 _apiService.setupPassword(password, token)
  }
```

> **关键**：Repository 是唯一直接操作 SharedPreferences 的层，View 和 Mixin 不接触 SharedPreferences。

---

## 任务 6：[messages_tab.dart + contacts_tab.dart] — 新建留白占位 Tab `⬜ 待处理`

### 6.1 [messages_tab.dart] 消息 Tab 占位 `⬜`

文件：`flash_im/lib/src/app/home/views/messages_tab.dart`（新建）

```dart
import 'package:flutter/material.dart';

class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '消息（敬请期待）',
        style: TextStyle(fontSize: 15, color: Color(0xFF999999)),
      ),
    );
  }
}
```

### 6.2 [contacts_tab.dart] 通讯录 Tab 占位 `⬜`

文件：`flash_im/lib/src/app/home/views/contacts_tab.dart`（新建）

```dart
import 'package:flutter/material.dart';

class ContactsTab extends StatelessWidget {
  const ContactsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '通讯录（敬请期待）',
        style: TextStyle(fontSize: 15, color: Color(0xFF999999)),
      ),
    );
  }
}
```

---

## 任务 7：[login_page.dart] — 实现登录页（mixin + 模式子类）`⬜ 待处理`

文件：`flash_im/lib/src/app/auth/views/login_page.dart`（修改，替换 Splash 占位内容）

> **核心设计**：`_SmsMode` / `_PasswordMode` 是两个自包含的内部类，各自持有自己的输入控制器、校验逻辑和 API 调用。`LoginLogic` mixin 是薄转发层，持有唯一的共享数据（`phoneCtrl`、`_isLoading`、`_error`），把操作委托给当前激活的模式。`_LoginPageState` 只写 UI。

### 7.1 _SmsMode 内部类 `⬜`

```dart
class _SmsMode {
  final codeCtrl = TextEditingController();
  String? displayCode;
  int countdown = 0;
  Timer? timer;

  bool canLogin(String phone) =>
      phone.length == 11 && codeCtrl.text.length >= 4;

  Future<String?> sendCode(String phone, AuthRepository repo) async {
    // 1. code = await repo.sendSms(phone)
    // 2. displayCode = code
    // 3. 启动倒计时 timer（Timer.periodic(1s) 递减 countdown，到 0 取消）
    // 4. 返回 code
  }

  Future<LoginResponse> login(String phone, AuthRepository repo) async {
    return repo.login(phone, codeCtrl.text);
  }

  void dispose() { codeCtrl.dispose(); timer?.cancel(); }

  void _startCountdown(void Function() onTick) {
    // countdown = 60
    // timer = Timer.periodic(1s, (t) { countdown--; onTick(); if countdown == 0 { t.cancel(); } })
  }
}
```

### 7.2 _PasswordMode 内部类 `⬜`

```dart
class _PasswordMode {
  final pwdCtrl = TextEditingController();

  bool canLogin(String phone) =>
      phone.length == 11 && pwdCtrl.text.length >= 6;

  Future<LoginResponse> login(String phone, AuthRepository repo) async {
    return repo.loginWithPassword(phone, pwdCtrl.text);
  }

  void dispose() { pwdCtrl.dispose(); }
}
```

### 7.3 LoginLogic mixin `⬜`

```dart
mixin LoginLogic on State<LoginPage> {
  final phoneCtrl = TextEditingController();
  final _repo = AuthRepository();

  var _isLoading = false;
  String? _error;
  var _isPasswordMode = false;

  final _sms = _SmsMode();
  final _pwd = _PasswordMode();

  // 当前模式
  _LoginMode get _current => _isPasswordMode ? _pwd : _sms;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPasswordMode => _isPasswordMode;

  // 验证码模式的快捷属性（密码模式下返回 default 值）
  String? get displayCode => _isPasswordMode ? null : _sms.displayCode;
  int get countdown => _isPasswordMode ? 0 : _sms.countdown;
  bool get canSendCode =>
      !_isPasswordMode && _sms.countdown == 0 && phoneCtrl.text.length == 11;

  // View 需要的输入框控制器——模式切换后自动换成新模式的控制器
  TextEditingController get inputCtrl =>
      _isPasswordMode ? _pwd.pwdCtrl : _sms.codeCtrl;

  // 模式切换后用新模式的 canLogin
  bool get canLogin => _current.canLogin(phoneCtrl.text);

  // ── 操作 ──
  void toggleMode() =>
      setState(() { _isPasswordMode = !_isPasswordMode; _error = null; });

  void clearError() => setState(() => _error = null);

  Future<void> sendCode() async {
    // 1. if isPasswordMode → return（密码模式不需要）
    // 2. setState(() => _isLoading = true)
    // 3. try: await _sms.sendCode(phoneCtrl.text, _repo) + setState(() => _isLoading = false)
    // 4. 倒计时每 tick 调 setState
    // 5. catch (e): setState(() { _error = e.toString(); _isLoading = false; })
  }

  Future<bool> login() async {
    // 1. setState(() { _isLoading = true; _error = null; })
    // 2. try:
    //    a. resp = await _current.login(phoneCtrl.text, _repo)
    //    b. if !resp.success → setState(() { _error = resp.message ?? '登录失败'; }) return false
    // 3. catch (e): setState(() { _error = e.toString(); }) return false
    // 4. setState(() => _isLoading = false)
    // 5. return true
  }

  void disposeAll() {
    phoneCtrl.dispose();
    _sms.dispose();
    _pwd.dispose();
  }
}
```

### 7.4 _LoginPageState `⬜`

```dart
class _LoginPageState extends State<LoginPage> with LoginLogic {
  @override
  void initState() {
    super.initState();
    phoneCtrl.addListener(() => setState(() {}));
    // inputCtrl 也需监听以触发 canLogin 重新计算
    // 每次 toggleMode 后重新监听新 inputCtrl
    _watchInputCtrl();
  }

  void _watchInputCtrl() {
    inputCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Stack(
          children: [
            _buildBody(),
            if (isLoading)
              Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
```

### 7.5 _buildBody `⬜`

参考 Playground `AuthLoginPage._buildBody()` 布局：

```dart
  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 48),
            _buildPhoneInput(),
            const SizedBox(height: 16),
            isPasswordMode ? _buildPasswordInput() : _buildCodeInput(),
            const SizedBox(height: 12),
            if (!isPasswordMode && displayCode != null) _buildCodeHint(),
            const SizedBox(height: 32),
            _buildLoginButton(),
            const SizedBox(height: 24),
            _buildModeSwitch(),
            if (error != null) ...[
              const SizedBox(height: 16),
              _buildErrorHint(),
            ],
          ],
        ),
      ),
    );
  }
```

### 7.6 _buildHeader `⬜`

参考 Playground `AuthLoginPage._buildHeader()`：
- 渐变色 Logo 图标（`LinearGradient` `4F46E5 → 7C3AED`，图标 `Icons.shield_outlined`）
- 「欢迎登录」标题（字号 28，字重 700）
- 副标题根据模式切换：「使用手机号和验证码登录」/「使用手机号和密码登录」

### 7.7 _buildPhoneInput `⬜`

参考 Playground `_InputField` 组件：
- 白色背景，圆角 12，shadow
- 手机号图标前缀
- maxLength: 11，keyboardType: phone
- counterText 隐藏
- controller: `phoneCtrl`（来自 mixin）

### 7.8 _buildCodeInput + _buildSendCodeBtn `⬜`

验证码输入框参考 Playground `_buildCodeInput()`：
- controller: `inputCtrl`（mixin 属性，模式切换自动换）
- 右侧 suffix：`canSendCode` 时「获取验证码」紫色，否则显示倒计时灰色
- 点击调用 `sendCode()`（mixin 方法）

### 7.9 _buildPasswordInput `⬜`

密码模式输入框：
- controller: `inputCtrl`（mixin 属性）
- 图标：`Icons.lock_outline`
- `obscureText: true`，suffix 切换显示/隐藏

### 7.10 _buildCodeHint `⬜`

参考 Playground `_buildCodeHint()` 绿色提示条：
- 绿色背景 `0xFFF0FDF4`，边框 `0xFFBBF7D0`
- 文案：「测试验证码: $displayCode」

### 7.11 _buildLoginButton `⬜`

参考 Playground `_buildLoginButton()`：
- 启用条件：`canLogin`（mixin 属性，自动判断验证码/密码模式）
- 启用时紫色 `4F46E5`，禁用时灰色 `E5E7EB`
- 文字「登 录」，字间距 2
- 点击 `_handleLogin()`

### 7.12 _handleLogin `⬜`

```dart
  Future<void> _handleLogin() async {
    final success = await login();  // mixin 方法
    if (!mounted || !success) return;
    // 登录成功 → 检查 hasPassword → 弹窗或直接跳转
    // hasPassword 的检测方式：
    //   - 密码登录 → hasPassword 默认为 true
    //   - 验证码登录 → 调用 _repo.getProfile() 检查是否已设置密码
    //     （如果后端 /user/profile 返回 has_password 字段则直接用，否则默认为 false 触发弹窗）
    _onLoginSuccess();
  }

  void _onLoginSuccess() {
    // 根据 hasPassword 决定是否弹出设置弹窗
    // 最终 Navigator.pushReplacement → MainPage
  }
```

### 7.13 _buildModeSwitch `⬜`

```dart
  Widget _buildModeSwitch() {
    return Center(
      child: GestureDetector(
        onTap: () {
          toggleMode();  // mixin 方法
          _watchInputCtrl();  // 重新监听新模式的 inputCtrl
        },
        child: Text(
          isPasswordMode ? '验证码登录' : '密码登录',
          style: const TextStyle(
            fontSize: 14, color: Color(0xFF4F46E5),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
```

### 7.14 _buildErrorHint `⬜`

参考 Playground `_buildErrorHint()` 红色错误提示条：
- 红色背景 `0xFFFEF2F2`，边框 `0xFFFECACA`
- 文案：`error`（mixin 属性）
- 右侧关闭按钮调用 `clearError()`（mixin 方法）

---

## 任务 8：[password_dialog.dart] — 新建密码设置弹窗 `⬜ 待处理`

文件：`flash_im/lib/src/app/auth/views/password_dialog.dart`（新建）

### 8.1 定义 PasswordDialog 骨架 `⬜`

```dart
import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';

class PasswordDialog extends StatefulWidget {
  final VoidCallback onSetupSuccess;
  final VoidCallback onSkip;

  const PasswordDialog({
    super.key,
    required this.onSetupSuccess,
    required this.onSkip,
  });

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _repo = AuthRepository();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
```

### 8.2 build 方法 `⬜`

```dart
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置密码'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 密码输入框（obscureText + suffixIcon 切换可见性）
          const SizedBox(height: 12),
          // 确认密码输入框（obscureText + suffixIcon 切换可见性）
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () { Navigator.of(context).pop(); widget.onSkip(); },
          child: const Text('暂不设置'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSetup,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('确认'),
        ),
      ],
    );
  }
```

### 8.3 _handleSetup 逻辑 `⬜`

```dart
  Future<void> _handleSetup() async {
    // 1. 校验两次密码一致，不一致 → show SnackBar，return
    // 2. 校验密码长度 >= 6，否则 → show SnackBar，return
    // 3. setState(() => _isLoading = true)
    // 4. try: await _repo.setupPassword(_passwordController.text)
    // 5. 成功 → Navigator.pop → widget.onSetupSuccess()
    // 6. catch (e): show SnackBar(e.toString()), setState(() => _isLoading = false)
  }
```

### 8.4 dispose `⬜`

```dart
  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
```

> **非功能性要求**：
> - `barrierDismissible: false`（不可点遮罩关闭，由 LoginPage 的 `showDialog` 中设置）
> - 两个密码输入框都带 `obscureText` 切换图标

---

## 任务 9：[profile_tab.dart] — 实现我的 Tab `⬜ 待处理`

文件：`flash_im/lib/src/app/home/views/profile_tab.dart`（新建）

### 9.1 页面骨架 `⬜`

ProfileTab 使用 `FutureBuilder` 加载用户信息，不依赖任何状态管理框架：

```dart
import 'package:flutter/material.dart';
import '../../auth/data/models/user_profile.dart';
import '../../auth/data/repositories/auth_repository.dart';
import '../../auth/views/login_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _repo = AuthRepository();
  late final Future<UserProfile> _profileFuture;

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
```

### 9.2 _buildContent 布局 `⬜`

参考 Playground `AuthProfilePage._buildContent()` 布局，**移除 AppBar 和返回按钮**（在 Tab 中不需要导航）：

```dart
  Widget _buildContent(UserProfile profile) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildAvatar(profile),
            const SizedBox(height: 16),
            _buildNickname(profile),
            const SizedBox(height: 32),
            _buildInfoCard(profile),
            const SizedBox(height: 32),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }
```

### 9.3 _buildAvatar `⬜`

参考 Playground `AuthProfilePage._buildAvatar()`：
- 80x80，圆角 20
- 渐变色底（`4F46E5 → 7C3AED`）+ boxShadow
- 有头像 URL → Image.network（fit: cover），errorBuilder → fallback
- 无头像 URL → fallback：首字母大写居中显示

### 9.4 _buildNickname `⬜`

参考 Playground `AuthProfilePage._buildNickname()`：
- 昵称（字号 22，字重 700）
- 下方：「ID: ${profile.userId}」（字号 13，灰色 `#999999`）

### 9.5 _buildInfoCard `⬜`

参考 Playground `AuthProfilePage._buildInfoCard()`：
- 白色卡片，圆角 16，shadow
- 三项信息：手机号（phone_outline）、昵称（badge_outline）、头像链接（link_outline）
- 每项之间 Divider（indent: 52）

### 9.6 _buildLogoutButton `⬜`

参考 Playground `AuthProfilePage._buildLogoutButton()`：
- OutlinedButton，红色边框 `EF4444`
- 文字「退出登录」，红色，字重 600

### 9.7 _handleLogout `⬜`

```dart
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
            child: const Text('确认退出', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }
```

### 9.8 _buildErrorView `⬜`

```dart
  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFF999999)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF999999))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() => _profileFuture = _repo.getProfile());
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
```

---

## 任务 10：[main_page.dart] — 实现底部三 Tab 主框架 `⬜ 待处理`

文件：`flash_im/lib/src/app/home/views/main_page.dart`（修改，替换 Splash 占位内容）

### 10.1 页面骨架 `⬜`

```dart
import 'package:flutter/material.dart';
import 'messages_tab.dart';
import 'contacts_tab.dart';
import 'profile_tab.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    MessagesTab(),
    ContactsTab(),
    ProfileTab(),
  ];
```

### 10.2 build 方法 `⬜`

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF4F46E5),
        unselectedItemColor: const Color(0xFF999999),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: '消息',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts_outlined),
            activeIcon: Icon(Icons.contacts),
            label: '通讯录',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
```

> **设计要点**：
> - `IndexedStack` 保持各 Tab 的 State，切换不重建 ProfileTab
> - 选中态图标填充色变（`chat_bubble` / `contacts` / `person`）
> - 选中色 `4F46E5`

---

## 任务 11：[main.dart] — 更新路由引用 `⬜ 待处理`

文件：`flash_im/lib/main.dart`（修改）

### 11.1 确认 main.dart 形态 `⬜`

> **前置条件**：Splash 模块的任务 8（main.dart 重写）已完成。

本任务**无需额外修改** main.dart——不引入 `flutter_bloc`、不注入 `BlocProvider`。Splash 模块任务 8 完成后的 main.dart 即为最终形态：

```dart
import 'package:flutter/material.dart';
import 'src/app/splash/views/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlashImApp());
}

class FlashImApp extends StatelessWidget {
  const FlashImApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flash IM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}
```

### 11.2 确认路由引用一致 `⬜`

检查 Splash 模块的路由跳转路径与本模块文件路径一致：

- SplashPage → 已登录跳转 `MainPage`
  - import: `src/app/home/views/main_page.dart`
  - 类名: `MainPage`
- SplashPage → 未登录跳转 `LoginPage`
  - import: `src/app/auth/views/login_page.dart`
  - 类名: `LoginPage`

---

## 任务 12：编译验证 + 测试路径 `⬜ 待处理`

### 12.1 flutter analyze `⬜`

```bash
cd flash_im
flutter analyze
```

确保零 error、零 warning。

### 12.2 目录结构最终确认 `⬜`

```
flash_im/
├── lib/
│   ├── main.dart                                          # Splash 任务 8 完成后不变
│   ├── main_playground.dart                               # 不动
│   └── src/
│       ├── app/
│       │   ├── splash/                                    # Splash 模块（已完成）
│       │   ├── auth/                                      # [新增] 认证模块
│       │   │   ├── data/
│       │   │   │   ├── models/
│       │   │   │   │   ├── login_response.dart
│       │   │   │   │   ├── login_type.dart
│       │   │   │   │   └── user_profile.dart
│       │   │   │   ├── repositories/
│       │   │   │   │   └── auth_repository.dart
│       │   │   │   └── services/
│       │   │   │       └── auth_api_service.dart
│       │   │   └── views/
│       │   │       ├── login_page.dart                    # 替换 Splash 占位（mixin 方案）
│       │   │       └── password_dialog.dart               # 无状态管理框架
│       │   ├── home/
│       │   │   └── views/
│       │   │       ├── main_page.dart                     # 替换 Splash 占位
│       │   │       ├── messages_tab.dart
│       │   │       ├── contacts_tab.dart
│       │   │       └── profile_tab.dart                   # FutureBuilder
│       │   └── shared/
│       │       └── config/
│       │           └── api_config.dart
│       └── playground/                                    # 不动
├── pubspec.yaml                                           # 无需新增依赖
└── docs/
    └── features/app-auth/
        ├── README.md
        ├── roadmap.md
        └── v1.0/client/
            ├── design.md
            └── tasks.md
```

### 12.3 测试路径 `⬜`

按以下路径手动验证功能完整性：

1. **新用户注册 + 验证码登录**：
   - 启动 App → 看到启动页 → 跳转 LoginPage
   - 输入手机号 → 点击「获取验证码」→ 显示绿色提示条（测试验证码） + 按钮倒计时
   - 输入验证码 → 点击「登录」→ 弹出密码设置弹窗
   - 设置密码 / 暂不设置 → 进入 MainPage（底部三 Tab）

2. **模式切换**：
   - 验证码模式下点击「密码登录」→ 输入框切换为密码输入框
   - 再点击「验证码登录」→ 恢复验证码输入框（倒计时如未结束则继续）
   - 切换过程手机号不丢失

3. **密码登录**：
   - 退出登录 → 回到 LoginPage
   - 点击「密码登录」→ 输入手机号 + 密码 → 登录 → 进入 MainPage

4. **启动保持登录态**：
   - 已登录状态下杀掉 App → 重新打开
   - 启动页跳过 LoginPage，直接进入 MainPage
   - ProfileTab 正确展示用户信息（FutureBuilder 加载成功）

5. **退出登录 + 重新登录**：
   - ProfileTab → 点击「退出登录」→ 确认 → 回到 LoginPage
   - Token 清除（重新加载 App 应进入 LoginPage）
   - 可重新登录进入 MainPage

---