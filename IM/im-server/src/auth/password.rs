use std::sync::Arc;
use axum::{extract::Extension, Json, http::StatusCode};
use serde::{Deserialize, Serialize};

use crate::auth::jwt;
use crate::state::{AppState, DbUser};

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum LoginType {
    Sms,
    Password,
}

#[derive(Debug, Deserialize)]
pub struct PasswordLoginRequest {
    pub phone: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct PasswordLoginResponse {
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
    Json(req): Json<PasswordLoginRequest>,
) -> Result<Json<PasswordLoginResponse>, StatusCode> {
    if req.phone.is_empty() || req.password.is_empty() {
        return Ok(Json(PasswordLoginResponse {
            success: false,
            login_type: LoginType::Password,
            token: None,
            user_id: None,
            nickname: None,
            avatar: None,
            has_password: None,
            message: Some("手机号和密码不能为空".to_string()),
        }));
    }

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

    let db_user = match db_user {
        Some(u) => u,
        None => {
            return Ok(Json(PasswordLoginResponse {
                success: false,
                login_type: LoginType::Password,
                token: None,
                user_id: None,
                nickname: None,
                avatar: None,
                has_password: None,
                message: Some("用户不存在".to_string()),
            }));
        }
    };

    if db_user.password_hash.is_empty()
        || !bcrypt::verify(&req.password, &db_user.password_hash).unwrap_or(false)
    {
        return Ok(Json(PasswordLoginResponse {
            success: false,
            login_type: LoginType::Password,
            token: None,
            user_id: None,
            nickname: None,
            avatar: None,
            has_password: None,
            message: Some("密码错误".to_string()),
        }));
    }

    let token = jwt::create_token(db_user.id as u64, &db_user.phone).map_err(|e| {
        tracing::error!("[JWT] 签发失败: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    tracing::info!("[密码登录] phone={}, user_id={}", db_user.phone, db_user.id);

    Ok(Json(PasswordLoginResponse {
        success: true,
        login_type: LoginType::Password,
        token: Some(token),
        user_id: Some(db_user.id),
        nickname: Some(db_user.nickname),
        avatar: Some(db_user.avatar_url),
        has_password: Some(true),
        message: None,
    }))
}

// ─── POST /auth/password/setup ─────────────────────────────

#[derive(Debug, Deserialize)]
pub struct SetupPasswordRequest {
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct SetupPasswordResponse {
    pub success: bool,
    pub message: String,
}

pub async fn setup_password(
    Extension(state): Extension<Arc<AppState>>,
    headers: axum::http::HeaderMap,
    Json(req): Json<SetupPasswordRequest>,
) -> Result<Json<SetupPasswordResponse>, StatusCode> {
    if req.password.len() < 6 {
        return Ok(Json(SetupPasswordResponse {
            success: false,
            message: "密码长度不能少于 6 位".to_string(),
        }));
    }

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
            return Ok(Json(SetupPasswordResponse {
                success: false,
                message: "Token 缺失".to_string(),
            }));
        }
    };

    let claims = jwt::verify_token(token).map_err(|_| StatusCode::UNAUTHORIZED)?;

    let row: Option<(String,)> = sqlx::query_as(
        "SELECT password_hash FROM auth_users WHERE phone = $1"
    )
    .bind(&claims.phone)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let (current_hash,) = match row {
        Some(r) => r,
        None => {
            return Ok(Json(SetupPasswordResponse {
                success: false,
                message: "用户不存在".to_string(),
            }));
        }
    };

    if !current_hash.is_empty() {
        return Ok(Json(SetupPasswordResponse {
            success: false,
            message: "密码已设置，请使用修改密码接口".to_string(),
        }));
    }

    let hash = bcrypt::hash(&req.password, bcrypt::DEFAULT_COST).map_err(|_| {
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    sqlx::query(
        "UPDATE auth_users SET password_hash = $1, updated_at = NOW() WHERE phone = $2"
    )
    .bind(&hash)
    .bind(&claims.phone)
    .execute(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    tracing::info!("[设置密码] phone={}", claims.phone);

    Ok(Json(SetupPasswordResponse {
        success: true,
        message: "密码设置成功".to_string(),
    }))
}

// ─── PUT /auth/password ────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct ChangePasswordRequest {
    pub old_password: String,
    pub new_password: String,
}

#[derive(Debug, Serialize)]
pub struct ChangePasswordResponse {
    pub success: bool,
    pub message: String,
}

pub async fn change_password(
    Extension(state): Extension<Arc<AppState>>,
    headers: axum::http::HeaderMap,
    Json(req): Json<ChangePasswordRequest>,
) -> Result<Json<ChangePasswordResponse>, StatusCode> {
    if req.new_password.len() < 6 {
        return Ok(Json(ChangePasswordResponse {
            success: false,
            message: "新密码长度不能少于 6 位".to_string(),
        }));
    }

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
            return Ok(Json(ChangePasswordResponse {
                success: false,
                message: "Token 缺失".to_string(),
            }));
        }
    };

    let claims = jwt::verify_token(token).map_err(|_| StatusCode::UNAUTHORIZED)?;

    let row: Option<(String,)> = sqlx::query_as(
        "SELECT password_hash FROM auth_users WHERE phone = $1"
    )
    .bind(&claims.phone)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let (current_hash,) = match row {
        Some(r) => r,
        None => {
            return Ok(Json(ChangePasswordResponse {
                success: false,
                message: "用户不存在".to_string(),
            }));
        }
    };

    if current_hash.is_empty() {
        return Ok(Json(ChangePasswordResponse {
            success: false,
            message: "请先设置密码".to_string(),
        }));
    }

    if !bcrypt::verify(&req.old_password, &current_hash).unwrap_or(false) {
        return Ok(Json(ChangePasswordResponse {
            success: false,
            message: "原密码错误".to_string(),
        }));
    }

    let hash = bcrypt::hash(&req.new_password, bcrypt::DEFAULT_COST).map_err(|_| {
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    sqlx::query(
        "UPDATE auth_users SET password_hash = $1, updated_at = NOW() WHERE phone = $2"
    )
    .bind(&hash)
    .bind(&claims.phone)
    .execute(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    tracing::info!("[修改密码] phone={}", claims.phone);

    Ok(Json(ChangePasswordResponse {
        success: true,
        message: "密码修改成功".to_string(),
    }))
}
