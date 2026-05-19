# HTTP vs WebSocket 对比研究

> 为什么即时通信（IM）产品必须使用 WebSocket

## 一、通俗比喻

| | HTTP | WebSocket |
|---|---|---|
| 比喻 | **打电话**：每次通话都要重新拨号，说完就挂断 | **对讲机**：建立连接后随时可以说话，一直保持通话状态 |
| 通信方式 | 你问我答，一问一答 | 随时互传消息，双向通道 |
| 连接 | 每次请求都新建连接，用完即关 | 建立一次连接，长期保持 |

## 二、通信流程对比

### HTTP 通信流程（短连接）

```mermaid
sequenceDiagram
    participant C as 客户端
    participant S as 服务端

    Note over C,S: 客户端发送消息给服务端
    C->>S: ① 建立 TCP 连接（三次握手）
    C->>S: ② 发送 HTTP 请求（GET /send_msg）
    S-->>C: ③ 返回响应（200 OK）
    C->>S: ④ 关闭连接

    Note over C,S: 客户端想接收新消息
    C->>S: ⑤ 建立 TCP 连接
    C->>S: ⑥ 发送请求（GET /get_msg）
    alt 没有新消息
        S-->>C: ⑦ 返回空数据
    else 有新消息
        S-->>C: ⑦ 返回消息
    end
    C->>S: ⑧ 关闭连接

    Note over C,S: 下次又要重复 ①~⑧...
```

### WebSocket 通信流程（长连接）

```mermaid
sequenceDiagram
    participant C as 客户端
    participant S as 服务端

    Note over C,S: 建立连接阶段
    C->>S: ① HTTP 握手请求（Upgrade: websocket）
    S-->>C: ② 同意升级协议
    Note over C,S: 连接建立成功，TCP 不断开

    Note over C,S: 通信阶段
    C->>S: ③ 发送消息："你好"
    S-->>C: ④ 实时推送消息："对方正在输入..."
    C->>S: ⑤ 发送消息："收到"
    S-->>C: ⑥ 推送新消息："对方已读"
    S-->>C: ⑦ 推送消息："对方撤回了一条消息"
    Note over C,S: 连接一直保持，随时收发消息

    Note over C,S: 需要时才断开
    C->>S: ⑧ 关闭连接（Close）
```

## 三、核心区别

| 维度 | HTTP | WebSocket |
|---|---|---|
| **连接方式** | 短连接，每次请求新建 | 长连接，建立后持续保持 |
| **通信方向** | 单向（客户端发起，服务端响应） | 双向（两端随时主动发消息） |
| **协议** | 应用层协议 | 基于 TCP，独立协议 |
| **头部大小** | 大（每次带完整 Header，几 KB） | 小（仅 2~14 字节帧头） |
| **实时性** | 差（依赖轮询，有延迟） | 好（毫秒级推送） |
| **服务端主动推送** | 不支持 | 原生支持 |
| **适用场景** | 网页浏览、表单提交、RESTful API | 实时聊天、在线游戏、直播弹幕 |

## 四、为什么 IM 必须用 WebSocket

### 4.1 场景 1：收消息

**HTTP 方案（轮询）的困境：**

```mermaid
sequenceDiagram
    participant A as 用户A
    participant S as 服务器
    participant B as 用户B

    B->>S: 发送消息："在吗？"
    Note over A,S: A 不知道有新消息...

    loop 每隔 2 秒轮询一次
        A->>S: 有新消息吗？
        S-->>A: 没有
    end

    A->>S: 有新消息吗？
    S-->>A: 有！"在吗？"
    Note over A: 延迟 0~2 秒，体验差
```

- 轮询间隔短 = 耗电耗流量
- 轮询间隔长 = 消息延迟大
- 大量无效请求，服务器压力大

**WebSocket 方案：**

```mermaid
sequenceDiagram
    participant A as 用户A
    participant S as 服务器
    participant B as 用户B

    Note over A,S: 连接已建立，持续监听
    B->>S: 发送消息："在吗？"
    S-->>A: ⚡ 立即推送消息（毫秒级）
    Note over A: 实时收到，无延迟
```

- 服务端有新消息时**主动推送**
- 零延迟，毫秒级到达
- 无多余请求，省流量省电

### 4.2 场景 2：在线状态

```mermaid
sequenceDiagram
    participant U as 用户
    participant S as 服务器

    Note over U: HTTP 方案
    loop 定期上报心跳
        U->>S: 我还在线（Heartbeat）
        S-->>U: 收到
    end
    Note over U,S: 频繁请求，浪费资源
    Note over U: WebSocket 方案
    U-->>S: 建立长连接
    Note over U,S: 连接存在 = 用户在线
    Note over U,S: 连接断开 = 用户离线
    Note over U,S: 天然感知状态，无需额外请求
```

### 4.3 场景 3：群聊消息广播

```mermaid
sequenceDiagram
    participant A as 用户A
    participant S as 服务器
    participant B as 用户B
    participant C as 用户C
    participant D as 用户D

    A->>S: 发送群消息
    Note over S: HTTP 方案：需要每个群成员轮询<br/>消息到达时间不一致
    par
        B->>S: 有新消息吗？
        S-->>B: 返回消息
    and
        C->>S: 有新消息吗？
        S-->>C: 返回消息
    and
        D->>S: 有新消息吗？
        S-->>D: 返回消息
    end

    Note over A,D: WebSocket 方案
    A->>S: 发送群消息
    S-->>B: ⚡ 主动推送
    S-->>C: ⚡ 主动推送
    S-->>D: ⚡ 主动推送
    Note over B,D: 所有人同时收到
```

## 五、性能对比

### 消息到达延迟

| 方案 | 平均延迟 | 最大延迟 |
|---|---|---|
| HTTP 轮询（间隔 2 秒） | 1 秒 | 2 秒 |
| HTTP 轮询（间隔 5 秒） | 2.5 秒 | 5 秒 |
| **WebSocket** | **< 100 毫秒** | **< 500 毫秒** |

### 流量消耗（假设 1000 次消息通信）

| 方案 | 请求次数 | 额外开销 |
|---|---|---|
| HTTP 轮询（2秒/次） | 约 36,000 次/小时 | 大量无效请求 |
| **WebSocket** | **1 次连接 + 实际消息数** | **几乎无额外开销** |

## 六、总结：IM 产品为什么必须用 WebSocket

| IM 核心需求 | HTTP 能否满足 | WebSocket |
|---|---|---|
| 消息实时到达 | ❌ 轮询有延迟 | ✅ 毫秒级推送 |
| 服务端主动推送 | ❌ 不支持 | ✅ 原生支持 |
| 在线状态感知 | ⚠️ 需额外心跳 | ✅ 连接即状态 |
| 省流量省电 | ❌ 大量轮询请求 | ✅ 仅传输有效数据 |
| 群聊广播 | ⚠️ 效率低下 | ✅ 一次推送全员 |
| 消息已读回执 | ⚠️ 延迟高 | ✅ 实时回执 |
| 输入状态提示 | ❌ 体验差 | ✅ 实时显示 |

**结论：** HTTP 适合"请求-响应"模式的一次性交互（如加载列表、提交表单）。而 IM 的核心是**持续、双向、实时**的通信，WebSocket 的长连接和双向推送特性完美契合这一需求。这就是为什么微信、QQ、Telegram、Slack 等所有即时通信产品都使用 WebSocket（或类似长连接协议）的原因。

## 七、技术选型建议

对于 Flash IM 项目：

```mermaid
graph LR
    A[IM 通信协议] --> B{是否需要实时推送?}
    B -->|是| C[WebSocket]
    B -->|否| D[HTTP]
    
    C --> E[Flutter 端: web_socket_channel]
    C --> F[服务端: Socket.IO / ws]
    C --> G[断线重连机制]
    C --> H[心跳保活]
    
    D --> I[用户资料/历史记录/文件下载]
    
    style C fill:#90EE90
    style D fill:#FFE4B5
```

- **消息收发** → WebSocket
- **用户信息、历史记录查询** → HTTP（RESTful API）
- **大文件传输** → HTTP（分片上传/下载）

两者配合使用，各取所长。
