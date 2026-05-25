CREATE TABLE IF NOT EXISTS auth_users (
    id            BIGSERIAL PRIMARY KEY,
    phone         VARCHAR(20)  NOT NULL,
    password_hash VARCHAR(255) NOT NULL DEFAULT '',
    nickname      VARCHAR(50)  NOT NULL DEFAULT '',
    avatar_url    TEXT         NOT NULL DEFAULT '',
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_users_phone ON auth_users (phone);
