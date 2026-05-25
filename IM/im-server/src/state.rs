use std::collections::HashMap;
use chrono::{DateTime, Utc};
use sqlx::FromRow;
use sqlx::PgPool;
use tokio::sync::{broadcast, RwLock};

#[derive(Debug, Clone, FromRow)]
pub struct DbUser {
    pub id: i64,
    pub phone: String,
    pub password_hash: String,
    pub nickname: String,
    pub avatar_url: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

pub struct SmsCode {
    pub code: String,
    pub expires_at: i64,
}

pub struct AppState {
    pub pool: PgPool,
    pub sms_codes: RwLock<HashMap<String, SmsCode>>,
    pub chat_tx: broadcast::Sender<String>,
}

impl AppState {
    pub fn new(pool: PgPool) -> Self {
        let (chat_tx, _) = broadcast::channel(256);

        AppState {
            pool,
            sms_codes: RwLock::new(HashMap::new()),
            chat_tx,
        }
    }
}
