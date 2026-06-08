# Flash IM

即时通讯应用，包含 **Flutter 客户端** 和 **Rust 后端**。

## 版本变更

### v0.3.0 — 隔离、拆分、实践（服务端+客户端）

**隔离（模块化）**
- 将 `flash_auth` 认证模块从 `flash_im` 中抽离为独立 Flutter 包 (`modules/flash_auth/`)
- 认证相关模型、服务、仓库、视图、组件独立封装，可复用

**拆分（架构重构）**
- **服务端**：完成 Node.js → Rust 迁移，删除旧 `server.js`/`node_modules`，新增 `IM/server/modules/flash_auth/` 模块化结构
- **客户端**：创建 `flash_im/lib/src/app/` 正式应用架构，从 playground 阶段过渡到真实应用开发
- 新增 `PUT /user/profile` 接口，支持用户资料更新

**实践（功能落地）**
- 用户资料编辑：昵称、签名修改，头像随机更换
- 对称方块图案头像系统（`PatternAvatar`），支持服务端持久化
- 密码管理：首次设置密码、修改密码（需原密码验证）
- 个人中心页面重构为微信风格布局
- 新增签名编辑页面（`EditSignaturePage`）

---

### v0.2.0 — 后端认证系统升级

- Rust 后端：JWT 认证、短信验证码登录、密码登录、密码管理
- PostgreSQL 数据库 + SQLx 迁移
- 服务端脚本：数据库初始化/重置、服务器启动
- 设计文档体系：feature-designer、feature-task-maker
- 认证升级客户端支持：密码登录、Token 持久化

### v0.1.0 — 项目初始化

- Flutter 客户端 playground 阶段：心跳通信、用户认证、聊天室、会话列表、烟花动画
- 设计文档：splash 功能设计

## 项目结构

```
client/
├── flash_im/                  # Flutter 客户端
│   └── lib/
│       ├── main.dart          # 正式入口
│       ├── main_playground.dart # Playground 入口
│       └── src/
│           ├── app/           # 正式应用架构
│           │   └── home/views/ # 主页视图（消息、联系人、个人中心）
│           └── playground/    # Playground 功能模块
├── modules/
│   └── flash_auth/            # 独立认证模块包
│       └── lib/src/
│           ├── config/        # API 配置
│           ├── models/        # 数据模型
│           ├── repositories/  # 业务仓库
│           ├── services/      # HTTP 服务
│           ├── views/         # UI 视图
│           └── widgets/       # 通用组件
├── IM/
│   ├── im-server/             # Rust 后端
│   │   └── src/
│   │       ├── main.rs        # 入口
│   │       ├── db.rs          # 数据库连接
│   │       ├── state.rs       # 应用状态
│   │       ├── ws/            # WebSocket 处理
│   │       └── mock/          # 模拟数据
│   ├── server/
│   │   └── modules/
│   │       └── flash_auth/    # 认证模块（JWT、密码、短信、用户）
│   ├── scripts/               # 运维脚本
│   └── migrations/            # 数据库迁移
└── docs/
    ├── features/              # 功能设计文档
    ├── feature-designer.md    # 功能设计规范
    └── feature-task-maker.md  # 任务生成规范
```

## 快速开始

### 后端

```powershell
# 初始化数据库（首次）
powershell -ExecutionPolicy Bypass -File IM/scripts/db/init.ps1

# 启动服务
powershell -ExecutionPolicy Bypass -File IM/scripts/server/start.ps1
```

服务运行在 `http://127.0.0.1:3000`，需要 PostgreSQL（`postgres`/`123456`，数据库 `flash_im`）。

### 客户端

```bash
# Playground 模式
cd flash_im && flutter run -t lib/main_playground.dart

# 正式应用
cd flash_im && flutter run -t lib/main.dart
```

## REST API

| 方法 | 路径 | 认证 | 说明 |
|------|------|------|------|
| GET | `/v` | - | 系统信息 |
| GET | `/conversation` | - | 会话列表 |
| POST | `/auth/sms` | - | 发送验证码 |
| POST | `/auth/login` | - | 短信登录 |
| POST | `/auth/login/password` | - | 密码登录 |
| POST | `/auth/password/setup` | Bearer | 设置密码 |
| POST | `/auth/password` | Bearer | 修改密码 |
| GET | `/user/profile` | Bearer | 获取用户信息 |
| PUT | `/user/profile` | Bearer | 更新用户资料 |
| GET | `/ws` | - | WebSocket Echo |
| GET | `/ws/chat_room` | JWT | 聊天室 |