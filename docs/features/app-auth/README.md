# 登录认证 + 主框架

## 是什么

Flash IM 正式 App 的核心入口模块。提供简约风格的登录认证（手机号验证码 / 密码登录）、密码设置引导弹窗、底部三 Tab 主框架（消息 / 通讯录 / 我的）、以及个人信息展示与退出登录。

使用 Bloc 的 Cubit 进行状态管理，与 Playground 的 ChangeNotifier 方案并存。

## 管什么

- **Client**：登录页 UI、密码设置弹窗、底部 Tab 主框架、我的页面、认证状态管理（Cubit）、Token 持久化