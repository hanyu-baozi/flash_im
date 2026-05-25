use std::sync::Arc;
use axum::{extract::Extension, Json};
use chrono::Utc;
use rand::Rng;
use serde::{Deserialize, Serialize};

use crate::state::{AppState, SmsCode};

#[derive(Debug, Deserialize)]
pub struct SendSmsRequest {
    pub phone: String,
}

#[derive(Debug, Serialize)]
pub struct SendSmsResponse {
    pub success: bool,
    pub message: String,
    pub code: String,
}

pub async fn send_sms(
    Extension(state): Extension<Arc<AppState>>,
    Json(req): Json<SendSmsRequest>,
) -> Json<SendSmsResponse> {
    if req.phone.is_empty() {
        return Json(SendSmsResponse {
            success: false,
            message: "手机号不能为空".to_string(),
            code: String::new(),
        });
    }

    let code = format!("{:06}", rand::thread_rng().gen_range(100000..999999));
    let expires_at = Utc::now().timestamp() + 5 * 60;

    state.sms_codes.write().await.insert(
        req.phone.clone(),
        SmsCode {
            code: code.clone(),
            expires_at,
        },
    );

    tracing::info!("[短信验证码] {} -> {}", req.phone, code);

    Json(SendSmsResponse {
        success: true,
        message: "验证码已发送".to_string(),
        code,
    })
}
