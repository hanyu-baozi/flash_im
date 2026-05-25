# 关系型数据库调研报告

## 一、调研背景

当前 IM 后端认证系统所有数据均存储在内存中，服务重启后数据丢失。为支撑生产环境需求，需引入数据库持久化用户数据。本报告从功能、性能、生态、适用场景四个维度对比主流关系型数据库，为 Rust 即时通信后端项目提供选型建议。

## 二、候选数据库

| 数据库 | 类型 | 开源协议 | 最新版本 |
|--------|------|----------|----------|
| PostgreSQL | 关系型 | PostgreSQL License | 17.x |
| MySQL | 关系型 | GPL | 9.0.x |
| SQLite | 嵌入式关系型 | Public Domain | 3.47.x |

## 三、功能对比

### 3.1 数据类型与特性

| 特性 | PostgreSQL | MySQL | SQLite |
|------|------------|-------|--------|
| JSON 支持 | ✅ 原生 JSONB，支持索引和查询 | ✅ JSON 类型（5.7+） | ❌ 仅 TEXT 存储 |
| 数组类型 | ✅ 原生数组 | ❌ | ❌ |
| 全文检索 | ✅ 内置 | ✅ 内置 | ✅ 基础 |
| GIS 支持 | ✅ PostGIS 扩展 | ✅ 基础支持 | ❌ |
| 窗口函数 | ✅ 完整支持 | ✅ 8.0+ 支持 | ✅ 3.25+ |
| CTE（公共表表达式） | ✅ 递归 CTE | ✅ 8.0+ | ✅ 3.8.3+ |
| 自定义类型 | ✅ 丰富 | ⚠️ 有限 | ❌ |
| 事务隔离级别 | 4 种完整 | 4 种完整 | 仅 SERIALIZABLE |
| 外键约束 | ✅ 完整 | ✅ InnoDB 支持 | ✅ |

### 3.2 并发与锁机制

| 特性 | PostgreSQL | MySQL | SQLite |
|------|------------|-------|--------|
| MVCC | ✅ 完整实现 | ✅ InnoDB 实现 | ⚠️ 有限 |
| 行级锁 | ✅ | ✅ InnoDB | ❌ 表级锁 |
| 读写并发 | ✅ 读写不阻塞 | ✅ 读写不阻塞 | ❌ 写操作阻塞所有读 |
| 连接池 | ✅ 内置 + 外部 | ✅ 外部 | ❌ 无需 |

## 四、性能对比

### 4.1 基准性能指标

| 场景 | PostgreSQL | MySQL | SQLite |
|------|------------|-------|--------|
| 简单查询（单表） | 快 | 快 | 极快（无网络开销） |
| 复杂查询（多表 JOIN） | 极快（优化器强） | 快 | 中等 |
| 写入性能 | 高 | 高 | 中等（单写者限制） |
| 高并发读 | 优秀 | 优秀 | 受限 |
| 高并发写 | 优秀 | 优秀 | 差 |
| 大数据量（千万级） | 优秀 | 优秀 | 不推荐 |

### 4.2 性能特点

**PostgreSQL**
- 查询优化器最成熟，复杂查询性能最佳
- 支持并行查询（Parallel Query）
- 连接开销较大，建议配合连接池（PgBouncer）

**MySQL**
- 简单查询性能优异
- InnoDB 缓冲池优化成熟
- 主从复制延迟低，读扩展容易

**SQLite**
- 零网络延迟，本地访问极快
- 写入吞吐量受限于单写者模型
- 适合读多写少场景

## 五、Rust 生态对比

### 5.1 主流 ORM/驱动

| 数据库 | 驱动 | ORM 支持 | 异步支持 |
|--------|------|----------|----------|
| PostgreSQL | `tokio-postgres`, `postgres` | SQLx, SeaORM, Diesel | ✅ 优秀 |
| MySQL | `mysql_async`, `mysql` | SQLx, SeaORM, Diesel | ✅ 优秀 |
| SQLite | `rusqlite`, `sqlx` | SQLx, SeaORM, Diesel | ✅ 良好 |

### 5.2 SQLx 支持情况

| 特性 | PostgreSQL | MySQL | SQLite |
|------|------------|-------|--------|
| 编译时查询检查 | ✅ | ✅ | ✅ |
| 连接池 | ✅ | ✅ | ✅ |
| 事务 | ✅ | ✅ | ✅ |
| 迁移工具 | ✅ | ✅ | ✅ |

### 5.3 SeaORM 支持情况

| 特性 | PostgreSQL | MySQL | SQLite |
|------|------------|-------|--------|
| 完整支持 | ✅ | ✅ | ✅ |
| 实体生成 | ✅ | ✅ | ✅ |
| 关系查询 | ✅ | ✅ | ✅ |

## 六、适用场景分析

### 6.1 PostgreSQL

**适合场景：**
- 复杂业务逻辑，需要高级查询能力
- 对数据一致性要求极高
- 需要 JSON 存储和查询（如用户配置、消息元数据）
- 未来可能扩展到 GIS、全文检索等场景
- 团队有 PostgreSQL 运维经验

**不适合场景：**
- 资源受限环境（内存占用较高）
- 超简单 CRUD 应用（过度设计）

### 6.2 MySQL

**适合场景：**
- 互联网应用，读多写少
- 需要主从复制、分库分表
- 团队熟悉 MySQL 生态
- 云数据库服务选择多

**不适合场景：**
- 需要复杂查询和高级数据类型
- 对事务隔离级别有严格要求

### 6.3 SQLite

**适合场景：**
- 嵌入式设备、移动端应用
- 单机应用、本地缓存
- 开发和测试环境
- 读多写少的小型应用

**不适合场景：**
- 高并发写入场景
- 多进程并发访问
- 需要远程访问的服务端应用

## 七、IM 项目需求匹配

### 7.1 当前项目需求

| 需求 | 优先级 | 说明 |
|------|--------|------|
| 用户数据持久化 | 高 | 账号、密码、昵称、头像 |
| 会话记录 | 高 | 聊天记录、离线消息 |
| 高并发读写 | 中 | 消息收发、在线状态 |
| JSON 存储 | 中 | 用户配置、扩展字段 |
| 事务支持 | 高 | 用户注册、消息发送 |

### 7.2 推荐方案

**首选：PostgreSQL**

理由：
1. **功能最全面**：JSONB 类型适合存储消息元数据、用户配置
2. **Rust 生态优秀**：SQLx + SeaORM 提供编译时检查和类型安全
3. **并发性能强**：MVCC 实现完善，适合 IM 高并发场景
4. **扩展性好**：未来可扩展到消息队列、全文检索等
5. **数据类型丰富**：数组类型适合存储标签、好友列表等

**备选：MySQL**

理由：
1. 团队熟悉度高，运维成本低
2. 云服务商支持广泛
3. 性能稳定，社区活跃

**不推荐：SQLite**

理由：
1. 单写者模型不适合 IM 高并发写入
2. 无法支持多实例部署
3. 仅适合开发测试环境

## 八、实施建议

### 8.1 技术栈推荐

```
数据库：PostgreSQL 16+
驱动：tokio-postgres（异步）
ORM：SQLx（编译时检查）或 SeaORM（Active Record 风格）
连接池：内置连接池或 PgBouncer
迁移：SQLx migrate 或 SeaORM CLI
```

### 8.2 表结构设计建议

```sql
-- 用户表
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nickname VARCHAR(50),
    avatar_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 会话表
CREATE TABLE conversations (
    id SERIAL PRIMARY KEY,
    type VARCHAR(20) NOT NULL, -- 'single' | 'group'
    created_at TIMESTAMP DEFAULT NOW()
);

-- 消息表
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    conversation_id INT REFERENCES conversations(id),
    sender_id INT REFERENCES users(id),
    content TEXT NOT NULL,
    msg_type VARCHAR(20) DEFAULT 'text',
    metadata JSONB, -- 扩展字段
    created_at TIMESTAMP DEFAULT NOW()
);

-- 在线状态表
CREATE TABLE user_sessions (
    user_id INT REFERENCES users(id),
    device_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'online',
    last_active TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, device_id)
);
```

### 8.3 迁移步骤

1. **引入依赖**：添加 `sqlx`、`sea-orm` 到 `Cargo.toml`
2. **配置连接**：在 `state.rs` 中添加数据库连接池
3. **定义实体**：使用 SeaORM 或手写结构体
4. **编写迁移**：使用 SQLx migrate 创建迁移文件
5. **替换内存存储**：逐步将内存操作改为数据库操作
6. **测试验证**：编写集成测试验证数据持久化

## 九、总结

| 维度 | PostgreSQL | MySQL | SQLite |
|------|------------|-------|--------|
| 功能丰富度 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| 性能 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Rust 生态 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 运维复杂度 | 中 | 低 | 极低 |
| IM 场景匹配度 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |

**最终建议：选择 PostgreSQL 作为 IM 后端数据库。**
