# 认证系统升级 — 演进路线

## v1.0（当前版本）

- [x] Service: 引入 PostgreSQL + sqlx，替代 HashMap 存储
- [x] Service: bcrypt 密码哈希替代 simple_hash
- [x] Service: `POST /auth/password/setup` 设置初始密码
- [x] Service: `PUT /auth/password` 修改密码
- [x] Service: 登录/Profile 响应新增 `has_password` 字段
- [x] Client: `LoginResponse` / `UserProfile` 新增 `hasPassword`
- [x] Client: 短信登录后引导设置密码
- [x] Client: 个人中心新增修改密码入口

## 后续版本

| 版本 | 方向 | 说明 |
|------|------|------|
| v1.1 | 验证码迁移 Redis | 验证码从内存 HashMap 迁移至 Redis |
| v1.2 | 密码强度策略 | 增加大小写+特殊符号要求 |
| v2.0 | 忘记密码 / 重置 | 短信验证码重置密码流程 |
