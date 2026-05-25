mod auth;
mod db;
mod mock;
mod state;
mod util;
mod ws;

use std::sync::Arc;
use axum::{routing::get, Router, extract::Extension};
use tower_http::cors::{Any, CorsLayer};

use state::AppState;

async fn get_v() -> axum::Json<mock::SystemInfo> {
    axum::Json(mock::SystemInfo::new())
}

async fn get_conversations() -> axum::Json<Vec<mock::Conversation>> {
    axum::Json(mock::get_conversations())
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    dotenvy::dotenv().ok();

    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");

    tracing::info!("PostgreSQL: {}", database_url);

    let pool = db::create_pool(&database_url).await;
    db::run_migrations(&pool).await.expect("migrations failed");

    let state = Arc::new(AppState::new(pool));

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let app = Router::new()
        .route("/v", get(get_v))
        .route("/conversation", get(get_conversations))
        .merge(auth::routes())
        .merge(ws::routes())
        .layer(Extension(state))
        .layer(cors);

    let ip = util::get_local_ip();
    let addr = format!("{}:3000", ip);

    tracing::info!("Server starting on http://{}", addr);
    tracing::info!("REST API: /v, /conversation, /auth/sms, /auth/login, /auth/login/password, /auth/password/setup, /auth/password, /user/profile");
    tracing::info!("WebSocket: /ws, /ws/chat_room");

    axum::Server::bind(&addr.parse().unwrap())
        .serve(app.into_make_service())
        .await
        .unwrap();
}
