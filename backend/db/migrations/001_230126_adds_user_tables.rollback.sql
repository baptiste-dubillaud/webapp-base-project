-- Rollback for: adds user table

-- Rollback SQL goes here

-- Drop user_role junction table
DROP TABLE IF EXISTS "user_role";

-- Drop role table
DROP TABLE IF EXISTS "role";

-- Drop trigger for updating updated_at timestamp
DROP TRIGGER IF EXISTS update_user_updated_at ON "user";

-- Drop trigger function
DROP FUNCTION IF EXISTS update_updated_at_column ();

-- Drop user table
DROP TABLE IF EXISTS "user";

-- Optionally, drop pgcrypto extension
DROP EXTENSION IF EXISTS "pgcrypto";