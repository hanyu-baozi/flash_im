# 启动页 — 客户端任务清单

基于 design.md，将启动模块拆解为可逐条执行的任务。

**全局约束**：
- 状态管理使用 `ChangeNotifier`（与项目现有 Auth / Heartbeat 模块一致）
- View 层使用 `AnimatedBuilder` 监听 ViewModel（与 `auth_profile_page.dart` 风格一致）
- 所有文件位于 `lib/src/app/splash/`，正式 App 代码不入 playground
- Playground 代码（`lib/src/playground/`）**不动**
- `main_playground.dart` **不动**，仅修改 `main.dart`
- Logo 由用户提供，路径 `assets/images/logo.png`

---

## 执行顺序

1. ⬜ 任务 1 — 创建 assets 目录 & 配置 pubspec.yaml（无依赖）
2. ⬜ 任务 2 — [splash_config.dart] 新建启动配置（无依赖）
3. ⬜ 任务 3 — [splash_state.dart] 新建状态模型（无依赖）
4. ⬜ 任务 4 — [splash_service.dart] 新建本地缓存服务（依赖任务 3）
5. ⬜ 任务 5 — [splash_viewmodel.dart] 新建启动状态管理（依赖任务 3、4）
6. ⬜ 任务 6 — [splash_page.dart] 新建启动页 UI（依赖任务 2、3、5）
7. ⬜ 任务 7 — [login_page.dart + main_page.dart] 新建占位页面（依赖任务 5）
8. ⬜ 任务 8 — [main.dart] 重写为正式 App 入口（依赖任务 6、7）
9. ⬜ 任务 9 — 编译验证 + flutter analyze（依赖任务 1-8）

---

## 任务 1：assets 配置 `⬜ 待处理`

文件：`flash_im/pubspec.yaml`（修改）  
文件：`flash_im/assets/images/`（新建目录）

### 1.1 创建 assets 目录 `⬜`

```
flash_im/assets/
└── images/
    └── .gitkeep              # 占位，Logo 由用户后续放入
```

### 1.2 修改 pubspec.yaml，注册 assets `⬜`

在 `flutter:` 节点下，取消注释并修改 assets 配置：

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/images/

  # fonts 配置保持不变（如有）
```

> 注意：`uses-material-design: true` 不要动。如果 fonts 节点已存在，保留原样，仅新增 assets 节点。

---

## 任务 2：[splash_config.dart] — 新建启动配置 `⬜ 待处理`

文件：`flash_im/lib/src/app/splash/config/splash_config.dart`（新建）

### 2.1 定义配置常量 `⬜`

```dart
class SplashConfig {
  /// 启动页最短展示时长（毫秒）
  static const int minDisplayMs = 1500;

  /// Logo 资源路径
  static const String logoPath = 'assets/images/logo.png';

  /// 应用名称
  static const String appName = 'Flash IM';

  /// Logo 入场动画时长（毫秒）
  static const int logoAnimMs = 800;

  /// 文字入场动画时长（毫秒）
  static const int textAnimMs = 600;
}
```

---

## 任务 3：[splash_state.dart] — 新建状态模型 `⬜ 待处理`

文件：`flash_im/lib/src/app/splash/models/splash_state.dart`（新建）

### 3.1 定义启动阶段枚举 `⬜`

```dart
enum SplashPhase {
  initializing,   // 初始化中
  ready,          // 加载完成，准备跳转
  error,          // 加载失败
}
```

### 3.2 定义路由目标枚举 `⬜`

```dart
enum SplashRouteTarget {
  login,          // 跳转登录页
  home,           // 跳转主页
}
```

### 3.3 定义加载结果类 `⬜`

```dart
class SplashLoadResult {
  final bool isLoggedIn;
  final int? userId;
  final String? errorMessage;

  const SplashLoadResult({
    required this.isLoggedIn,
    this.userId,
    this.errorMessage,
  });

  /// 据此确定路由目标
  SplashRouteTarget get routeTarget =>
      isLoggedIn ? SplashRouteTarget.home : SplashRouteTarget.login;
}
```

> `routeTarget` 是计算属性，ViewModel 中直接用它做路由分发。

---

## 任务 4：[splash_service.dart] — 新建本地缓存服务 `⬜ 待处理`

文件：`flash_im/lib/src/app/splash/services/splash_service.dart`（新建）

### 4.1 实现缓存读取方法 `⬜`

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/splash_state.dart';

class SplashService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'auth_user_id';

  /// 加载本地认证数据，返回加载结果
  Future<SplashLoadResult> loadAuthData() async {
    // 1. 获取 SharedPreferences 实例
    // 2. 读取 _tokenKey，得到 token (String?)
    // 3. 读取 _userIdKey，得到 userId (int?)
    // 4. 判断 isLoggedIn: token != null && token.isNotEmpty
    // 5. 返回 SplashLoadResult(isLoggedIn, userId, null)
  }
}
```

**逻辑要点**：
- key 常量与 `AuthService` 中保持一致（`auth_token` / `auth_user_id`），确保读写同一份数据
- 异常处理：若 SharedPreferences 读取异常，返回 `isLoggedIn: false` 并设置 errorMessage
- 不做网络请求，只读本地缓存

---

## 任务 5：[splash_viewmodel.dart] — 新建启动状态管理 `⬜ 待处理`

文件：`flash_im/lib/src/app/splash/viewmodel/splash_viewmodel.dart`（新建）

### 5.1 定义 ViewModel 骨架 `⬜`

```dart
import 'package:flutter/foundation.dart';
import '../config/splash_config.dart';
import '../models/splash_state.dart';
import '../services/splash_service.dart';

class SplashViewModel extends ChangeNotifier {
  final SplashService _service;

  SplashViewModel({SplashService? service})
      : _service = service ?? SplashService();

  SplashPhase _phase = SplashPhase.initializing;
  String? _errorMessage;

  // getters: phase, errorMessage
}
```

### 5.2 实现 initLoad() `⬜`

```dart
  Future<void> initLoad() async {
    // 1. 启动两个并行 Future：
    //    a. Future.delayed(SplashConfig.minDisplayMs) — 最短展示
    //    b. _service.loadAuthData() — 读缓存
    // 2. 使用 Future.wait 等待二者都完成
    // 3. 取 loadAuthData() 的结果
    // 4. 判断结果：
    //    a. 成功 → _phase = ready，保存 _routeTarget
    //    b. 失败 → _phase = error，保存 _errorMessage
    // 5. notifyListeners()
  }
```

**关键点**：`Future.wait` 等待展示时间 + 缓存加载都完成后才推进，确保品牌曝光足够。

### 5.3 实现 retry() `⬜`

```dart
  Future<void> retry() async {
    // 1. _phase = initializing
    // 2. _errorMessage = null
    // 3. notifyListeners()
    // 4. 调用 initLoad()
  }
```

### 5.4 暴露路由目标 `⬜`

```dart
  SplashRouteTarget? _routeTarget;
  SplashRouteTarget? get routeTarget => _routeTarget;
```

---

## 任务 6：[splash_page.dart] — 新建启动页 UI `⬜ 待处理`

文件：`flash_im/lib/src/app/splash/views/splash_page.dart`（新建）

### 6.1 页面骨架 `⬜`

```dart
import 'package:flutter/material.dart';
import '../config/splash_config.dart';
import '../models/splash_state.dart';
import '../viewmodel/splash_viewmodel.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final SplashViewModel _viewModel;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _viewModel = SplashViewModel();
    // 1. 创建 AnimationController，duration 取 SplashConfig.logoAnimMs + textAnimMs
    // 2. 定义 scaleAnim: 0.8 → 1.0（前 logoAnimMs）
    // 3. 定义 fadeAnim: 0.0 → 1.0（后 textAnimMs）
    // 4. forward() 播放动画
    // 5. 调用 _viewModel.initLoad()
    // 6. 添加 _viewModel 监听：当 phase == ready 时执行路由跳转
  }

  @override
  void dispose() {
    _animController.dispose();
    _viewModel.dispose();
    super.dispose();
  }
```

### 6.2 路由跳转逻辑 `⬜`

在 `initState` 中添加监听器：

```dart
  void _onViewModelChanged() {
    if (_viewModel.phase == SplashPhase.ready) {
      final target = _viewModel.routeTarget;
      if (target == SplashRouteTarget.home) {
        // Navigator.pushReplacement → MainPage
      } else {
        // Navigator.pushReplacement → LoginPage
      }
    }
  }
```

> 跳转时使用 `Navigator.pushReplacement`，不可回退。可加 `MaterialPageRoute` 全屏透明路由或默认路由。

### 6.3 build 方法 `⬜`

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          final phase = _viewModel.phase;
          return Stack(
            fit: StackFit.expand,
            children: [
              // 主体：Logo + 文字 + 动画
              _buildLogoSection(),
              // 底部状态区
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: phase == SplashPhase.initializing
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : _buildErrorSection(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
```

### 6.4 Logo + 文字区域 `⬜`

```dart
  Widget _buildLogoSection() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ScaleTransition 包裹 Logo 图片
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
            child: Image.asset(
              SplashConfig.logoPath,
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text('FI', style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  )),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // FadeTransition + 上移 包裹文字
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) => Opacity(
              opacity: _fadeAnim.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _fadeAnim.value)),
                child: child,
              ),
            ),
            child: const Text(
              SplashConfig.appName,  // "Flash IM"
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
```

> Logo 加载失败时显示渐变色圆形占位（与 Auth 模块头像 fallback 风格一致）。

### 6.5 错误状态展示 `⬜`

```dart
  Widget _buildErrorSection() {
    final errorMsg = _viewModel.errorMessage ?? '加载失败，请重试';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(errorMsg, style: const TextStyle(
          color: Color(0xFF999999), fontSize: 14,
        )),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _viewModel.retry,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('重试'),
        ),
      ],
    );
  }
```

---

## 任务 7：占位页面 — 登录页 + 主页 `⬜ 待处理`

### 7.1 [login_page.dart] 登录页占位 `⬜`

文件：`flash_im/lib/src/app/auth/views/login_page.dart`（新建）

```dart
import 'package:flutter/material.dart';

/// 登录页占位 — 后续由 auth 模块替换
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('登录页（待实现）', style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
      ),
    );
  }
}
```

### 7.2 [main_page.dart] 主页占位 `⬜`

文件：`flash_im/lib/src/app/home/views/main_page.dart`（新建）

```dart
import 'package:flutter/material.dart';

/// 主页占位 — 后续由 auth 模块替换为底部三 Tab 主框架
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flash IM'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('主页（待实现）', style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
      ),
    );
  }
}
```

> 两个占位页都设置 `automaticallyImplyLeading: false`，防止出现返回按钮（从 SplashPage pushReplacement 过来的，不应有回退）。

---

## 任务 8：[main.dart] — 重写为正式 App 入口 `⬜ 待处理`

文件：`flash_im/lib/main.dart`（修改）

### 8.1 替换原有内容 `⬜`

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

**关键变更**：
- 删除原有 `MyApp`、`MyHomePage`、`_MyHomePageState` 等计数器 demo 代码
- 新增 `WidgetsFlutterBinding.ensureInitialized()`（initState 之前需要 Flutter 引擎就绪）
- 设置 `debugShowCheckedModeBanner: false` 隐藏调试横幅（正式 App 体验）
- 主题色使用 `4F46E5`（与 Auth 模块渐变主色一致）
- `home` 直接指向 `SplashPage`

---

## 任务 9：编译验证 `⬜ 待处理`

### 9.1 flutter analyze 验证 `⬜`

```bash
cd flash_im
flutter analyze
```

确保零 error、零 warning（允许已有的 info 级别提示）。

### 9.2 目录结构最终确认 `⬜`

```
flash_im/
├── assets/
│   └── images/
│       └── .gitkeep
├── lib/
│   ├── main.dart                              # 重写：正式 App 入口
│   ├── main_playground.dart                   # 不动
│   └── src/
│       ├── app/                               # 新增
│       │   ├── splash/
│       │   │   ├── config/splash_config.dart
│       │   │   ├── models/splash_state.dart
│       │   │   ├── services/splash_service.dart
│       │   │   ├── viewmodel/splash_viewmodel.dart
│       │   │   └── views/splash_page.dart
│       │   ├── auth/views/login_page.dart      # 占位
│       │   └── home/views/main_page.dart       # 占位
│       └── playground/                         # 不动
├── pubspec.yaml                               # 新增 assets 声明
└── docs/
    └── features/splash/
        ├── README.md
        ├── roadmap.md
        └── v1.0/client/
            ├── design.md
            └── tasks.md
```

---