# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flash IM is an instant messaging app with a **Flutter client** (`flash_im/`) and a **Rust backend** (`IM/im-server/`). The project is in early "playground" development phase. An older Node.js/Express prototype (`IM/server.js`) is also present but the Rust server is the active backend.

## Common Commands

### Backend (Rust server)

```powershell
# Initialize database and run migrations (first time only)
powershell -ExecutionPolicy Bypass -File IM/scripts/db/init.ps1

# Reset database (drop, recreate, re-migrate)
powershell -ExecutionPolicy Bypass -File IM/scripts/db/reset.ps1

# Start the server (auto-starts PostgreSQL, kills port 3000, runs cargo run)
powershell -ExecutionPolicy Bypass -File IM/scripts/server/start.ps1

# Manual start (if PostgreSQL is already running)
cd IM/im-server && cargo run
```

The server binds to `<local-ip>:3000`. Requires PostgreSQL running on `localhost:5432` (credentials: `postgres`/`123456`, database: `flash_im`).

### Flutter client

```bash
# Run the playground app (the active entry point)
cd flash_im && flutter run -t lib/main_playground.dart

# Run specific test files
flutter test test/playground/auth/auth_service_test.dart
flutter test test/playground/auth/auth_models_test.dart
flutter test test/playground/auth/auth_viewmodel_test.dart
flutter test test/playground/conversation_service_test.dart

# Analyze
flutter analyze
```

Tests use Dio interceptors to mock HTTP responses — no real server needed.

## Architecture

### Flutter client (`flash_im/`)

**Entry points:**
- `lib/main.dart` — placeholder counter app (unused).
- `lib/main_playground.dart` — the active entry point. Creates `PlaygroundApp` (MaterialApp with amber theme) showing `PlaygroundHome`.

**State management:** Plain `ChangeNotifier` + `AnimatedBuilder`. No Provider, BLoC, or Riverpod. Each feature's ViewModel extends `ChangeNotifier` and is instantiated directly (manual DI).

**Feature architecture:** Every playground feature under `lib/src/playground/features/<name>/` follows this layered pattern:
- `config/` — API base URLs, path constants, timeouts
- `models/` — data classes (immutable, hand-written `==` and `hashCode`)
- `services/` — HTTP (Dio) or WebSocket (`web_socket_channel`) calls
- `viewmodel/` — `ChangeNotifier` subclass holding UI state and calling services
- `views/` — Flutter widgets, receive ViewModel via constructor

**Central config:** `PlaygroundConfig.baseUrl` defaults to `http://10.0.2.2:3000` (Android emulator → host). Other config classes read from this. Call `PlaygroundConfig.updateBaseUrl(url)` to change at runtime.

**Key dependencies:** `dio` (HTTP), `shared_preferences` (local storage for auth tokens), `web_socket_channel` (WebSocket client).

**Features (all in `lib/src/playground/features/`):**
| Feature | Purpose | Network |
|---------|---------|---------|
| `auth` | SMS/password login, profile | REST |
| `chat_room` | WebSocket chat with heartbeat | WebSocket |
| `conversation` | Conversation list (WEUI-style) | REST |
| `heartbeat` | HTTP heartbeat testing | REST |
| `fireworks` | Canvas particle animation | None |

### Rust backend (`IM/im-server/`)

**Module structure:**
- `auth/` — SMS code, user login/registration, password management, JWT
- `ws/` — WebSocket echo + chat_room handlers
- `db.rs` — PostgreSQL connection pool + SQLx migration runner
- `state.rs` — `AppState` shared via `Arc`: holds `PgPool`, in-memory `sms_codes` HashMap, and a `broadcast::Sender` for chat messages
- `mock/` — hardcoded system info and conversation data (legacy from Node prototype)
- `util/` — `get_local_ip()` (currently returns `127.0.0.1`)

**Database:** PostgreSQL via `sqlx` with migration files in `migrations/`. The `auth_users` table has `id`, `phone`, `password_hash`, `nickname`, `avatar_url`, timestamps. Seed data creates 3 test users (password: `123456`).

**Auth flow:** SMS codes are stored in memory (HashMap with 5-min TTL). Login is "login-or-register": if phone doesn't exist, a new user is auto-created. JWT uses HS256 with hardcoded secret `"flash_im_playground_secret"`, 2-hour expiry. Passwords use bcrypt.

**WebSocket chat protocol:**
1. Client connects, sends `{"type":"auth","token":"..."}`
2. Server validates JWT, responds `{"type":"auth_success",...}` or `{"type":"auth_error",...}`
3. Heartbeat: client sends `{"type":"ping"}` → server replies `{"type":"pong"}`
4. Messages: client sends `{"type":"message","content":"...","msgType":"text"}` → server broadcasts `{"type":"chat_message",...}` to all connected clients via Tokio broadcast channel

### REST API summary

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/v` | None | System info |
| GET | `/conversation` | None | Mock conversation list |
| POST | `/auth/sms` | None | Send SMS code (returns code in response) |
| POST | `/auth/login` | None | SMS code login (auto-registers) |
| POST | `/auth/login/password` | None | Password login |
| POST | `/auth/password/setup` | Bearer | Set initial password |
| POST | `/auth/password` | Bearer | Change password |
| GET | `/user/profile` | Bearer | Get user profile |
| GET | `/ws` | None | WebSocket echo |
| GET | `/ws/chat_room` | JWT in handshake | WebSocket chat room |
