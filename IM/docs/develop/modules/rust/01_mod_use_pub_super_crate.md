# Rust 模块系统 — 文件拆分与导入

## 1. `mod` — 声明模块

`mod` 有两种用法：

### 1.1 内联模块（写在同一个文件里）

```rust
mod math {
    pub fn add(a: i32, b: i32) -> i32 {
        a + b
    }
}

fn main() {
    let sum = math::add(1, 2);  // 模块名::函数名
}
```

### 1.2 文件模块（拆到独立文件）

```
src/
├── main.rs
└── math.rs        # mod math;
```

在 `main.rs` 中只需要一行声明，Rust 会自动找到 `math.rs`：

```rust
// main.rs
mod math;          // 告诉编译器：有一个叫 math 的模块，去 math.rs 找

fn main() {
    math::add(1, 2);
}
```

### 1.3 目录模块（子模块嵌套）

```
src/
├── main.rs
└── auth/
    ├── mod.rs     # 模块入口（module root）
    ├── jwt.rs
    └── sms.rs
```

`mod.rs` 内部声明子模块：

```rust
// auth/mod.rs
pub mod jwt;       // 声明子模块，编译器找 auth/jwt.rs
pub mod sms;       // 声明子模块，编译器找 auth/sms.rs
```

`main.rs` 中声明顶层模块：

```rust
// main.rs
mod auth;          // 编译器找 auth/mod.rs

fn main() {
    let token = auth::jwt::create_token(1, "13800138000");
}
```

## 2. `pub` — 控制可见性

Rust 中**默认一切都是私有的**。外部模块/外部 crate 看不到未标记 `pub` 的项。

| 写法 | 可见范围 |
|------|----------|
| （不加 pub）| 仅当前模块 |
| `pub` | 任何地方都能访问 |
| `pub(crate)` | 当前 crate 内可见，外部 crate 不可见 |
| `pub(super)` | 仅父模块可见 |
| `pub(in crate::auth)` | 仅 `auth` 模块内可见 |

```rust
// auth/jwt.rs
pub const JWT_SECRET: &str = "xxx";  // 外部可访问
fn internal_helper() { }              // 仅 jwt.rs 内部可用

pub fn create_token(...) { }          // 外部可调用
```

## 3. `use` — 导入路径

`use` 用于缩短路径，避免每次写完整的模块路径：

```rust
// 不用 use：
let claims = crate::auth::jwt::verify_token(token)?;

// 用 use：
use crate::auth::jwt::verify_token;
let claims = verify_token(token)?;

// 用 use + 别名：
use crate::auth::jwt as j;
let claims = j::verify_token(token)?;
```

## 4. `crate` 与 `super` — 路径起点

### 4.1 绝对路径：`crate::`

`crate` 指向**当前 crate 的根**（即 `main.rs` 或 `lib.rs` 所在位置）：

```rust
// 无论在哪个文件中，crate:: 都能从根出发
use crate::state::AppState;          // → src/state.rs
use crate::auth::jwt::create_token;  // → src/auth/jwt.rs
use crate::ws::echo;                 // → src/ws/echo.rs
```

### 4.2 相对路径：`super::`

`super` 指向**当前模块的父模块**：

```rust
// 文件：src/auth/jwt.rs  （父模块是 auth）
use super::sms;                // → src/auth/sms.rs

// 文件：src/ws/echo.rs  （父模块是 ws）
use super::chat_room;          // → src/ws/chat_room.rs
```

### 4.3 对比

```
src/auth/user.rs 中：
  crate::state::AppState     → 从根出发，到 src/state.rs
  crate::auth::jwt::verify_token → 从根出发，到 src/auth/jwt.rs
  super::jwt::verify_token   → 上一级（auth），再到 jwt.rs
```

## 5. 本项目模块树

```
src/
├── main.rs          ──┬──  crate::main
├── state.rs         ──┤──  crate::state::AppState
├── auth/
│   ├── mod.rs       ──┤──  crate::auth::routes()
│   ├── jwt.rs       ──┤──  crate::auth::jwt::create_token()
│   ├── sms.rs       ──┤──  crate::auth::sms::send_sms()
│   └── user.rs      ──┤──  crate::auth::user::login()
├── ws/
│   ├── mod.rs       ──┤──  crate::ws::routes()
│   ├── echo.rs      ──┤──  crate::ws::echo::handler()
│   └── chat_room.rs ──┤──  crate::ws::chat_room::handler()
├── mock/
│   └── mod.rs       ──┤──  crate::mock::get_conversations()
└── util/
    └── mod.rs       ──┘──  crate::util::get_local_ip()
```

## 6. 要点总结

| 关键字 | 作用 | 例子 |
|--------|------|------|
| `mod` | 声明模块存在 | `mod auth;` → 找 `auth/mod.rs` |
| `pub` | 标记为公开可见 | `pub fn login()` |
| `use` | 导入路径，缩短调用 | `use crate::auth::jwt;` |
| `crate::` | 从根开始的绝对路径 | `crate::state::AppState` |
| `super::` | 从父模块开始的相对路径 | `super::sms` |
| `self::` | 从当前模块开始 | `self::helper()` |
