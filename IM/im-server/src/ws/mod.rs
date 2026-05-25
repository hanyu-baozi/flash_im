pub mod echo;
pub mod chat_room;

use axum::{routing::get, Router};

pub fn routes() -> Router {
    Router::new()
        .route("/ws", get(echo::handler))
        .route("/ws/chat_room", get(chat_room::handler))
}
