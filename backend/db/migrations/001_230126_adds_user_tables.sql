-- adds user table

-- Migration SQL goes here

-- Adds pgcrypto extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-----------------------------------------------------------------
-- Create user table
CREATE TABLE IF NOT EXISTS "user" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v7 (),
    "username" VARCHAR(50) NOT NULL UNIQUE,
    "email" VARCHAR(100) NOT NULL UNIQUE,
    "password_hash" VARCHAR(255) NOT NULL,
    "created_at" TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        "updated_at" TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        "is_valid" BOOLEAN DEFAULT FALSE
);

-- Create index on username for faster lookups
CREATE INDEX idx_user_username ON "user" ("username");
-- Create trigger function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updated_at" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to use the function on user table
CREATE TRIGGER update_user_updated_at
BEFORE UPDATE ON "user"
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-----------------------------------------------------------------
-- Create role_table
CREATE TABLE IF NOT EXISTS "role" (
    "id" SERIAL PRIMARY KEY,
    "role_name" VARCHAR(50) NOT NULL UNIQUE
);

-- Insert default roles
INSERT INTO
    "role" ("role_name")
VALUES ('admin'),
    ('user'),
    ('demo');

-----------------------------------------------------------------
-- Create user_role junction table

CREATE TABLE IF NOT EXISTS "user_role" (
    "user_id" UUID REFERENCES "user" ("id") ON DELETE CASCADE,
    "role_id" INT REFERENCES "role" ("id") ON DELETE CASCADE,
    PRIMARY KEY ("user_id", "role_id")
);

-- Create index on user_id for faster lookups
CREATE INDEX idx_user_role_user_id ON "user_role" ("user_id");
-- Create index on role_id for faster lookups
CREATE INDEX idx_user_role_role_id ON "user_role" ("role_id");

-----------------------------------------------------------------