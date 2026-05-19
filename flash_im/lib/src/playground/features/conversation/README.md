# Conversation 网络请求单元

这是一个基于 Dio 的网络请求演示模块，展示了如何构建结构清晰、可测试的网络请求层。

## 目录结构

```
conversation/
├── config/
│   └── api_config.dart          # API 配置（可配置的 IP 地址）
├── models/
│   └── conversation_item.dart   # 会话实体类
├── services/
│   └── conversation_service.dart # 网络请求服务层
├── conversation_demo.dart       # UI 演示页面
└── README.md                    # 本文档
```

## 功能特性

### 1. 分层架构
- **Config 层**: 管理 API 配置，支持动态修改基础 URL
- **Model 层**: 定义数据实体，提供 JSON 序列化/反序列化
- **Service 层**: 封装网络请求逻辑，统一错误处理
- **UI 层**: 展示数据和用户交互

### 2. 可配置的 IP 地址
通过 `ApiConfig` 类可以动态修改基础 URL：

```dart
// 更新 API 地址
ApiConfig.updateBaseUrl('http://192.168.1.100:3000');

// 或通过 Service 更新
service.updateBaseUrl('http://192.168.1.100:3000');
```

### 3. 完善的错误处理
- 连接超时
- 请求超时
- 网络错误
- 服务器响应错误
- 统一的错误信息提示

### 4. 独立测试
测试文件位于 `test/playground/conversation_service_test.dart`，包含：
- 单元测试（模型序列化、配置更新）
- 集成测试（实际网络请求）

## 使用方法

### 1. 安装依赖

```bash
cd flash_im
flutter pub get
```

### 2. 启动后端服务

确保后端服务运行在 `http://127.0.0.1:3000`，并提供 `/conversation` 接口。

### 3. 运行应用

```bash
flutter run -t lib/main_playground.dart
```

在 Playground 首页点击"会话列表 (Conversation)"进入演示页面。

### 4. 运行测试

```bash
# 运行所有测试
flutter test test/playground/conversation_service_test.dart

# 运行特定测试
flutter test test/playground/conversation_service_test.dart --name "fromJson"
```

## API 接口说明

### GET /conversation

返回会话列表数据。

**响应示例**:
```json
[
  {
    "title": "张三",
    "lastMsg": "晚上一起吃饭吗？",
    "time": "2026-04-25 18:30"
  },
  {
    "title": "李四",
    "lastMsg": "项目文档已发送",
    "time": "2026-04-25 17:45"
  }
]
```

## 代码示例

### 基本使用

```dart
// 创建服务实例
final service = ConversationService();

// 获取会话列表
try {
  final conversations = await service.getConversationList();
  print('获取到 ${conversations.length} 条会话');
} catch (e) {
  print('请求失败: $e');
}
```

### 自定义配置

```dart
// 使用自定义 Dio 实例
final dio = Dio();
dio.options.connectTimeout = Duration(seconds: 5);
final service = ConversationService(dio: dio);

// 更新 API 地址
service.updateBaseUrl('http://192.168.1.100:3000');
```

## 扩展建议

1. **添加更多接口**: 在 `ConversationService` 中添加其他 API 方法
2. **状态管理**: 集成 Provider/Riverpod/Bloc 等状态管理方案
3. **缓存策略**: 添加本地缓存减少网络请求
4. **Mock 测试**: 使用 `mockito` 或 `http_mock_adapter` 进行 Mock 测试
5. **请求拦截**: 添加认证、日志、重试等拦截器

## 注意事项

- 确保后端服务正常运行
- 修改 IP 地址后需要重新请求
- 集成测试依赖实际的网络环境
- 生产环境建议使用 HTTPS
