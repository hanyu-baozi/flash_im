# GET /user/profile - 获取用户信息

## 接口说明

- **URL**: `http://localhost:3000/user/profile`
- **Method**: GET
- **Authorization**: Bearer Token（通过 /auth/login 获取）
- **说明**: 获取当前登录用户的个人信息，需要在请求头中携带 JWT Token

## 请求头

| 字段          | 值                          | 说明              |
| ------------- | --------------------------- | ----------------- |
| Authorization | Bearer \<token\>            | 登录时获取的 JWT  |

## Curl 命令

```bash
curl -X GET http://localhost:3000/user/profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJwaG9uZSI6IjEzODAwMDAwMDAxIiwiaWF0IjoxNzc4MTE3NDY1LCJleHAiOjE3NzgxMjQ2NjV9.oRACEZYF1pDxC5E5Zo9odDrbUX2Vg0VKdWqjWBDbDZE"
```

## 实际测试结果

- **测试时间**: 2026-05-07 09:31
- **测试状态**: 通过

### 请求头

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJwaG9uZSI6IjEzODAwMDAwMDAxIiwiaWF0IjoxNzc4MTE3NDY1LCJleHAiOjE3NzgxMjQ2NjV9.oRACEZYF1pDxC5E5Zo9odDrbUX2Vg0VKdWqjWBDbDZE
```

### 响应 (200 OK)

```json
{
  "success": true,
  "user_id": 1,
  "nickname": "13800000001",
  "avatar": "https://api.dicebear.com/7.x/identicon/svg?seed=13800000001",
  "phone": "13800000001"
}
```

## 响应字段说明

| 字段     | 类型   | 说明                              |
| -------- | ------ | --------------------------------- |
| success  | bool   | 请求是否成功                      |
| user_id  | number | 用户 ID                           |
| nickname | string | 用户昵称（默认为手机号）           |
| avatar   | string | 用户头像 URL（基于 DiceBear 生成） |
| phone    | string | 用户手机号                        |

## 测试结论

接口正常工作：
1. 携带有效 JWT Token 后成功返回用户信息
2. 返回字段完整：user_id、nickname、avatar、phone
3. 头像使用 DiceBear Identicon 根据手机号生成
4. 昵称默认为手机号，与注册时一致
