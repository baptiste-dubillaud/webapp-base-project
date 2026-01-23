-- adds session tables
-- depends: 001_230126_adds_user_table

-- Migration SQL goes here

-----------------------------------------------------------------
-- Create sessions table
CREATE TABLE "sessions" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    "user_id" UUID NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
    "session_token" VARCHAR(255) NOT NULL UNIQUE,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    "expires_at" TIMESTAMP WITHOUT TIME ZONE NOT NULL
);

-- Create index on user_id for faster lookups
CREATE INDEX idx_sessions_user_id ON "sessions" ("user_id");

-- Create index on expires_at for efficient cleanup of expired sessions
CREATE INDEX idx_sessions_expires_at ON "sessions" ("expires_at");

-----------------------------------------------------------------
-- Create refresh_tokens table
CREATE TABLE "refresh_tokens" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    "user_id" UUID NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
    "token" VARCHAR(255) NOT NULL UNIQUE,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    "expires_at" TIMESTAMP WITHOUT TIME ZONE NOT NULL
);

-- Create index on user_id for faster lookups
CREATE INDEX idx_refresh_tokens_user_id ON "refresh_tokens" ("user_id");

-- Create index on expires_at for efficient cleanup of expired refresh tokens
CREATE INDEX idx_refresh_tokens_expires_at ON "refresh_tokens" ("expires_at");