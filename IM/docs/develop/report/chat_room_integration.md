# ChatRoom 聊天室模块开发报告

## 一、概述

本次开发将 **WebSocket 心跳通信** 和 **JWT 用户认证** 两个独立模块进行整合，构建了一个完整的聊天室（ChatRoom）功能。采用业界主流的 **URL Query Token 认证方案**（方案 A），在 WebSocket 握手阶段完成身份验证。

## 二、技术选型

### 2.1 认证方案

| 方案 | 选择 | 理由 |
|------|------|------|
| URL Query 携带 Token | ✅ 采用 | 握手阶段同步验证、安全性高、实现简单、资源占用少 |
| 首条消息携带 Token | ❌ 未采用 | 存在匿名窗口期、需额外计时器防御、复杂度高 |

### 2.2 核心流程

```
客户端 ──HTTP 登录──▶ 服务端 (获取 JWT Token)
客户端 ──WS /ws/chat_room?token=xxx──▶ 服务端 (握手时校验 Token)
         ✅ 通过 → 绑定用户身份 → 进入正常通信
         ❌ 失败 → 拒绝升级 → 关闭连接
```

## 三、后端实现

### 3.1 新增接口

- **路径**：`/ws/chat_room`
- **协议**：WebSocket
- **认证方式**：URL Query 参数 `?token=<JWT>`

### 3.2 核心功能

#### 3.2.1 JWT 握手认证
```javascript
// 从 URL query 中提取 token
const token = url.searchParams.get('token');
// 验证签名和过期时间
const decoded = jwt.verify(token, JWT_SECRET);
// 查询用户并绑定连接
onlineUsers.set(user.user_id, ws);
```

#### 3.2.2 心跳保活机制
- **间隔**：30 秒
- **方式**：服务端 `ping` → 客户端 `pong`
- **超时处理**：未响应 pong 则主动断开连接 (`terminate`)

#### 3.2.3 消息广播
- 支持文本消息发送与全房间广播
- 自动附加发送者信息（userId、nickname、avatar）
- 系统消息通知（加入/离开）

### 3.3 错误码定义

| 错误码 | 含义 |
|--------|------|
| 4001 | Token 缺失 |
| 4002 | Token 无效或已过期 |
| 4003 | 用户不存在 |

### 3.4 文件变更

- [server.js](../../IM/server.js) — 新增 `/ws/chat_room` WebSocket 服务端点（约 130 行新增代码）

## 四、前端实现

### 4.1 目录结构

```
features/chat_room/
├── config/
│   └── chat_room_config.dart          # 配置（URL、心跳间隔）
├── models/
│   ├── chat_message.dart              # 聊天消息模型 + 系统消息模型
│   └── chat_room_state.dart           # 连接状态模型（含状态机）
├── services/
│   └── chat_room_service.dart         # 核心服务（WS连接+JWT+心跳）
├── viewmodel/
│   └── chat_room_viewmodel.dart       # ViewModel（状态管理）
└── views/
    ├── chat_room_page.dart            # 主页面（底部导航栏）
    ├── chat_list_view.dart            # 聊天列表页（微信风格）
    └── profile_view.dart             # 个人中心页
```

### 4.2 页面设计（微信风格）

#### 底部导航栏
- **聊天室**（Tab 0）：绿色高亮，显示在线人数状态徽章
- **我的**（Tab 1）：个人资料、连接状态、操作按钮

#### 聊天室页面
- 顶部状态栏：实时显示连接状态 + 在线人数
- 消息气泡：左右对齐（自己靠右/他人靠左），头像 + 昵称 + 时间戳
- 输入框：表情按钮 + 多行输入 + 发送按钮（渐变绿）

#### 个人中心页面
- 头部：渐变背景 + 大头像 + 连接状态标签
- 卡片式布局：
  - 账号信息（ID、昵称、在线人数）
  - 连接状态（认证状态、最近心跳时间、错误信息）
  - 操作区（重连/断开/清空消息）

### 4.3 核心服务架构

```
ChatRoomService
├── connect(token)        # 建立 WS 连接（带 JWT）
├── sendMessage(content)  # 发送聊天消息
├── sendPing()           # 心跳 ping
├── _startHeartbeat()    # 启动心跳定时器（10s）
├── _scheduleReconnect() # 断线自动重连（指数退避）
└── disconnect()         # 断开连接
```

### 4.4 状态机

```
disconnected → connecting → authenticating → authenticated
     ↑              ↓                              ↓
     └──────────────┴──────────── reconnect ←─────┘
                     ↓
                   error
```

### 4.5 入口集成

在 [playground_home.dart](../../../flash_im/lib/src/playground/playground_home.dart) 首页新增「聊天室」入口项，位于「用户认证」之后。

## 五、协议格式

### 5.1 客户端 → 服务端

```json
// 心跳
{ "type": "ping", "timestamp": 1700000000000 }

// 发送消息
{ "type": "message", "content": "你好", "msgType": "text" }
```

### 5.2 服务端 → 客户端

```json
// 认证成功
{ "type": "auth_success", "message": "欢迎回来", "userId": 1, "nickname": "...", "avatar": "...", "onlineCount": 5 }

// 认证失败
{ "type": "auth_error", message": "Token 无效或已过期" }

// 心跳响应
{ "type": "pong", "timestamp": 1700000000000, "serverTime": "2026-05-11 12:00:00" }

// 聊天消息
{ "type": "chat_message", "id": "1", "fromUserId": 1, "fromNickname": "...", "fromAvatar": "...", "content": "...", "type": "text", "time": "12:00" }

// 系统消息
{ "type": "system_message", "content": "xxx 加入了聊天室", "time": "12:00", "onlineCount": 6 }
```

## 六、安全设计

1. **Token 验证**：握手阶段同步校验，未通过则拒绝建立连接
2. **匿名连接防护**：无 Token 的连接直接关闭，不占用服务端资源
3. **心跳超时检测**：30 秒内无 pong 响应则强制断开
4. **自动重连限制**：最多 5 次，指数退避（2s → 10s），防止无限重连风暴

## 七、测试说明

### 7.1 前置条件

1. 启动后端服务：`cd IM && node server.js`（端口 3000）
2. 先通过「用户认证」页面登录获取 Token
3. 进入「聊天室」页面即可自动连接

### 7.2 测试步骤

1. 打开 Playground 首页 → 点击「聊天室(ChatRoom)」
2. 观察顶部状态栏变化：`未连接` → `连接中...` → `N人在线`
3. 发送消息，观察气泡渲染（左侧他人 / 右侧自己）
4. 切换到「我的」Tab，查看账号信息和连接详情
5. 点击「断开」再点击「连接」，验证重连功能
6. 可开多个客户端模拟多人聊天

## 八、文件清单

| 文件 | 类型 | 说明 |
|------|------|------|
| `IM/server.js` | 后端 | 新增 `/ws/chat_room` 接口（~130行） |
| `chat_room_config.dart` | 前端配置 | URL、心跳间隔等常量 |
| `chat_message.dart` | 前端模型 | 聊天消息 & 系统消息数据类 |
| `chat_room_state.dart` | 前端模型 | 连接状态枚举 & 数据类 |
| `chat_room_service.dart` | 前端服务 | WS连接/JWT/心跳核心逻辑 |
| `chat_room_viewmodel.dart` | 前端VM | 状态管理 & SharedPreferences |
| `chat_room_page.dart` | 前端视图 | 主页面（底部导航） |
| `chat_list_view.dart` | 前端视图 | 聊天室界面（微信风格） |
| `profile_view.dart` | 前端视图 | 个人中心界面 |
| `playground_home.dart` | 入口修改 | 新增聊天室入口 |

## 九、总结

本次整合实现了：

- ✅ **JWT + WebSocket 深度整合**：握手阶段完成身份认证
- ✅ **心跳保活**：30s 间隔 ping/pong，超时自动断开
- ✅ **微信风格 UI**：底部导航栏 + 聊天气泡 + 个人中心
- ✅ **断线重连**：指数退避策略，最多 5 次
- ✅ **全栈代码零编译错误**
