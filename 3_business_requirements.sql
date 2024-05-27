/*
Business Questions:
1. What are the top 5 brands by receipts scanned for most recent month?
2. How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
3. When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
4. When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
5. Which brand has the most spend among users who were created within the past 6 months?
6. Which brand has the most transactions among users who were created within the past 6 months?
*/
--=============================================================================================================================================

-- 1 and 2

WITH 
    -- getting list of all receipts processed in the last 3 months
link_receipt_item AS (
    SELECT 
        RECEIPT_ID, 
        (YEAR(DATESCANNED) || '-' || MONTHNAME(DATESCANNED)) AS year_mon, 
        brand,
    FROM T3_USER_RECEIPT_ITEM
    WHERE (YEAR(DATESCANNED) || '-' || MONTH(DATESCANNED)) IN ('2021-3','2021-2', '2021-1') AND TRIM(BRAND) NOT IN ('ITEM', 'DELETED', '')
),

    -- Gives the number of times a brand was mentioned within the receipt.
    -- This is a pre-process to get 1 to 1 mapping of a brand and its receipt.
brand_in_receipt as (
    SELECT year_mon, RECEIPT_ID, BRAND, COUNT(BRAND) AS num_repeats
    FROM link_receipt_item 
    GROUP BY year_mon, RECEIPT_ID, BRAND
),

    -- Gives the number of times a brand was mentioned across receipts
    -- Returning only top 5 brands for each month
rank_brand AS (
    SELECT year_mon, BRAND, COUNT(BRAND) as num_occurances, RANK() OVER (PARTITION BY YEAR_MON ORDER BY COUNT(BRAND) DESC) as rk
    FROM brand_in_receipt
    GROUP BY year_mon, BRAND
    QUALIFY rk <=5
)

    -- Using three months data because Mar 2021 has just 1 days data which may not be reflective of the overall month.
SELECT 
    BRAND, 
    MIN(CASE WHEN YEAR_MON = '2021-Mar' THEN RK END) AS "Rank_in_2021_Mar",
    MIN(CASE WHEN YEAR_MON = '2021-Feb' THEN RK END) AS "Rank_in_2021_Feb",
    MIN(CASE WHEN YEAR_MON = '2021-Jan' THEN RK END) AS "Rank_in_2021_Jan"
FROM rank_brand
PIVOT(YEAR_MON)
GROUP BY BRAND;

--===================================================================================================================================

-- 5 and 6

WITH 
    -- getting list of users with create date in last 6 months
users_list AS (
    SELECT USER_ID, DATE(MAX(CREATEDDATE))
    FROM T2_USERS_BASE
    WHERE DATE(CREATEDDATE) > (SELECT DATEADD(MONTH, -6, DATE(MAX(CREATEDDATE))) FROM T2_USERS_BASE)
    GROUP BY user_id
),

    -- getting brand and final price
user_brand_map AS (
    SELECT BRAND, FINALPRICE
    FROM T3_USER_RECEIPT_ITEM uri
    WHERE uri.USER_ID IN (SELECT USER_ID FROM users_list) AND BRAND IS NOT NULL AND TRIM(BRAND) <> ''
),

    -- calcualting transactions and money spent per brand and ranking them
brands_ranking AS (
SELECT 
    BRAND, 
    COUNT(*) AS num_transactions,
    RANK() OVER(ORDER BY num_transactions DESC) AS transaction_rank,
    TO_NUMBER(SUM(FINALPRICE),10,2) AS money_spent_usd,
    RANK() OVER(ORDER BY money_spent_usd DESC) AS spending_rank
FROM user_brand_map ubm
GROUP BY BRAND
)

SELECT *
FROM brands_ranking
WHERE transaction_rank = 1 OR spending_rank = 1;



