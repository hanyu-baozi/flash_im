use std::collections::HashMap;
use sqlx::FromRow;
use sqlx::PgPool;
use tokio::sync::RwLock;

#[derive(Debug, Clone, FromRow)]
pub struct DbUser {
    pub id: i64,
    pub phone: String,
    pub password_hash: String,
    pub nickname: String,
    pub avatar_url: String,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
}

pub struct SmsCode {
    pub code: String,
    pub expires_at: i64,
}

pub struct AppState {
    pub pool: PgPool,
    pub sms_codes: RwLock<HashMap<String, SmsCode>>,
}

impl AppState {
    pub fn new(pool: PgPool) -> Self {
        AppState {
            pool,
            sms_codes: RwLock::new(HashMap::new()),
        }
    }
}