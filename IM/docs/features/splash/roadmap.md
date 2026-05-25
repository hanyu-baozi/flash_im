# 应用启动 — 演进路线

## v1.0（当前版本）

- [ ] Client: 启动页（Logo + "Flash IM" + 最小 1.5s 展示）
- [ ] Client: 读取 SharedPreferences Token 判断登录状态
- [ ] Client: 根据状态分流 → LoginPage / MainPage
- [ ] Client: 重写 main.dart 入口

## 后续版本

| 版本 | 方向 | 说明 |
|------|------|------|
| v1.1 | Token 远程校验 | 启动期请求 /user/profile 验证 Token 有效性 |
| v1.2 | 启动运营图 | 服务端下发广告/活动图替换静态 Logo |
| v1.3 | 引导页 | 首次安装展示 Onboarding |
| v2.0 | 启动优化 | 缩短白屏时间、骨架屏、预加载资源 |
