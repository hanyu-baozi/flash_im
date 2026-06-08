pub const JWT_SECRET: &str = "flash_im_playground_secret";
pub const JWT_EXPIRES_IN_HOURS: i64 = 2;

use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use chrono::Utc;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub user_id: u64,
    pub phone: String,
    pub exp: usize,
    pub iat: usize,
}

pub fn create_token(user_id: u64, phone: &str) -> Result<String, jsonwebtoken::errors::Error> {
    let now = Utc::now();
    let claims = Claims {
        user_id,
        phone: phone.to_string(),
        iat: now.timestamp() as usize,
        exp: (now.timestamp() + JWT_EXPIRES_IN_HOURS * 3600) as usize,
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(JWT_SECRET.as_bytes()),
    )
}

pub fn verify_token(token: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
    decode::<Claims>(
        token,
        &DecodingKey::from_secret(JWT_SECRET.as_bytes()),
        &Validation::default(),
    )
    .map(|data| data.claims)
}