pub mod jwt;
pub mod password;
pub mod sms;
pub mod user;

use axum::{routing::{get, post}, Router};

pub fn routes() -> Router {
    Router::new()
        .route("/auth/sms", post(sms::send_sms))
        .route("/auth/login", post(user::login))
        .route("/auth/login/password", post(password::login))
        .route("/auth/password/setup", post(password::setup_password))
        .route("/auth/password", post(password::change_password))
        .route("/user/profile", get(user::get_profile))
}
