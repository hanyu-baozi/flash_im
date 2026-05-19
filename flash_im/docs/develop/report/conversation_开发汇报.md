# Conversation 功能开发汇报文档

## 1. 项目背景

在游乐场（Playground）模块中实现 IM 会话列表功能，从前端到后端全流程由 AI 完成，用户仅通过自然语言对话即可完成功能开发。

---

## 2. 项目结构概览

```
e:\flutter_project\client\
├── flash_im/                          # Flutter 前端项目
│   ├── lib/src/playground/features/conversation/
│   │   ├── config/api_config.dart     # API 配置
│   │   ├── models/conversation_item.dart  # 数据模型
│   │   ├── services/conversation_service.dart  # 网络服务
│   │   ├── viewmodel/conversation_viewmodel.dart  # 视图模型
│   │   ├── views/conversation_page.dart  # 页面视图
│   │   └── widgets/                   # UI 组件
│   ├── test/playground/conversation_service_test.dart  # 测试
│   └── docs/playground/conversation_structure.md  # 结构文档
│
└── IM/                                # 后端项目
    ├── server.js                      # Node.js 后端服务
    └── im-server/src/main.rs          # Rust 后端服务
```

---

## 3. 核心开发流程

### 3.1 需求分析与项目探索

**关键决策点：**
- 识别出项目已有完整的分层架构：Config → Model → Service → ViewModel → View
- 确定前端已有 mock 数据，需要替换为真实后端接口
- 发现存在两个后端实现：Rust (`main.rs`) 和 Node.js (`server.js`)

**涉及文件：**
- `flash_im/lib/src/playground/features/conversation/services/conversation_service.dart`
- `flash_im/lib/src/playground/features/conversation/models/conversation_item.dart`
- `flash_im/lib/src/playground/features/conversation/config/api_config.dart`
- `IM/im-server/src/main.rs`
- `IM/server.js`

---

### 3.2 后端接口开发

#### 3.2.1 Rust 后端实现

**修改文件：** `IM/im-server/src/main.rs`

**新增内容：**
- 定义 `Conversation` 结构体，包含 8 个字段
- 实现 `get_conversations()` 函数返回 10 条模拟数据
- 实现 `conversations_to_json()` 函数生成 JSON 格式
- 添加 `/conversation` 路由处理

**关键代码：**
```rust
struct Conversation {
    id: String,
    title: String,
    last_msg: String,
    time: String,
    unread_count: i32,
    conversation_type: String,
    message_type: String,
    is_muted: bool,
}

// 路由处理
} else if request.starts_with("GET /conversation HTTP/1.1") {
    let conversations = get_conversations();
    let json = conversations_to_json(&conversations);
    // ...
}
```

**数据字段设计：**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 会话唯一标识 |
| title | String | 会话标题/联系人名称 |
| lastMsg | String | 最后一条消息内容 |
| time | String | 消息时间 |
| unreadCount | int | 未读消息数 |
| type | String | 会话类型 (single/group) |
| messageType | String | 消息类型 (text/image/sticker 等) |
| isMuted | bool | 是否静音 |

---

#### 3.2.2 Node.js 后端实现

**修改文件：** `IM/server.js`

**新增内容：**
- 引入 `cors` 中间件解决跨域问题
- 定义完整的会话数据数组（10 条）
- 配置监听 `0.0.0.0` 以支持局域网访问

**关键代码：**
```javascript
const cors = require('cors');
app.use(cors());

app.listen(port, '0.0.0.0', () => { ... });
```

**启动命令：**
```bash
npm install cors
node server.js
```

---

### 3.3 前端网络层重构

**修改文件：** `flash_im/lib/src/playground/features/conversation/services/conversation_service.dart`

**改造前：** 使用本地 mock 数据
```dart
static Future<List<Map<String, dynamic>>> _fetchMockData() async {
  await Future.delayed(const Duration(milliseconds: 500));
  final List<dynamic> mockList = jsonDecode(mockConversationsJson);
  return mockList.cast<Map<String, dynamic>>();
}
```

**改造后：** 使用 Dio 进行真实网络请求
```dart
class ConversationService {
  final Dio _dio;

  ConversationService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  Future<List<ConversationItem>> getConversationList() async {
    final response = await _dio.get(ApiConfig.conversationPath);
    // 解析响应数据
  }
}
```

**关键技术点：**
1. 使用 Dio 作为 HTTP 客户端
2. 配置连接超时和接收超时
3. 实现完善的错误处理（DioException 类型判断）
4. 支持依赖注入（可传入自定义 Dio 实例用于测试）

---

### 3.4 移动端局域网访问问题解决

**问题描述：**
Flutter 应用在真机运行时，使用 `http://127.0.0.1:3000` 无法连接后端，显示"网络连接失败"。

**根本原因：**
- `127.0.0.1` (localhost) 指向设备自身，而非开发机
- 真机通过 5G 网络，与开发机不在同一局域网

**解决方案：**

| 步骤 | 操作 | 文件 |
|------|------|------|
| 1 | 获取开发机局域网 IP | `ipconfig` |
| 2 | 后端监听 `0.0.0.0` | `server.js` |
| 3 | 添加 CORS 支持 | `server.js` |
| 4 | 更新前端 API 地址 | `api_config.dart` |

**关键修改：**
```dart
// api_config.dart
static String baseUrl = 'http://10.92.11.227:3000';  // 局域网 IP
```

```javascript
// server.js
app.listen(port, '0.0.0.0', () => { ... });  // 监听所有网卡
```

**网络拓扑：**
```
开发机 (10.92.11.227)
    ├── Node.js 后端 (0.0.0.0:3000)
    └── Flutter 前端
         └── 真机/模拟器
              └── HTTP 请求 → http://10.92.11.227:3000/conversation
```

---

### 3.5 数据流向设计

```
用户打开页面
    ↓
ConversationPage (View)
    ↓
ConversationViewModel (状态管理)
    ↓
ConversationService (网络层)
    ↓
Dio HTTP Client
    ↓
http://10.92.11.227:3000/conversation
    ↓
JSON 响应
    ↓
ConversationItem.fromJson() (模型解析)
    ↓
notifyListeners() (状态更新)
    ↓
AnimatedBuilder (UI 重建)
    ↓
ListView.separated (列表渲染)
```

---

## 4. 关键技术点总结

### 4.1 分层架构

| 层级 | 职责 | 文件 |
|------|------|------|
| Config | API 配置管理 | `config/api_config.dart` |
| Model | 数据模型与 JSON 序列化 | `models/conversation_item.dart` |
| Service | 网络请求封装 | `services/conversation_service.dart` |
| ViewModel | 状态管理与业务逻辑 | `viewmodel/conversation_viewmodel.dart` |
| View | UI 展示 | `views/conversation_page.dart` |

### 4.2 错误处理策略

```dart
on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    throw Exception('连接超时');
  } else if (e.type == DioExceptionType.receiveTimeout) {
    throw Exception('响应超时');
  } else if (e.type == DioExceptionType.connectionError) {
    throw Exception('网络连接失败');
  } else {
    throw Exception('请求失败: ${e.message}');
  }
}
```

### 4.3 UI 状态管理

```dart
// 加载状态
if (_viewModel.isLoading) {
  return const Center(child: CircularProgressIndicator());
}

// 错误状态
if (_viewModel.hasError) {
  return _ErrorView(...);
}

// 空数据状态
if (!_viewModel.hasData) {
  return const _EmptyView();
}

// 数据展示
return ListView.separated(...);
```

---

## 5. 涉及的文件清单

### 修改的文件
| 文件路径 | 修改内容 |
|----------|----------|
| `IM/im-server/src/main.rs` | 添加 Conversation 结构体和 /conversation 路由 |
| `IM/server.js` | 添加会话数据、CORS、0.0.0.0 监听 |
| `flash_im/.../conversation_service.dart` | 从 mock 数据改为 Dio 网络请求 |
| `flash_im/.../config/api_config.dart` | 更新 baseUrl 为局域网 IP |

### 新增的文件
| 文件路径 | 说明 |
|----------|------|
| `flash_im/docs/develop/report/` | 汇报文档目录 |

### 已有但未修改的文件
| 文件路径 | 说明 |
|----------|------|
| `flash_im/.../conversation_item.dart` | 数据模型（已完备） |
| `flash_im/.../conversation_viewmodel.dart` | 视图模型（已完备） |
| `flash_im/.../conversation_page.dart` | 页面视图（已完备） |
| `flash_im/.../conversation_list_item.dart` | 列表项组件（已完备） |
| `flash_im/test/.../conversation_service_test.dart` | 单元测试（已完备） |

---

## 6. 开发模式总结

### 6.1 AI 协作流程

1. **需求输入**：用户用自然语言描述需求
2. **项目分析**：AI 自动探索项目结构和已有代码
3. **方案设计**：AI 提出技术方案并实施
4. **问题诊断**：遇到问题时 AI 自动定位原因
5. **方案迭代**：根据运行结果调整实现

### 6.2 关键优势

| 方面 | 传统开发 | AI 协作开发 |
|------|----------|-------------|
| 代码探索 | 手动浏览文件 | 自动语义搜索 |
| 跨文件修改 | 逐个文件操作 | 批量关联修改 |
| 问题排查 | 手动分析日志 | 自动诊断原因 |
| 开发效率 | 按小时计 | 按分钟计 |

---

## 7. 后续优化建议

### 7.1 功能增强
- [ ] 添加下拉刷新动画优化
- [ ] 实现会话搜索功能
- [ ] 添加未读消息角标
- [ ] 支持会话置顶
- [ ] 实现左滑删除/静音

### 7.2 技术优化
- [ ] 添加请求缓存机制
- [ ] 实现 WebSocket 实时更新
- [ ] 添加图片加载优化
- [ ] 实现列表懒加载

### 7.3 工程优化
- [ ] 添加 API Mock 支持
- [ ] 完善单元测试覆盖
- [ ] 添加集成测试
- [ ] 配置 CI/CD 流程

---

*文档生成时间：2026-04-25*
*项目：Flash IM - Conversation 功能*
