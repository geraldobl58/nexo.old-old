-- PostgreSQL Initialization Script - Development
-- Creates additional databases for Keycloak

CREATE DATABASE keycloak_dev;
GRANT ALL PRIVILEGES ON DATABASE keycloak_dev TO nexo;
