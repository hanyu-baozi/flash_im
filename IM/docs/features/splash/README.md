# 应用启动

## 是什么

Flash IM 的应用启动（Splash）模块，负责品牌展示 + 本地数据初始化 + 根据登录状态分流。

## 管什么

- **Client**：Logo 品牌展示页 → 异步读 SharedPreferences → 跳转登录页或主页
