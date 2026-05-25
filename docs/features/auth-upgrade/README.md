# 认证系统升级

## 是什么

升级现有 Playground 认证系统，从内存存储迁移至 PostgreSQL，新增密码设置与修改能力。

## 管什么

- **Server**：PostgreSQL 持久化用户数据、bcrypt 密码哈希、密码设置/修改接口
- **Client**：登录后引导设置密码、个人中心修改密码入口
