-- Rollback for: adds session tables
-- depends: 001_230126_adds_user_table

-- Rollback SQL goes here

-----------------------------------------------------------------
-- Drop refresh_tokens table and associated indexes

DROP INDEX IF EXISTS idx_refresh_tokens_expires_at;

DROP INDEX IF EXISTS idx_refresh_tokens_user_id;

DROP TABLE IF EXISTS "refresh_tokens";

-----------------------------------------------------------------
-- Drop sessions table and associated indexes

DROP INDEX IF EXISTS idx_sessions_expires_at;

DROP INDEX IF EXISTS idx_sessions_user_id;

DROP TABLE IF EXISTS "sessions";