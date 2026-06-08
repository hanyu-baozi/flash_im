use std::sync::Arc;
use axum::{extract::Extension, Json, http::StatusCode};
use chrono::Utc;
use serde::{Deserialize, Serialize};

use crate::jwt;
use crate::password::LoginType;
use crate::state::{AppState, DbUser};

#[derive(Debug, Deserialize)]
pub struct UpdateProfileRequest {
    #[serde(default)]
    pub nickname: Option<String>,
    #[serde(default)]
    pub avatar: Option<String>,
    #[serde(default)]
    pub signature: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub phone: String,
    pub code: String,
}

#[derive(Debug, Serialize)]
pub struct LoginResponse {
    pub success: bool,
    pub login_type: LoginType,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub token: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub user_id: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub nickname: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub avatar: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub has_password: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub message: Option<String>,
}

pub async fn login(
    Extension(state): Extension<Arc<AppState>>,
    Json(req): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> {
    if req.phone.is_empty() || req.code.is_empty() {
        return Ok(Json(LoginResponse {
            success: false,
            login_type: LoginType::Sms,
            token: None,
            user_id: None,
            nickname: None,
            avatar: None,
            has_password: None,
            message: Some("手机号和验证码不能为空".to_string()),
        }));
    }

    let valid = {
        let codes = state.sms_codes.read().await;
        codes
            .get(&req.phone)
            .map(|record| record.code == req.code && Utc::now().timestamp() < record.expires_at)
            .unwrap_or(false)
    };

    if !valid {
        return Ok(Json(LoginResponse {
            success: false,
            login_type: LoginType::Sms,
            token: None,
            user_id: None,
            nickname: None,
            avatar: None,
            has_password: None,
            message: Some("验证码错误或已过期".to_string()),
        }));
    }

    state.sms_codes.write().await.remove(&req.phone);

    let db_user: Option<DbUser> = sqlx::query_as(
        "SELECT id, phone, password_hash, nickname, avatar_url, created_at, updated_at FROM auth_users WHERE phone = $1"
    )
    .bind(&req.phone)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("[DB] 查询用户失败: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let user = match db_user {
        Some(u) => u,
        None => {
            let avatar_url = format!("https://api.dicebear.com/7.x/identicon/png?seed={}", req.phone);
            let row: (i64,) = sqlx::query_as(
                "INSERT INTO auth_users (phone, nickname, avatar_url) VALUES ($1, $2, $3) RETURNING id"
            )
            .bind(&req.phone)
            .bind(&req.phone)
            .bind(&avatar_url)
            .fetch_one(&state.pool)
            .await
            .map_err(|e| {
                tracing::error!("[DB] 插入用户失败: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })?;

            tracing::info!("[新用户注册] phone={}, user_id={}", req.phone, row.0);

            DbUser {
                id: row.0,
                phone: req.phone.clone(),
                password_hash: String::new(),
                nickname: req.phone.clone(),
                avatar_url,
                created_at: Utc::now(),
                updated_at: Utc::now(),
            }
        }
    };

    let token = jwt::create_token(user.id as u64, &user.phone).map_err(|e| {
        tracing::error!("[JWT] 签发失败: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let has_password = !user.password_hash.is_empty();

    tracing::info!("[短信登录] phone={}, user_id={}, has_password={}", user.phone, user.id, has_password);

    Ok(Json(LoginResponse {
        success: true,
        login_type: LoginType::Sms,
        token: Some(token),
        user_id: Some(user.id),
        nickname: Some(user.nickname),
        avatar: Some(user.avatar_url),
        has_password: Some(has_password),
        message: None,
    }))
}

#[derive(Debug, Serialize)]
pub struct ProfileResponse {
    pub success: bool,
    pub user_id: Option<i64>,
    pub nickname: Option<String>,
    pub avatar: Option<String>,
    pub phone: Option<String>,
    pub has_password: Option<bool>,
    pub message: Option<String>,
}

pub async fn get_profile(
    Extension(state): Extension<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> Result<Json<ProfileResponse>, StatusCode> {
    let token = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .map(|v| {
            if v.starts_with("Bearer ") {
                &v[7..]
            } else {
                v
            }
        });

    let token = match token {
        Some(t) => t,
        None => {
            return Ok(Json(ProfileResponse {
                success: false,
                user_id: None,
                nickname: None,
                avatar: None,
                phone: None,
                has_password: None,
                message: Some("Token 缺失".to_string()),
            }))
        }
    };

    let claims = jwt::verify_token(token).map_err(|_| StatusCode::UNAUTHORIZED)?;

    let db_user: Option<DbUser> = sqlx::query_as(
        "SELECT id, phone, password_hash, nickname, avatar_url, created_at, updated_at FROM auth_users WHERE phone = $1"
    )
    .bind(&claims.phone)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("[DB] 查询用户失败: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    match db_user {
        Some(u) => {
            let has_password = !u.password_hash.is_empty();
            Ok(Json(ProfileResponse {
                success: true,
                user_id: Some(u.id),
                nickname: Some(u.nickname),
                avatar: Some(u.avatar_url),
                phone: Some(u.phone),
                has_password: Some(has_password),
                message: None,
            }))
        }
        None => Ok(Json(ProfileResponse {
            success: false,
            user_id: None,
            nickname: None,
            avatar: None,
            phone: None,
            has_password: None,
            message: Some("用户不存在".to_string()),
        })),
    }
}

pub async fn update_profile(
    Extension(state): Extension<Arc<AppState>>,
    headers: axum::http::HeaderMap,
    Json(req): Json<UpdateProfileRequest>,
) -> Result<Json<ProfileResponse>, StatusCode> {
    let token = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .map(|v| {
            if v.starts_with("Bearer ") {
                &v[7..]
            } else {
                v
            }
        });

    let token = match token {
        Some(t) => t,
        None => {
            return Ok(Json(ProfileResponse {
                success: false,
                user_id: None,
                nickname: None,
                avatar: None,
                phone: None,
                has_password: None,
                message: Some("Token 缺失".to_string()),
            }))
        }
    };

    let claims = jwt::verify_token(token).map_err(|_| StatusCode::UNAUTHORIZED)?;

    // Build dynamic update query
    let mut updates: Vec<String> = Vec::new();
    let mut nickname_val: Option<String> = None;
    let mut avatar_val: Option<String> = None;

    if let Some(ref nickname) = req.nickname {
        updates.push("nickname = $1".to_string());
        nickname_val = Some(nickname.clone());
    }
    if let Some(ref avatar) = req.avatar {
        let idx = updates.len() + 1;
        updates.push(format!("avatar_url = ${}", idx));
        avatar_val = Some(avatar.clone());
    }

    if updates.is_empty() {
        return Ok(Json(ProfileResponse {
            success: false,
            user_id: None,
            nickname: None,
            avatar: None,
            phone: None,
            has_password: None,
            message: Some("没有需要更新的字段".to_string()),
        }));
    }

    let phone = claims.phone.clone();

    let db_user: Option<DbUser> = match (nickname_val, avatar_val) {
        (Some(nick), Some(av)) => {
            sqlx::query_as(
                "UPDATE auth_users SET nickname = $1, avatar_url = $2, updated_at = NOW() WHERE phone = $3 RETURNING id, phone, password_hash, nickname, avatar_url, created_at, updated_at"
            )
            .bind(&nick)
            .bind(&av)
            .bind(&phone)
            .fetch_optional(&state.pool)
            .await
        }
        (Some(nick), None) => {
            sqlx::query_as(
                "UPDATE auth_users SET nickname = $1, updated_at = NOW() WHERE phone = $2 RETURNING id, phone, password_hash, nickname, avatar_url, created_at, updated_at"
            )
            .bind(&nick)
            .bind(&phone)
            .fetch_optional(&state.pool)
            .await
        }
        (None, Some(av)) => {
            sqlx::query_as(
                "UPDATE auth_users SET avatar_url = $1, updated_at = NOW() WHERE phone = $2 RETURNING id, phone, password_hash, nickname, avatar_url, created_at, updated_at"
            )
            .bind(&av)
            .bind(&phone)
            .fetch_optional(&state.pool)
            .await
        }
        (None, None) => {
            return Err(StatusCode::BAD_REQUEST);
        }
    }
    .map_err(|e| {
        tracing::error!("[DB] 更新用户失败: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    match db_user {
        Some(u) => {
            let has_password = !u.password_hash.is_empty();
            tracing::info!("[更新资料] phone={}, user_id={}", u.phone, u.id);
            Ok(Json(ProfileResponse {
                success: true,
                user_id: Some(u.id),
                nickname: Some(u.nickname),
                avatar: Some(u.avatar_url),
                phone: Some(u.phone),
                has_password: Some(has_password),
                message: None,
            }))
        }
        None => Ok(Json(ProfileResponse {
            success: false,
            user_id: None,
            nickname: None,
            avatar: None,
            phone: None,
            has_password: None,
            message: Some("用户不存在".to_string()),
        })),
    }
}