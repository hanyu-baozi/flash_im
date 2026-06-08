use std::sync::Arc;
use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::Extension;
use axum::response::IntoResponse;
use chrono::Utc;

use flash_auth::jwt;
use flash_auth::DbUser;
use crate::state::AppState;

pub async fn handler(
    ws: WebSocketUpgrade,
    Extension(state): Extension<Arc<AppState>>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket: WebSocket| handle_connection(socket, state))
}

async fn handle_connection(mut socket: WebSocket, state: Arc<AppState>) {
    let mut is_authenticated = false;
    let mut current_user_id: u64 = 0;
    let mut current_nickname = String::new();
    let mut current_avatar = String::new();

    let mut broadcast_rx = state.chat_tx.subscribe();

    loop {
        tokio::select! {
            broadcast_msg = broadcast_rx.recv() => {
                if let Ok(msg) = broadcast_msg {
                    let _ = socket.send(Message::Text(msg)).await;
                }
            }
            client_msg = socket.recv() => {
                match client_msg {
                    Some(Ok(Message::Text(text))) => {
                        if !is_authenticated {
                            handle_auth_message(
                                &text,
                                &state,
                                &mut socket,
                                &mut is_authenticated,
                                &mut current_user_id,
                                &mut current_nickname,
                                &mut current_avatar,
                                &mut broadcast_rx,
                            ).await;
                        } else {
                            handle_chat_message(
                                &text,
                                &state,
                                &mut socket,
                                current_user_id,
                                &current_nickname,
                                &current_avatar,
                            ).await;
                        }
                    }
                    Some(Ok(Message::Pong(_))) => {
                    }
                    Some(Ok(Message::Close(_))) | None => {
                        if is_authenticated {
                            _ = state.chat_tx.send(
                                serde_json::json!({
                                    "type": "system_message",
                                    "content": format!("{} 离开了聊天室", current_nickname),
                                    "time": formatted_time(),
                                }).to_string()
                            );
                            tracing::info!(
                                "[ChatRoom] 用户 {}({}) 已下线",
                                current_nickname,
                                current_user_id
                            );
                        }
                        return;
                    }
                    _ => {}
                }
            }
        }
    }
}

async fn handle_auth_message(
    text: &str,
    state: &Arc<AppState>,
    socket: &mut WebSocket,
    is_authenticated: &mut bool,
    current_user_id: &mut u64,
    current_nickname: &mut String,
    current_avatar: &mut String,
    _broadcast_rx: &mut tokio::sync::broadcast::Receiver<String>,
) {
    let payload: serde_json::Value = match serde_json::from_str(text) {
        Ok(v) => v,
        Err(_) => return,
    };

    if payload.get("type").and_then(|v| v.as_str()) != Some("auth") {
        let auth_error = serde_json::json!({
            "type": "auth_error",
            "message": "请先认证"
        });
        let _ = socket
            .send(Message::Text(auth_error.to_string()))
            .await;
        let _ = socket.send(Message::Close(None)).await;
        return;
    }

    let token = match payload.get("token").and_then(|v| v.as_str()) {
        Some(t) => t,
        None => {
            let _ = socket
                .send(Message::Text(
                    serde_json::json!({"type": "auth_error", "message": "Token 缺失"}).to_string(),
                ))
                .await;
            let _ = socket.send(Message::Close(None)).await;
            return;
        }
    };

    let claims = match jwt::verify_token(token) {
        Ok(c) => c,
        Err(e) => {
            tracing::info!("[ChatRoom] 认证失败: JWT 无效 - {}", e);
            let _ = socket
                .send(Message::Text(
                    serde_json::json!({"type": "auth_error", "message": "Token 无效或已过期"})
                        .to_string(),
                ))
                .await;
            let _ = socket.send(Message::Close(None)).await;
            return;
        }
    };

    let db_user: Result<Option<DbUser>, _> = sqlx::query_as(
        "SELECT id, phone, password_hash, nickname, avatar_url, created_at, updated_at FROM auth_users WHERE phone = $1"
    )
    .bind(&claims.phone)
    .fetch_optional(&state.auth.pool)
    .await;

    let db_user = match db_user {
        Ok(Some(u)) => u,
        Ok(None) => {
            tracing::info!("[ChatRoom] 认证失败: 用户不存在");
            let _ = socket
                .send(Message::Text(
                    serde_json::json!({"type": "auth_error", "message": "用户不存在"})
                        .to_string(),
                ))
                .await;
            let _ = socket.send(Message::Close(None)).await;
            return;
        }
        Err(e) => {
            tracing::info!("[ChatRoom] DB 查询失败: {}", e);
            let _ = socket
                .send(Message::Text(
                    serde_json::json!({"type": "auth_error", "message": "服务内部错误"}).to_string(),
                ))
                .await;
            let _ = socket.send(Message::Close(None)).await;
            return;
        }
    };

    *is_authenticated = true;
    *current_user_id = db_user.id as u64;
    *current_nickname = db_user.nickname.clone();
    *current_avatar = db_user.avatar_url.clone();

    let _ = socket
        .send(Message::Text(
            serde_json::json!({
                "type": "auth_success",
                "message": format!("欢迎回来，{}", db_user.nickname),
                "userId": db_user.id,
                "nickname": db_user.nickname,
                "avatar": db_user.avatar_url,
            })
            .to_string(),
        ))
        .await;

    let _ = state.chat_tx.send(
        serde_json::json!({
            "type": "system_message",
            "content": format!("{} 加入了聊天室", db_user.nickname),
            "time": formatted_time(),
        })
        .to_string(),
    );

    tracing::info!(
        "[ChatRoom] 用户 {}({}) 认证成功",
        db_user.nickname,
        db_user.id
    );
}

async fn handle_chat_message(
    text: &str,
    state: &Arc<AppState>,
    socket: &mut WebSocket,
    current_user_id: u64,
    current_nickname: &str,
    current_avatar: &str,
) {
    let payload: serde_json::Value = match serde_json::from_str(text) {
        Ok(v) => v,
        Err(_) => return,
    };

    let msg_type = payload
        .get("type")
        .and_then(|v| v.as_str())
        .unwrap_or("");

    match msg_type {
        "ping" => {
            let _ = socket
                .send(Message::Text(
                    serde_json::json!({
                        "type": "pong",
                        "timestamp": Utc::now().timestamp_millis(),
                        "serverTime": Utc::now().format("%Y-%m-%d %H:%M:%S").to_string(),
                    })
                    .to_string(),
                ))
                .await;
        }
        "message" => {
            let content = payload
                .get("content")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            let msg_type_val = payload
                .get("msgType")
                .and_then(|v| v.as_str())
                .unwrap_or("text");

            tracing::info!(
                "[ChatRoom] 收到消息: from={}, content={}",
                current_nickname,
                content
            );

            let _ = state.chat_tx.send(
                serde_json::json!({
                    "type": "chat_message",
                    "fromUserId": current_user_id,
                    "fromNickname": current_nickname,
                    "fromAvatar": current_avatar,
                    "content": content,
                    "msgType": msg_type_val,
                    "time": formatted_time(),
                })
                .to_string(),
            );
        }
        _ => {}
    }
}

fn formatted_time() -> String {
    chrono::Local::now().format("%H:%M").to_string()
}