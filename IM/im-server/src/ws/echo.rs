use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::response::IntoResponse;

pub async fn handler(ws: WebSocketUpgrade) -> impl IntoResponse {
    ws.on_upgrade(move |mut socket: WebSocket| async move {
        let welcome = serde_json::json!({
            "type": "welcome",
            "message": "欢迎连接！"
        });
        let _ = socket
            .send(Message::Text(welcome.to_string()))
            .await;

        while let Some(Ok(msg)) = socket.recv().await {
            match msg {
                Message::Text(text) => {
                    tracing::info!("[WebSocket] 收到消息: {}", text);
                    let reply = serde_json::json!({
                        "type": "echo",
                        "message": format!("echo: {}", text)
                    });
                    let _ = socket
                        .send(Message::Text(reply.to_string()))
                        .await;
                }
                Message::Close(_) => break,
                _ => {}
            }
        }
    })
}
