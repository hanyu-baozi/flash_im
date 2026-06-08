use std::sync::Arc;
use tokio::sync::broadcast;
use sqlx::PgPool;

use flash_auth::AppState as AuthAppState;

pub struct AppState {
    pub auth: Arc<AuthAppState>,
    pub chat_tx: broadcast::Sender<String>,
}

impl AppState {
    pub fn new(pool: PgPool) -> Self {
        let (chat_tx, _) = broadcast::channel(256);
        let auth = Arc::new(AuthAppState::new(pool));
        AppState { auth, chat_tx }
    }
}