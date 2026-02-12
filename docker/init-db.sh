#!/bin/bash
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  CREATE DATABASE auth_service_development;
  CREATE DATABASE notification_service_development;
  CREATE DATABASE webscraping_manager_development;
EOSQL
