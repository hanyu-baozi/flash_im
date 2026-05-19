# IM 后端服务技术文档

## 项目简介

这是一个基于 Rust 语言和 axum 框架开发的后端服务，提供了一个简单的系统信息查询接口。

## 技术栈

- **语言**: Rust 1.95.0
- **框架**: axum 0.6
- **运行时**: Tokio
- **序列化**: Serde

## 项目结构

```
IM/
├── src/
│   └── main.rs      # 主程序入口
├── docs/
│   └── develop/
│       └── version/
│           └── v.md  # 技术文档
├── Cargo.toml       # 项目配置和依赖管理
└── .gitignore       # Git 忽略文件配置
```

## 功能说明

### 提供的接口

- **GET /v** - 返回系统信息，包含 name 和 version 字段

### 接口返回示例

```json
{
  "name": "IM Server",
  "version": "0.1.0"
}
```

## 代码解析

### 1. 依赖管理

在 `Cargo.toml` 文件中，我们添加了以下依赖：

```toml
axum = "0.6"          # Web 框架
tokio = { version = "1", features = ["full"] }  # 异步运行时
serde = { version = "1", features = ["derive"] }  # 序列化库
```

### 2. 主程序结构

在 `src/main.rs` 文件中：

1. **导入必要的库**
   ```rust
   use axum::{extract::State, http::StatusCode, routing::get, Json, Router};
   use serde::Serialize;
   use std::net::{IpAddr, Ipv4Addr, SocketAddr};
   ```

2. **定义数据结构**
   - `SystemInfo`: 用于返回系统信息的结构体
   - `AppState`: 应用状态，包含系统名称和版本

3. **处理函数**
   - `get_system_info`: 处理 `/v` 接口请求，返回系统信息

4. **辅助函数**
   - `get_local_ip`: 获取本地 IP 地址（简化为 127.0.0.1）

5. **主函数**
   - 初始化应用状态
   - 创建路由
   - 绑定地址并启动服务器
   - 打印服务器启动信息

## 如何运行

1. **安装 Rust**
   如果还没有安装 Rust，请访问 [rust-lang.org](https://www.rust-lang.org/) 下载并安装。

2. **进入项目目录**
   ```bash
   cd IM
   ```

3. **构建项目**
   ```bash
   cargo build
   ```

4. **运行服务**
   ```bash
   cargo run
   ```

5. **查看服务器输出**
   服务启动后，会在终端输出类似以下信息：
   ```
   Server starting on http://127.0.0.1:3000
   You can access the system info at http://127.0.0.1:3000/v
   ```

## 如何测试接口

### 使用浏览器测试

1. 打开浏览器
2. 访问 `http://127.0.0.1:3000/v`
3. 浏览器会显示 JSON 格式的系统信息

### 使用 curl 测试

在终端中执行：

```bash
curl http://127.0.0.1:3000/v
```

返回结果：

```json
{"name":"IM Server","version":"0.1.0"}
```

## 常见问题

### 服务启动失败

- 检查端口 3000 是否已被占用
- 确保 Rust 环境配置正确
- 检查依赖是否正确安装

### 接口返回错误

- 确保服务正在运行
- 检查 URL 是否正确
- 查看终端输出的错误信息

## 后续扩展

- 可以添加更多接口
- 可以实现数据库连接
- 可以添加身份验证
- 可以配置不同的环境变量

## 总结

这个项目是一个使用 axum 框架创建的简单后端服务，提供了系统信息查询接口。通过这个项目，你可以了解如何：

1. 创建 Rust 项目并添加依赖
2. 使用 axum 框架构建 Web 服务
3. 定义路由和处理函数
4. 处理异步请求
5. 返回 JSON 格式的数据

希望这个文档对你有所帮助！
