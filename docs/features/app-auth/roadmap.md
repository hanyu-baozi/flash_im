# 登录认证 + 主框架 — 演进路线

## v1.0（当前版本）

- [ ] Client: mixin + 模式子类状态管理（LoginLogic + _SmsMode / _PasswordMode）
- [ ] Client: 简约风格登录页（验证码 / 密码两种模式切换）
- [ ] Client: 密码设置弹窗（AlertDialog，支持「暂不设置」）
- [ ] Client: Token 持久化（SharedPreferences，与 Splash 握手）
- [ ] Client: 底部三 Tab 主框架（IndexedStack）
- [ ] Client: 消息 / 通讯录 Tab 留白占位
- [ ] Client: 「我的」页面（参考 Playground 风格，含退出登录）
- [ ] Client: 替换 Splash 模块的 LoginPage / HomePage 占位

## 后续版本

| 版本 | 方向 | 说明 |
|------|------|------|
| v1.1 | 修改密码 | 在「我的」页面新增修改密码入口 + 修改密码页面 |
| v1.2 | 图形验证码 | 发送验证码前增加滑块/图形验证，防刷 |
| v2.0 | 忘记密码 / 重置 | 短信验证码重置密码完整流程 |
| v2.1 | 第三方登录 | 微信 / Apple OAuth 登录 |