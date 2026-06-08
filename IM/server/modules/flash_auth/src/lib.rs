pub mod jwt;
pub mod password;
pub mod sms;
pub mod state;
pub mod user;

pub use state::{AppState, DbUser, SmsCode};

use axum::{routing::{get, post, put}, Router};

pub fn routes() -> Router {
    Router::new()
        .route("/auth/sms", post(sms::send_sms))
        .route("/auth/login", post(user::login))
        .route("/auth/login/password", post(password::login))
        .route("/auth/password/setup", post(password::setup_password))
        .route("/auth/password", post(password::change_password))
        .route("/user/profile", get(user::get_profile))
        .route("/user/profile", put(user::update_profile))
}