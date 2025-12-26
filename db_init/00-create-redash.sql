-- Runs only on first init of the Postgres data directory
-- Creates redash role and database
CREATE USER redash WITH PASSWORD 'redash';
CREATE DATABASE redash OWNER redash;
GRANT ALL PRIVILEGES ON DATABASE redash TO redash;
