# Overview

SQL Dialect - Snowflake SQL

<img width="510" alt="image" src="https://github.com/Vidaan/fetch-rewards-analysis/assets/56769902/7d7e979a-19ac-465c-a94a-1d3988807ca7">

The above picture shows the structuring of data based on the files provided for this analysis. 

## 1. Process:
1. The three data files are first loaded into corresponding tables in Raw Data layer. A VARIANT data type is used to accomodate the JSON data.
2. The JSON data is flattened into corresponding columns in the Base Data layer. Each Raw layer table has a corresponding Base layer table except for the Receipts data which is split into two tables (one for higher level transaction data and other for item level transaction data) because the table becomes too wide if not split.
3. The Mart Data layer contains a table that is customized to contain only the columns and data that is frequently used to answer business questions.

## 2. Table setup:
A detailed relationship between the tables is provided in the ER diagram (refer [ER_diagram.pdf](https://github.com/Vidaan/rewards-receipt-analysis/blob/main/ER_diagram.pdf)).

#### T2_BRANDS_BASE:
Primary Key - barcode
Using barcode as a PK because it has reference in the Brands data and Receipts data. Also, most brands have one barcode for each brand.

#### T2_USERS_BASE:
Primary Key - user_id

#### T2_RECEIPTS_BASE:
Primary Key - receipt_id

#### T2_REWARDS_RECEIPT_ITEM_LIST:
Composite Key - receipt_id, item_index_num
Foreign Key - barcode

#### T3_USER_RECIPT_ITEM:
Foreign Key - receipt_id, user_id

## 3. Data Quality:
Some of the data quality checks employed are listed below. Refer to [4_data_quality_checks.sql](https://github.com/Vidaan/rewards-receipt-analysis/blob/main/4_data_quality_checks.sql) and [email_to_product_team](https://github.com/Vidaan/rewards-receipt-analysis/blob/main/email_to_product_team.pdf) files for more details.
1. Uniqueness test
2. Null values test
3. Non-negative test
4. Accepted Values test

## Summary:
It is possible to answer the current business questions based on the data provided but the overall data flow structure and efficiency of queries can be improved if some of the questions put forth to the product team get answered. Currently some redundant data that are being duplicated within some tables which can be avoided.
