# Conversation 网络请求单元 - 项目结构

## 📁 完整目录结构

```
flash_im/
├── lib/
│   └── src/
│       └── playground/
│           ├── features/
│           │   └── conversation/
│           │       ├── config/
│           │       │   └── api_config.dart           # API 配置类
│           │       ├── models/
│           │       │   └── conversation_item.dart    # 会话实体类
│           │       ├── services/
│           │       │   └── conversation_service.dart # 网络请求服务
│           │       ├── conversation_demo.dart        # UI 演示页面
│           │       └── README.md                     # 使用文档
│           ├── playground_home.dart                  # Playground 首页
│           └── main_playground.dart                  # 入口文件
├── test/
│   └── playground/
│       └── conversation_service_test.dart            # 单元测试
├── docs/
│   └── data/
│       └── playground/
│           └── conversation/
│               └── list.json                         # 接口数据示例
└── pubspec.yaml                                      # 依赖配置
```

## 🏗️ 架构设计

### 1. Config 层 (配置层)
**文件**: `config/api_config.dart`

**职责**:
- 管理 API 基础 URL
- 定义接口路径常量
- 提供 URL 动态配置能力

**特点**:
- 单一配置源
- 支持运行时修改
- 便于环境切换（开发/测试/生产）

### 2. Model 层 (数据模型层)
**文件**: `models/conversation_item.dart`

**职责**:
- 定义数据结构
- JSON 序列化/反序列化
- 数据验证和转换

**特点**:
- 类型安全
- 可复用
- 易于测试

### 3. Service 层 (服务层)
**文件**: `services/conversation_service.dart`

**职责**:
- 封装网络请求逻辑
- 统一错误处理
- 配置 HTTP 客户端
- 提供业务接口

**特点**:
- 单一职责
- 依赖注入（可传入自定义 Dio）
- 完善的错误处理
- 日志拦截器

### 4. UI 层 (界面层)
**文件**: `conversation_demo.dart`

**职责**:
- 展示数据
- 用户交互
- 状态管理
- 错误提示

**特点**:
- 响应式 UI
- 加载状态处理
- 错误友好提示
- 可配置 API 地址

## 🔧 技术栈

- **网络库**: Dio 5.9.2
- **UI 框架**: Flutter Material Design
- **测试框架**: flutter_test
- **语言**: Dart 3.11.4+

## 📊 数据流

```
用户操作
   ↓
UI 层 (conversation_demo.dart)
   ↓
Service 层 (conversation_service.dart)
   ↓
Dio HTTP 请求
   ↓
后端 API (http://127.0.0.1:3000/conversation)
   ↓
JSON 响应
   ↓
Model 层解析 (conversation_item.dart)
   ↓
UI 层展示
```

## ✅ 测试覆盖

### 单元测试
- ✓ 模型序列化测试
- ✓ 模型反序列化测试
- ✓ API 配置更新测试
- ✓ Service URL 更新测试
- ✓ 模型 toString 测试
- ✓ 空字符串处理测试

### 集成测试
- ✓ 实际网络请求测试
- ✓ 连接错误处理测试

**测试命令**:
```bash
flutter test test/playground/conversation_service_test.dart
```

## 🚀 使用示例

### 基础使用
```dart
final service = ConversationService();
final conversations = await service.getConversationList();
```

### 自定义配置
```dart
// 方式 1: 更新全局配置
ApiConfig.updateBaseUrl('http://192.168.1.100:3000');

// 方式 2: 通过 Service 更新
service.updateBaseUrl('http://192.168.1.100:3000');

// 方式 3: 自定义 Dio
final dio = Dio();
dio.options.connectTimeout = Duration(seconds: 5);
final service = ConversationService(dio: dio);
```

## 🎯 设计原则

1. **单一职责**: 每个类只负责一个功能
2. **依赖注入**: Service 支持注入自定义 Dio
3. **开闭原则**: 易于扩展，无需修改现有代码
4. **可测试性**: 所有层都可独立测试
5. **配置分离**: 配置与业务逻辑分离

## 🔄 扩展方向

### 1. 添加更多接口
```dart
// 在 ConversationService 中添加
Future<ConversationDetail> getConversationDetail(String id) async {
  final response = await _dio.get('/conversation/$id');
  return ConversationDetail.fromJson(response.data);
}
```

### 2. 集成状态管理
```dart
// 使用 Provider
class ConversationProvider extends ChangeNotifier {
  final ConversationService _service = ConversationService();
  List<ConversationItem> _conversations = [];
  
  Future<void> loadConversations() async {
    _conversations = await _service.getConversationList();
    notifyListeners();
  }
}
```

### 3. 添加缓存
```dart
// 使用 shared_preferences 或 hive
class CachedConversationService extends ConversationService {
  Future<List<ConversationItem>> getConversationList() async {
    // 先读缓存
    final cached = await _loadFromCache();
    if (cached != null) return cached;
    
    // 缓存失效，请求网络
    final data = await super.getConversationList();
    await _saveToCache(data);
    return data;
  }
}
```

### 4. Mock 测试
```dart
// 使用 mockito
class MockDio extends Mock implements Dio {}

test('should handle mock response', () async {
  final mockDio = MockDio();
  when(mockDio.get(any)).thenAnswer((_) async => Response(
    data: [{'title': 'Test', 'lastMsg': 'Hello', 'time': '2026-04-25'}],
    statusCode: 200,
    requestOptions: RequestOptions(path: '/conversation'),
  ));
  
  final service = ConversationService(dio: mockDio);
  final result = await service.getConversationList();
  expect(result.length, 1);
});
```

## 📝 注意事项

1. **网络权限**: 确保 Android/iOS 配置了网络权限
2. **HTTPS**: 生产环境建议使用 HTTPS
3. **错误处理**: 所有网络请求都应该有 try-catch
4. **超时设置**: 根据实际情况调整超时时间
5. **日志管理**: 生产环境应关闭详细日志

## 📚 相关文档

- [Dio 官方文档](https://pub.dev/packages/dio)
- [Flutter 网络请求最佳实践](https://flutter.dev/docs/cookbook/networking)
- [Dart 异步编程](https://dart.dev/codelabs/async-await)
