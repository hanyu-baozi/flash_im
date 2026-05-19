# 用户认证系统概述

> 面向即时通信产品的认证基础知识梳理，帮助团队建立统一认知。

---

## 1. 认证 vs 授权 —— 先分清两件事

| | 认证 (Authentication) | 授权 (Authorization) |
|---|---|---|
| **回答的问题** | 你是谁？ | 你能做什么？ |
| **生活类比** | 进小区要刷门禁卡 | 门禁卡只能开 A 栋，开不了 B 栋 |
| **技术举例** | 登录验证账号密码 | 检查用户是否是群管理员 |
| **简称** | AuthN | AuthZ |

> 本文聚焦 **认证（AuthN）**，授权在后续文档中展开。

---

## 2. 认证的核心流程

一次完整的登录认证，本质是 **"提交凭证 → 服务端验证 → 颁发令牌 → 持续使用 → 过期/注销 → 重新登录"** 的闭环：

```mermaid
graph TB
  A["用户提交凭证"] --> B["登录"]
  B -->|"验证通过"| C["签发Token"]
  B -->|"验证失败"| D["拒绝"]
  D --> E["需要重新登录"]
  C --> F["客户端保存Token"]
  F --> G["使用中"]
  G -->|"每次请求携带Token"| G
  G -->|"超过exp时间"| H["已过期"]
  G -->|"用户主动退出"| I["已注销"]
  H --> E
  I --> E
```

---

## 3. 常见认证方式

### 3.1 账号密码登录

最经典的方式，无需赘述。

**优点**：简单直接，用户熟悉
**缺点**：密码可能泄露、弱密码、撞库攻击

### 3.2 手机号 + 验证码（SMS OTP）

```mermaid
sequenceDiagram
  participant U as 用户
  participant App as 客户端
  participant S as 服务端
  participant SMS as 短信网关

  U->>App: 输入手机号
  App->>S: 请求发送验证码
  S->>SMS: 调用短信 API
  SMS-->>U: 收到6位验证码
  U->>App: 填写验证码
  App->>S: 提交手机号 + 验证码
  S-->>App: 验证通过，返回 Token
```

**优点**：无需记忆密码、验证手机号真实性
**缺点**：依赖短信通道、有送达延迟、短信成本

### 3.3 第三方 OAuth 登录

用微信、Google 等已有账号登录，不用再注册新密码。

```mermaid
sequenceDiagram
  participant U as 用户
  participant App as 客户端
  participant S as 我方服务端
  participant W as 第三方-微信等

  U->>App: 点击微信登录
  App->>S: 请求微信登录URL
  S-->>App: 返回带redirect_uri的授权URL
  App->>W: 打开WebView跳转授权页
  U->>W: 确认授权
  W-->>S: 回调redirect_uri并携带code
  S->>W: 用code+appSecret换access_token
  W-->>S: 返回access_token+用户openid等信息
  S-->>App: 我方Token-绑定或新建本地账号
```

**优点**：用户零注册成本、安全性由第三方保障
**缺点**：依赖第三方可用性、用户数据受平台政策限制

### 3.4 方式对比

| | 账号密码 | 短信验证码 | OAuth 第三方 |
|---|---|---|---|
| **用户门槛** | 需记密码 | 只需手机号 | 最省事 |
| **安全等级** | 中（依赖密码强度） | 中高（依赖手机安全） | 高（第三方风控） |
| **实现成本** | 低 | 中（短信费用） | 中（对接 SDK） |
| **适合场景** | 基础登录 | 手机号注册体系 | 快速拉新 |

> 💡 **IM 产品推荐组合**：手机号验证码为主 + OAuth 为辅。手机号天然是 IM 的身份标识。

---

## 4. Token 机制 —— 认证的核心产物

登录成功后，服务端颁发一个 **Token（令牌）**，客户端后续请求都带着它。

### 4.1 两种主流 Token 方案

| | Session + Cookie | JWT（JSON Web Token） |
|---|---|---|
| **存储位置** | 服务端存 Session，客户端存 Session ID | 客户端存 Token，服务端不存状态 |
| **状态** | 有状态（Stateful） | 无状态（Stateless） |
| **扩展性** | 难跨服务共享 Session | 天然支持分布式 |
| **即时吊销** | 容易（删 Session 即可） | 较难（需额外黑名单机制） |
| **适合** | 传统 Web 单体 | 移动端 / 微服务 / IM |

> 💡 **IM 场景选 JWT**：移动端天然无 Cookie，且 IM 后端通常微服务化，JWT 更合适。

### 4.2 JWT 长什么样？

JWT 由三段 Base64 编码拼接而成：

```
eyJhbGciOiJIUzI1NiJ9.eyJ1aWQiOjEyMywiZXhwIjoxNzAwMDAwMDAwfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
│                    │                                    │
│  Header（算法）     │  Payload（载荷：uid, exp等声明）     │  Signature（签名，防篡改）
```

- **Header**：声明签名算法（如 HS256）和令牌类型（typ: JWT）
- **Payload**：存放声明（Claims），如 `uid`（用户标识）、`exp`（过期时间戳），**不要放密码等敏感信息**
- **Signature**：用密钥对前两段签名，任何篡改都会导致签名校验失败

### 4.3 Token 的生命周期

```mermaid
stateDiagram
  [*] --> 颁发: 登录成功
  颁发 --> 有效: 在有效期内
  有效 --> 过期: exp到期
  有效 --> 刷新: 用refreshToken换新
  刷新 --> 有效: 获得新accessToken
  过期 --> 刷新: refreshToken仍有效
  过期 --> 重新登录: refreshToken也过期
  有效 --> 吊销: 主动登出或安全事件
  吊销 --> 重新登录
  重新登录 --> 颁发
```

### 4.4 双 Token 设计（Access + Refresh）

IM 产品推荐使用 **双 Token** 方案：

| | Access Token | Refresh Token |
|---|---|---|
| **有效期** | 短（15 分钟 ~ 2 小时） | 长（7 天 ~ 30 天） |
| **用途** | 每次请求携带 | 仅用于刷新 Access Token |
| **泄露风险** | 时间窗口小 | 需要额外保护 |
| **存储** | 内存（App 运行时） | 安全存储（Keychain / Keystore） |

```mermaid
sequenceDiagram
  participant U as 用户
  participant App as 客户端
  participant S as 服务端

  U->>S: 登录
  S-->>App: accessToken短期 + refreshToken长期

  Note over App,S: 正常使用带accessToken

  App->>S: 业务请求 + accessToken
  S-->>App: 正常返回数据

  Note over App,S: accessToken过期

  App->>S: 业务请求 + 过期accessToken
  S-->>App: 401 Token过期

  App->>S: 用refreshToken请求刷新
  S-->>App: 新accessToken + 新refreshToken

  Note over App,S: 无感刷新用户无感知
```

> 💡 **为什么 IM 必须双 Token？** 用户不会频繁主动登录，但 Access Token 必须短有效期来降低泄露风险。双 Token 让安全性和体验兼得。

---

## 5. IM 场景的特殊认证需求

即时通信产品有一些区别于普通 Web 应用的认证特点：

### 5.1 长连接认证

IM 的 WebSocket 连接是持久的，不像 HTTP 请求每次都带 Token。

```mermaid
sequenceDiagram
  participant App as 客户端
  participant S as IM服务端

  Note over App,S: 1.先HTTP登录获取Token
  App->>S: HTTP POST /login
  S-->>App: Token

  Note over App,S: 2.用Token建立WebSocket
  App->>S: WS连接 ws://server/ws?token=xxx
  S->>S: 验证Token
  S-->>App: 连接成功

  Note over App,S: 3.连接期间Token过期怎么办
  App->>S: WS发送 refresh_token请求
  S-->>App: WS返回新Token
```

**关键问题**：
- WS 连接建立时验证 Token，之后连接保持，Token 过期怎么办？
- **方案 A**：连接层不校验过期，由业务层拦截 → 简单但有窗口期
- **方案 B**：服务端定时检查，过期主动断开 → 安全但体验差
- **方案 C**：客户端在 Token 快过期时通过 WS 主动刷新 → **推荐**

### 5.2 多端登录与互踢

IM 用户可能在手机、平板、PC 同时在线，需要策略：

| 策略 | 说明 | 典型产品 |
|---|---|---|
| **单端登录** | 同一平台只允许一个设备 | 早期微信 |
| **多端共存** | 手机 + PC 可同时在线 | 现在的微信 |
| **互踢** | 新设备登录，旧设备被踢下线 | WhatsApp |

```mermaid
sequenceDiagram
  participant Phone1 as 手机A
  participant S as 服务端
  participant Phone2 as 手机B

  Phone1->>S: 登录-设备A
  S-->>Phone1: Token_A

  Phone2->>S: 登录-设备B同账号
  S->>S: 检测到同平台已有连接
  S-->>Phone1: 被踢下线通知
  S-->>Phone2: Token_B
```

### 5.3 离线消息与认证恢复

IM 断网重连后需要拉取离线消息，此时需要：

```mermaid
graph TD
  A["网络断开"] --> B["自动重连"]
  B -->|"Token仍有效"| C["拉取离线消息"]
  B -->|"Token过期"| D["用refreshToken刷新"]
  D -->|"刷新成功"| C
  D -->|"refreshToken也过期"| E["跳转登录页"]
```

---

## 6. 安全要点速查

| 威胁 | 防御措施 |
|---|---|
| **密码泄露** | 加盐哈希存储（bcrypt / argon2）、登录失败限频 |
| **Token 被盗** | 短有效期 + HTTPS 传输 + 安全存储 |
| **重放攻击** | Token 加入 `jti`（唯一 ID）+ 时间戳 |
| **中间人攻击** | 全链路 HTTPS / WSS |
| **暴力破解** | 验证码 + 限频 + 账号锁定 |
| **Token 无法即时吊销** | 维护黑名单（Redis），或短有效期 + 刷新机制 |

---

## 7. 认证技术选型建议（IM 产品）

```mermaid
graph TB
  subgraph 推荐方案
    A["登录方式: 手机验证码为主+OAuth为辅"]
    B["Token方案: JWT双Token-Access+Refresh"]
    C["长连接认证: WS握手带Token+自动刷新"]
    D["多端策略: 多端共存+同平台互踢"]
    E["安全: HTTPS/WSS+bcrypt+限频+黑名单"]
  end
  A --> B --> C --> D --> E
```

---

## 8. 关键术语速查表

| 术语 | 全称 | 一句话解释 |
|---|---|---|
| **JWT** | JSON Web Token | 一种自包含的令牌格式，里面存了用户信息+签名 |
| **Access Token** | — | 短期令牌，每次请求带着它证明身份 |
| **Refresh Token** | — | 长期令牌，只用来换新的 Access Token |
| **OAuth 2.0** | Open Authorization 2.0 | 用第三方账号登录的行业标准协议 |
| **OTP** | One-Time Password | 一次性密码，如短信验证码 |
| **bcrypt** | — | 一种密码哈希算法，自带加盐和慢速计算 |
| **WSS** | WebSocket Secure | 加密版 WebSocket，相当于 HTTPS 之于 HTTP |
