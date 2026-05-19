# POST /auth/sms - 发送验证码

## 接口说明

- **URL**: `http://localhost:3000/auth/sms`
- **Method**: POST
- **Content-Type**: application/json
- **说明**: 发送短信验证码（模拟），Playground 阶段直接在响应中返回六位随机验证码

## 请求参数

| 字段  | 类型   | 必填 | 说明     |
| ----- | ------ | ---- | -------- |
| phone | string | 是   | 手机号码 |

## Curl 命令

```bash
curl -X POST http://localhost:3000/auth/sms \
  -H "Content-Type: application/json" \
  -d '{"phone": "13800000001"}'
```

## 实际测试结果

- **测试时间**: 2026-05-07 09:31
- **测试状态**: 通过

### 请求

```json
{
  "phone": "13800000001"
}
```

### 响应 (200 OK)

```json
{
  "success": true,
  "message": "验证码已发送",
  "code": "825249"
}
```

## 测试结论

接口正常工作：
1. 成功接收手机号参数
2. 返回六位随机数字验证码
3. 响应结构符合预期，`success` 为 `true`
4. Playground 阶段验证码直接返回在响应体中，方便开发调试
