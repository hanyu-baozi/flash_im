
const express = require('express');
const cors = require('cors');
const WebSocket = require('ws');
const jwt = require('jsonwebtoken');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  console.log(`[HTTP] ${req.method} ${req.url}`);
  next();
});

const conversations = [
  {
    id: "1",
    title: "壹贰叁 （备注学校，会统一通…",
    lastMsg: "已被接收",
    time: "3月16日",
    unreadCount: 0,
    type: "single",
    messageType: "transfer",
    isMuted: false
  },
  {
    id: "2",
    title: "付总",
    lastMsg: "我之前退了",
    time: "3月14日",
    unreadCount: 0,
    type: "single",
    messageType: "text",
    isMuted: false
  },
  {
    id: "3",
    title: "鸭子🦆 (6.21)",
    lastMsg: "嗯",
    time: "3月13日",
    unreadCount: 0,
    type: "single",
    messageType: "sticker",
    isMuted: false
  },
  {
    id: "4",
    title: "包子",
    lastMsg: "嗯",
    time: "3月13日",
    unreadCount: 0,
    type: "single",
    messageType: "image",
    isMuted: false
  },
  {
    id: "5",
    title: "杨博",
    lastMsg: "噢噢，时间挺快的，明年你们也要出来实习了",
    time: "3月12日",
    unreadCount: 0,
    type: "single",
    messageType: "text",
    isMuted: false
  },
  {
    id: "6",
    title: "2025区块链技能大赛备赛群",
    lastMsg: "王刻奇老师: 🤝",
    time: "3月8日",
    unreadCount: 5,
    type: "group",
    messageType: "text",
    isMuted: true
  },
  {
    id: "7",
    title: "18汽修徐叙敏",
    lastMsg: "",
    time: "3月2日",
    unreadCount: 0,
    type: "single",
    messageType: "sticker",
    isMuted: false
  },
  {
    id: "8",
    title: "214",
    lastMsg: "23网新2罗敏颐: 不管了",
    time: "2月28日",
    unreadCount: 0,
    type: "group",
    messageType: "text",
    isMuted: false
  },
  {
    id: "9",
    title: "创新创业项目交流",
    lastMsg: "龚芳海老师: 今天是20260228，祝创新创业项目…",
    time: "2月28日",
    unreadCount: 12,
    type: "group",
    messageType: "text",
    isMuted: false
  },
  {
    id: "10",
    title: "小韩",
    lastMsg: "四下单词",
    time: "2月21日",
    unreadCount: 0,
    type: "single",
    messageType: "text",
    isMuted: false
  }
];

// ─── 内存模拟数据 ─────────────────────────────────────────
const JWT_SECRET = 'flash_im_playground_secret';
const JWT_EXPIRES_IN = '2h';

// 验证码存储: phone -> { code, expiresAt }
const smsCodes = new Map();
// 用户存储: phone -> { user_id, phone, nickname, avatar }
const users = new Map();
let userIdCounter = 1;

// ─── 认证接口 ───────────────────────────────────────────────

// POST /auth/sms - 发送验证码（模拟）
app.post('/auth/sms', (req, res) => {
  const { phone } = req.body;
  if (!phone) {
    return res.status(400).json({ success: false, message: '手机号不能为空' });
  }

  const code = String(Math.floor(100000 + Math.random() * 900000));
  smsCodes.set(phone, { code, expiresAt: Date.now() + 5 * 60 * 1000 });

  console.log(`[短信验证码] ${phone} -> ${code}`);
  res.json({ success: true, message: '验证码已发送', code }); // playground 阶段直接返回 code
});

// POST /auth/login - 验证码登录（登录即注册）
app.post('/auth/login', (req, res) => {
  const { phone, code } = req.body;
  if (!phone || !code) {
    return res.status(400).json({ success: false, message: '手机号和验证码不能为空' });
  }

  const record = smsCodes.get(phone);
  if (!record || record.code !== code || Date.now() > record.expiresAt) {
    return res.status(401).json({ success: false, message: '验证码错误或已过期' });
  }

  // 验证通过，删除已使用的验证码
  smsCodes.delete(phone);

  // 登录即注册：手机号不存在则自动创建
  let user = users.get(phone);
  if (!user) {
    user = {
      user_id: userIdCounter++,
      phone,
      nickname: phone,
      avatar: `https://api.dicebear.com/7.x/identicon/png?seed=${phone}`,
    };
    users.set(phone, user);
    console.log(`[新用户注册] phone=${phone}, user_id=${user.user_id}`);
  }

  // 签发 JWT
  const token = jwt.sign(
    { user_id: user.user_id, phone: user.phone },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );

  console.log(`[登录成功] phone=${phone}, user_id=${user.user_id}`);
  res.json({ success: true, token, user_id: user.user_id });
});

// GET /user/profile - 获取用户信息（需 Token）
app.get('/user/profile', (req, res) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.startsWith('Bearer ')
    ? authHeader.slice(7)
    : authHeader;

  if (!token) {
    return res.status(401).json({ success: false, message: 'Token 缺失' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = users.get(decoded.phone);
    if (!user) {
      return res.status(401).json({ success: false, message: '用户不存在' });
    }
    res.json({
      success: true,
      user_id: user.user_id,
      nickname: user.nickname,
      avatar: user.avatar,
      phone: user.phone,
    });
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Token 无效或已过期' });
  }
});

app.get('/conversation', (req, res) => {
  res.json(conversations);
});

app.get('/heartbeat', (req, res) => {
  const now = new Date();
  const serverTime = now.toISOString().replace('T', ' ').substring(0, 19);

  res.json({
    success: true,
    message: 'pong',
    serverTime: serverTime,
    timestamp: Date.now()
  });
});

app.post('/heartbeat', (req, res) => {
  const now = new Date();
  const serverTime = now.toISOString().replace('T', ' ').substring(0, 19);
  const { message } = req.body;

  console.log(`[心跳消息] 收到: ${message}`);

  res.json({
    success: true,
    type: 'echo',
    originalMessage: message || '',
    replyMessage: `服务器已收到: ${message}`,
    serverTime: serverTime,
    timestamp: Date.now()
  });
});

const server = app.listen(port, '0.0.0.0', () => {
  console.log(`Server listening at http://localhost:${port}`);
});

server.on('upgrade', (request, socket, head) => {
  const pathname = request.url.split('?')[0];
  console.log(`[Upgrade] WebSocket 升级请求: ${pathname}`);

  if (pathname === '/ws') {
    wss.handleUpgrade(request, socket, head, (ws) => {
      wss.emit('connection', ws, request);
    });
  } else if (pathname === '/ws/chat_room') {
    chatRoomWss.handleUpgrade(request, socket, head, (ws) => {
      chatRoomWss.emit('connection', ws, request);
    });
  } else {
    socket.destroy();
    console.log(`[Upgrade] 未知路径，已拒绝: ${pathname}`);
  }
});

const wss = new WebSocket.Server({ noServer: true });

wss.on('connection', (ws, req) => {
  const clientIp = req.socket.remoteAddress;
  console.log(`[WebSocket] 客户端连接: ${clientIp}`);

  ws.send(JSON.stringify({ type: 'welcome', message: '欢迎连接！' }));

  ws.on('message', (data) => {
    const message = data.toString();
    console.log(`[WebSocket] 收到消息: ${message}`);
    ws.send(JSON.stringify({ type: 'echo', message: `echo: ${message}` }));
  });

  ws.on('close', () => {
    console.log(`[WebSocket] 客户端断开: ${clientIp}`);
  });

  ws.on('error', (err) => {
    console.error(`[WebSocket] 错误: ${err.message}`);
  });
});

// ─── Chat Room WebSocket (JWT 认证 + 心跳) ──────────────────

const chatRoomWss = new WebSocket.Server({ 
  noServer: true,
  clientTracking: true,
});

chatRoomWss.on('error', (err) => {
  console.error('[ChatRoom] Server Error:', err.message);
});

const onlineUsers = new Map();
let msgIdCounter = 1;

chatRoomWss.on('connection', (ws, req) => {
  const clientIp = req.socket.remoteAddress;
  console.log(`[ChatRoom] WebSocket 连接建立: ${clientIp}`);

  let isAuthenticated = false;
  let currentUser = null;
  let heartbeatInterval = null;

  ws.on('message', (data) => {
    try {
      const payload = JSON.parse(data.toString());

      if (!isAuthenticated) {
        if (payload.type === 'auth' && payload.token) {
          let decoded;
          try {
            decoded = jwt.verify(payload.token, JWT_SECRET);
          } catch (e) {
            console.log(`[ChatRoom] 认证失败: JWT 无效 - ${e.message}`);
            ws.send(JSON.stringify({ type: 'auth_error', message: 'Token 无效或已过期' }));
            ws.close(4002, 'Token invalid');
            return;
          }

          const user = users.get(decoded.phone);
          if (!user) {
            console.log(`[ChatRoom] 认证失败: 用户不存在 - phone=${decoded.phone}`);
            ws.send(JSON.stringify({ type: 'auth_error', message: '用户不存在' }));
            ws.close(4003, 'User not found');
            return;
          }

          isAuthenticated = true;
          currentUser = user;
          ws.userId = user.user_id;
          ws.nickname = user.nickname;
          ws.avatar = user.avatar;
          ws.isAlive = true;

          onlineUsers.set(user.user_id, ws);

          console.log(`[ChatRoom] 用户 ${user.nickname}(${user.user_id}) 认证成功`);

          ws.send(JSON.stringify({
            type: 'auth_success',
            message: `欢迎回来，${user.nickname}`,
            userId: user.user_id,
            nickname: user.nickname,
            avatar: user.avatar,
            onlineCount: onlineUsers.size,
          }));

          broadcastSystemMessage(`${user.nickname} 加入了聊天室`, user.user_id);

          heartbeatInterval = setInterval(() => {
            if (!ws.isAlive) {
              clearInterval(heartbeatInterval);
              ws.terminate();
              return;
            }
            ws.isAlive = false;
            ws.ping();
          }, 30000);

          return;
        } else {
          ws.send(JSON.stringify({ type: 'auth_error', message: '请先认证' }));
          ws.close(4000, 'Auth required');
          return;
        }
      }

      if (payload.type === 'ping') {
        ws.send(JSON.stringify({
          type: 'pong',
          timestamp: Date.now(),
          serverTime: new Date().toISOString().replace('T', ' ').substring(0, 19),
        }));
        return;
      }

      if (payload.type === 'message') {
        console.log(`[ChatRoom] 收到消息: from=${currentUser.nickname}, content=${payload.content}`);

        const chatMsg = {
          id: String(msgIdCounter++),
          fromUserId: currentUser.user_id,
          fromNickname: currentUser.nickname,
          fromAvatar: currentUser.avatar,
          content: payload.content || '',
          msgType: payload.msgType || 'text',
          time: new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' }),
        };

        chatRoomWss.clients.forEach((client) => {
          if (client.readyState === WebSocket.OPEN && client.userId) {
            client.send(JSON.stringify({ type: 'chat_message', ...chatMsg }));
          }
        });
        return;
      }
    } catch (e) {
      if (isAuthenticated) {
        ws.send(JSON.stringify({ type: 'error', message: '消息格式错误' }));
      }
    }
  });

  ws.on('pong', () => {
    ws.isAlive = true;
  });

  ws.on('close', () => {
    if (heartbeatInterval) clearInterval(heartbeatInterval);
    if (currentUser) {
      onlineUsers.delete(currentUser.user_id);
      broadcastSystemMessage(`${currentUser.nickname} 离开了聊天室`, currentUser.user_id);
      console.log(`[ChatRoom] 用户 ${currentUser.nickname}(${currentUser.user_id}) 已下线，当前在线: ${onlineUsers.size}`);
    }
  });

  ws.on('error', (err) => {
    if (heartbeatInterval) clearInterval(heartbeatInterval);
    console.error(`[ChatRoom] 错误: ${err.message}`);
  });
});

function broadcastSystemMessage(message, excludeUserId) {
  chatRoomWss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN && client.userId && client.userId !== excludeUserId) {
      client.send(JSON.stringify({
        type: 'system_message',
        content: message,
        time: new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' }),
        onlineCount: onlineUsers.size,
      }));
    }
  });
}

console.log('[ChatRoom] 聊天室服务已启动: /ws/chat_room?token=xxx');
