# POST /auth/login - 验证码登录

## 接口说明

- **URL**: `http://localhost:3000/auth/login`
- **Method**: POST
- **Content-Type**: application/json
- **说明**: 使用手机号 + 验证码登录，登录即注册。手机号不存在时自动注册新用户，默认用户名为手机号

## 请求参数

| 字段  | 类型   | 必填 | 说明                                 |
| ----- | ------ | ---- | ------------------------------------ |
| phone | string | 是   | 手机号码                             |
| code  | string | 是   | 六位验证码（通过 /auth/sms 获取）     |

## Curl 命令

```bash
# 第一步：获取验证码
curl -X POST http://localhost:3000/auth/sms \
  -H "Content-Type: application/json" \
  -d '{"phone": "13800000001"}'

# 第二步：使用返回的验证码登录（以 290739 为例）
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone": "13800000001", "code": "290739"}'
```

## 实际测试结果

- **测试时间**: 2026-05-07 09:31
- **测试状态**: 通过

### 请求

```json
{
  "phone": "13800000001",
  "code": "290739"
}
```

### 响应 (200 OK)

```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJwaG9uZSI6IjEzODAwMDAwMDAxIiwiaWF0IjoxNzc4MTE3NDY1LCJleHAiOjE3NzgxMjQ2NjV9.oRACEZYF1pDxC5E5Zo9odDrbUX2Vg0VKdWqjWBDbDZE",
  "user_id": 1
}
```

### JWT Token 解码内容

```json
{
  "user_id": 1,
  "phone": "13800000001",
  "iat": 1778117465,
  "exp": 1778124665
}
```

## 测试结论

接口正常工作：
1. 验证码校验通过后成功签发 JWT Token
2. Token 有效期为 2 小时（JWT_EXPIRES_IN = '2h'）
3. 首次登录的手机号自动注册为新用户，返回 `user_id: 1`
4. 用户昵称默认为手机号
5. 响应结构符合预期，`success` 为 `true`
