#!/bin/bash
# Initialize multiple databases in PostgreSQL

set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    -- Create databases
    CREATE DATABASE wazuh;
    CREATE DATABASE thehive;
    CREATE DATABASE cortex;
    CREATE DATABASE rocketchat;

    -- Create users
    CREATE USER wazuh_user WITH ENCRYPTED PASSWORD 'wazuh_pass';
    CREATE USER thehive_user WITH ENCRYPTED PASSWORD 'thehive_pass';
    CREATE USER cortex_user WITH ENCRYPTED PASSWORD 'cortex_pass';
    CREATE USER rocketchat_user WITH ENCRYPTED PASSWORD 'rocketchat_pass';

    -- Grant privileges
    GRANT ALL PRIVILEGES ON DATABASE wazuh TO wazuh_user;
    GRANT ALL PRIVILEGES ON DATABASE thehive TO thehive_user;
    GRANT ALL PRIVILEGES ON DATABASE cortex TO cortex_user;
    GRANT ALL PRIVILEGES ON DATABASE rocketchat TO rocketchat_user;

    -- Enable extensions
    \c wazuh
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

    \c thehive
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

    \c cortex
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

    \c rocketchat
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
EOSQL

echo "✅ Databases initialized successfully"
