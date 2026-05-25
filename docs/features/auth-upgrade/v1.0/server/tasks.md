# 认证系统升级 — 服务端任务清单

基于 [design.md](./design.md) 设计，列出需要创建/修改的具体细节。

**全局约束**：
- 所有数据库操作使用 `sqlx` 异步查询，不引入 ORM
- 密码哈希使用 `bcrypt` crate，替换现有的 `simple_hash()`
- JWT 鉴权复用现有 `auth/jwt.rs` 的 `verify_token()` + `Claims`
- 验证码仍暂存内存 HashMap，本版本不改动
- 响应结构遵循 design.md 定义的 JSON 格式，`has_password` 字段不可遗漏
- **表命名规范**：`{module}_{entity}`（如 `auth_users`），所有 SQL 中的表名必须带模块前缀
- 数据库通过 `scripts/db/init.ps1` 一键创建，迁移由 `sqlx migrate` 管理

---

## 执行顺序

1. ⬜ 任务 0 — 环境准备：安装 sqlx-cli + 创建数据库（无依赖）
2. ⬜ 任务 1 — 添加依赖（依赖任务 0）
3. ⬜ 任务 2 — 创建数据库模块 `db.rs`（依赖任务 1）
4. ⬜ 任务 3 — 创建 SQL 迁移文件（依赖任务 0）
5. ⬜ 任务 4 — 重构 `state.rs`（依赖任务 2）
6. ⬜ 任务 5 — 重构 `auth/user.rs`（依赖任务 4）
7. ⬜ 任务 6 — 重构 `auth/password.rs`（依赖任务 4）
8. ⬜ 任务 7 — 更新 `auth/mod.rs` 路由（依赖任务 5、6）
9. ⬜ 任务 8 — 更新 `main.rs`（依赖任务 2、4）
10. ⬜ 最后 — 编译验证 + 数据库连接测试

---

## 任务 0：环境准备 — sqlx-cli + 数据库 `⬜ 待处理`

### 0.1 安装 sqlx-cli（检测 + 自动安装） `⬜`

```powershell
powershell -ExecutionPolicy Bypass -File ..\..\scripts\setup\install_sqlx.ps1
```

脚本检测 `sqlx` 命令是否存在，不存在则通过 `cargo install sqlx-cli` 自动安装。

### 0.2 创建数据库 + 运行迁移 `⬜`

```powershell
powershell -ExecutionPolicy Bypass -File ..\..\scripts\db\init.ps1
```

脚本完成以下操作：
1. 检查 PostgreSQL 是否运行
2. 若数据库 `flash_im` 不存在则创建
3. 生成 `.env` 写入 `DATABASE_URL=postgres://postgres:123456@localhost:5432/flash_im`
4. 执行 `sqlx migrate run`（自动建 `auth_users` 表 + 插入种子数据）

> 重置数据库用 `scripts/db/reset.ps1`；清空数据保留结构用 `scripts/db/clean.ps1`。

---

## 任务 1：Cargo.toml — 添加新依赖 `⬜ 待处理`

文件：`im-server/Cargo.toml`

### 1.1 新增 `[dependencies]` 条目 `⬜`

在现有 `[dependencies]` 段末尾追加：

```toml
sqlx = { version = "0.8", features = ["runtime-tokio", "tls-rustls", "postgres", "migrate", "uuid", "chrono"] }
bcrypt = "0.16"
dotenvy = "0.15"
```

| 依赖 | 用途 |
|------|------|
| `sqlx` | 异步 PostgreSQL 驱动 + 连接池 + 迁移 |
| `bcrypt` | 替代 `simple_hash()` 做密码哈希 |
| `dotenvy` | 读取 `.env` 中的 `DATABASE_URL` |

---

## 任务 2：创建 `db.rs` — 数据库连接池与迁移 `⬜ 待处理`

文件：`im-server/src/db.rs`（新建）

### 2.1 定义连接池创建函数 `⬜`

```rust
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;

pub async fn create_pool(database_url: &str) -> PgPool {
    // 用 PgPoolOptions 创建连接池
    // max_connections = 5（开发环境足够）
    // 连接 URL 从 .env 读取
}
```

### 2.2 定义迁移执行函数 `⬜`

```rust
pub async fn run_migrations(pool: &PgPool) -> Result<(), sqlx::migrate::MigrateError> {
    // 使用 sqlx::migrate!("./migrations") 宏执行迁移
    // 迁移文件放在 im-server/migrations/ 目录下
}
```

---

## 任务 3：创建 SQL 迁移文件 `⬜ 待处理`

文件：`im-server/migrations/20260519000000_create_auth_users.sql`（新建）

### 3.1 创建 `auth_users` 表 `⬜`

```sql
CREATE TABLE IF NOT EXISTS auth_users (
    id            BIGSERIAL PRIMARY KEY,
    phone         VARCHAR(20)  NOT NULL,
    password_hash VARCHAR(255) NOT NULL DEFAULT '',
    nickname      VARCHAR(50)  NOT NULL DEFAULT '',
    avatar_url    TEXT         NOT NULL DEFAULT '',
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_users_phone ON auth_users (phone);
```

文件：`im-server/migrations/20260519000001_seed_auth_users.sql`（新建）

### 3.2 插入种子数据 `⬜`

```sql
INSERT INTO auth_users (id, phone, password_hash, nickname, avatar_url) VALUES
(1, '13800000001', '<bcrypt hash>', 'Alice', 'https://api.dicebear.com/7.x/identicon/png?seed=alice'),
(2, '13800000002', '<bcrypt hash>', 'Bob',   'https://api.dicebear.com/7.x/identicon/png?seed=bob'),
(3, '13800000003', '<bcrypt hash>', 'Carol', 'https://api.dicebear.com/7.x/identicon/png?seed=carol')
ON CONFLICT (id) DO NOTHING;
```

> 种子密码 `123456` 的 bcrypt hash 需在 `init.ps1` 执行前手动生成填入，或后续版本改为 Rust 启动时 seed。

---

## 任务 4：重构 `state.rs` — AppState 适配数据库 `⬜ 待处理`

文件：`im-server/src/state.rs`（修改）

### 4.1 移除 User / SmsCode / User::new / from_sms / verify_password / simple_hash `⬜`

删除以下内容：
- `User` 结构体及其 `impl` 块（包括 `new`、`from_sms`、`verify_password`）
- `SmsCode` 结构体
- `simple_hash()` 辅助函数

### 4.2 新增 `DbUser` 结构体 `⬜`

定义与 `auth_users` 表对应的数据库行结构体：

```rust
use sqlx::FromRow;
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, FromRow)]
pub struct DbUser {
    pub id: i64,
    pub phone: String,
    pub password_hash: String,
    pub nickname: String,
    pub avatar_url: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
```

### 4.3 重构 AppState `⬜`

```rust
use sqlx::PgPool;
use tokio::sync::{broadcast, RwLock};

pub struct AppState {
    pub pool: PgPool,
    pub sms_codes: RwLock<HashMap<String, SmsCode>>,
    pub chat_tx: broadcast::Sender<String>,
}

impl AppState {
    pub fn new(pool: PgPool) -> Self {
        let (chat_tx, _) = broadcast::channel(256);
        AppState {
            pool,
            sms_codes: RwLock::new(HashMap::new()),
            chat_tx,
        }
    }
}
```

**关键变更**：
- `users: RwLock<HashMap>` → `pool: PgPool`
- 移除 `user_id_counter`（改用 DB `BIGSERIAL` 自增）
- `new()` 不再需要 `seed_users` 参数

### 4.4 保留 SmsCode `⬜`

`SmsCode` 结构体保留不变（验证码仍存内存）。

---

## 任务 5：重构 `auth/user.rs` — 短信登录 + Profile 改为 DB 查询 `⬜ 待处理`

文件：`im-server/src/auth/user.rs`（修改）

### 5.1 LoginResponse 新增 `has_password` `⬜`

在 `LoginResponse` 结构体中追加字段：

```rust
#[derive(Debug, Serialize)]
pub struct LoginResponse {
    // ... 现有字段保持不变 ...
    pub has_password: bool,   // 新增
}
```

### 5.2 重写 `login()` — 从 DB 查询/插入用户 `⬜`

```rust
pub async fn login(
    State(state): State<Arc<AppState>>,
    Json(req): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> {
    // 1. 验证验证码（保持现有逻辑，从 sms_codes HashMap 读取）
    // 2. 用 sqlx::query_as 查 DB：SELECT * FROM auth_users WHERE phone = $1
    //    返回 Option<DbUser>
    // 3. 如果用户不存在：
    //    - INSERT INTO auth_users (phone, nickname, avatar_url) VALUES ($1, $2, $3) RETURNING id
    //    - nickname = phone, avatar_url = dicebear URL
    // 4. has_password = !db_user.password_hash.is_empty()
    // 5. 签发 JWT，返回 LoginResponse
}
```

关键 SQL：

```sql
SELECT id, phone, password_hash, nickname, avatar_url, created_at, updated_at
FROM auth_users WHERE phone = $1
```

```sql
INSERT INTO auth_users (phone, nickname, avatar_url)
VALUES ($1, $2, $3) RETURNING id
```

### 5.3 ProfileResponse 新增 `has_password` `⬜`

```rust
pub struct ProfileResponse {
    // ... 现有字段保持不变 ...
    pub has_password: bool,   // 新增
}
```

### 5.4 重写 `get_profile()` — 从 DB 查询 `⬜`

```rust
pub async fn get_profile(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> Result<Json<ProfileResponse>, StatusCode> {
    // 1. 从 Header 提取 Bearer Token（保持现有逻辑）
    // 2. jwt::verify_token() 验证
    // 3. sqlx::query_as("SELECT ... FROM auth_users WHERE phone = $1") 查 DB
    // 4. has_password = !db_user.password_hash.is_empty()
    // 5. 返回 ProfileResponse
}
```

### 5.5 清理 import `⬜`

移除不再需要的 `use crate::state::User`，改为 `use crate::state::DbUser`。

---

## 任务 6：重构 `auth/password.rs` — 密码登录 + 新增设置/修改接口 `⬜ 待处理`

文件：`im-server/src/auth/password.rs`（修改）

### 6.1 重写 `PasswordLoginResponse` — 新增 `has_password` `⬜`

```rust
pub struct PasswordLoginResponse {
    // ... 现有字段保持不变 ...
    pub has_password: bool,   // 新增
}
```

### 6.2 重写 `login()` — 从 DB 查询 `⬜`

```rust
pub async fn login(
    State(state): State<Arc<AppState>>,
    Json(req): Json<PasswordLoginRequest>,
) -> Result<Json<PasswordLoginResponse>, StatusCode> {
    // 1. 校验 phone 和 password 非空（保持现有逻辑）
    // 2. sqlx::query_as("SELECT ... FROM auth_users WHERE phone = $1") 查 DB
    // 3. 用户不存在 → 返回错误
    // 4. bcrypt::verify(password, &db_user.password_hash) 校验
    // 5. has_password = true（密码登录必然已设密码）
    // 6. 签发 JWT，返回 PasswordLoginResponse
}
```

### 6.3 新增 `setup_password()` `⬜`

**请求/响应结构体**：

```rust
#[derive(Debug, Deserialize)]
pub struct SetupPasswordRequest {
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct SetupPasswordResponse {
    pub success: bool,
    pub message: String,
}
```

**处理函数签名**：

```rust
pub async fn setup_password(
    State(state): State<Arc<AppState>>,
    TypedHeader(auth): TypedHeader<Authorization<Bearer>>,
    Json(req): Json<SetupPasswordRequest>,
) -> Result<Json<SetupPasswordResponse>, StatusCode> {
    // 1. 校验 password.len() >= 6
    // 2. jwt::verify_token(auth.token()) 提取 user_id
    // 3. SELECT password_hash FROM auth_users WHERE id = $1
    // 4. 如果 password_hash != "" → 返回 "密码已设置，请使用修改密码接口"
    // 5. let hash = bcrypt::hash(password, bcrypt::DEFAULT_COST)
    // 6. UPDATE auth_users SET password_hash = $1, updated_at = NOW() WHERE id = $2
    // 7. 返回成功
}
```

> ⚠ 需要从 Header 提取 Bearer Token：使用 `axum::TypedHeader` + `axum::headers::authorization::Bearer`。如果当前 axum 0.5 不支持 `TypedHeader`，则沿用 `user.rs` 中 `get_profile()` 的方式手动解析 `authorization` header。

### 6.4 新增 `change_password()` `⬜`

**请求/响应结构体**：

```rust
#[derive(Debug, Deserialize)]
pub struct ChangePasswordRequest {
    pub old_password: String,
    pub new_password: String,
}

#[derive(Debug, Serialize)]
pub struct ChangePasswordResponse {
    pub success: bool,
    pub message: String,
}
```

**处理函数签名**：

```rust
pub async fn change_password(
    State(state): State<Arc<AppState>>,
    Json(req): Json<ChangePasswordRequest>,
) -> Result<Json<ChangePasswordResponse>, StatusCode> {
    // 1. 校验 new_password.len() >= 6
    // 2. jwt::verify_token() 提取 user_id
    // 3. SELECT password_hash FROM auth_users WHERE id = $1
    // 4. 如果 password_hash == "" → 返回 "请先设置密码"
    // 5. bcrypt::verify(old_password, &db_user.password_hash) → false → 返回 "原密码错误"
    // 6. let hash = bcrypt::hash(new_password, bcrypt::DEFAULT_COST)
    // 7. UPDATE auth_users SET password_hash = $1, updated_at = NOW() WHERE id = $2
    // 8. 返回成功
}
```

> `change_password` 需要从 Header 提取 Bearer Token，方式同 `setup_password`。

### 6.5 移除 `seed_users()` `⬜`

删除 `pub fn seed_users() -> HashMap<String, User>`。种子数据改为 SQL 迁移脚本管理（见任务 3.2）。

---

## 任务 7：更新 `auth/mod.rs` — 注册新路由 `⬜ 待处理`

文件：`im-server/src/auth/mod.rs`（修改）

### 7.1 新增 setup / change 路由 `⬜`

在 `routes()` 函数中追加：

```rust
pub fn routes() -> Router<Arc<AppState>> {
    Router::new()
        .route("/auth/sms", post(sms::send_sms))
        .route("/auth/login", post(user::login))
        .route("/auth/login/password", post(password::login))
        .route("/auth/password/setup", post(password::setup_password))    // 新增
        .route("/auth/password", put(password::change_password))           // 新增
        .route("/user/profile", get(user::get_profile))
}
```

> 注意 `put()` 路由需要确认 axum 0.5 是否已有 `axum::routing::put`，如没有则用 `axum::routing::patch` 或用 `.route("/auth/password", put(...))`。

### 7.2 更新 `use` 导入 `⬜`

````rust
use axum::routing::{get, post, put};  // 新增 put
````

---

## 任务 8：更新 `main.rs` — 初始化 PgPool `⬜ 待处理`

文件：`im-server/src/main.rs`（修改）

### 8.1 加载 `.env` 并创建连接池 `⬜`

在 `#[tokio::main]` 函数开头：

```rust
#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();
    dotenvy::dotenv().ok();                                    // 新增

    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");                   // 新增

    let pool = db::create_pool(&database_url).await;           // 新增
    db::run_migrations(&pool).await.expect("migrations failed"); // 新增

    let state = Arc::new(AppState::new(pool));                 // 修改：不再传 seed_users
    // ... 后续不变 ...
}
```

### 8.2 新增 `mod db` `⬜`

```rust
mod auth;
mod db;     // 新增
mod mock;
mod state;
mod util;
mod ws;
```

### 8.3 更新启动日志 `⬜`

```rust
tracing::info!("PostgreSQL: {}", database_url);
```

---

## 最后 — 验证 `⬜ 待处理`

- ⬜ 确认 `.env` 已由 `init.ps1` 生成，内容为 `DATABASE_URL=postgres://postgres:123456@localhost:5432/flash_im`
- ⬜ `cargo check` 无编译错误
- ⬜ `cargo run` 启动成功，日志输出 `PostgreSQL: postgres://...`
- ⬜ 用 curl 测试 `POST /auth/sms` → `POST /auth/login`，确认 `has_password` 字段存在
- ⬜ 用 curl 测试 `POST /auth/password/setup`（需带 Bearer Token）
- ⬜ 用 curl 测试 `PUT /auth/password`（需带 Bearer Token + 旧密码）
- ⬜ 用 `scripts\db\reset.ps1` 验证重建数据库流程正常
