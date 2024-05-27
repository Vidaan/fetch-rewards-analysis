-- Warehouse
CREATE WAREHOUSE fetch_wh
WAREHOUSE_SIZE = 'X-SMALL';
USE WAREHOUSE fetch_wh;

-- Database
CREATE DATABASE retail_db;
USE DATABASE retail_db;

-- Schema
CREATE SCHEMA retail_schema;
USE SCHEMA retail_schema;

-- DDL for raw data tables
CREATE OR REPLACE TABLE T_BRANDS_JSON (
    JSON_DATA VARIANT
);

CREATE OR REPLACE TABLE T_RECEIPTS_JSON (
    JSON_DATA VARIANT
);

CREATE OR REPLACE TABLE T_USERS_JSON (
    JSON_DATA VARIANT
);

-- Query data
SELECT * FROM T_BRANDS_JSON;

SELECT * FROM T_RECEIPTS_JSON;

SELECT * FROM T_USERS_JSON;