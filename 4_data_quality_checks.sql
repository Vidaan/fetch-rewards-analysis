/*
Initial observations:

RECEIPTS table:
1. Number of items in "purchasedItemCount" column is not matching the number of items in "rewardsReceiptItemList".
2. Points Earned not matching values in "rewardsReceiptItemList".

T2_BRANDS_BASE:
1. Some categories do not have categorycode.
2. All baking, candy&sweets category brands are test ones.
3. Many items in Magazines category have a number in brandcode.

T2_USERS_BASE:
1. user_id is not unique.

T2_REWARDS_RECEIPT_ITEM_LIST:
1. Multiple brandcodes are labled as 'BRAND'.
*/



-- 1. Number of items in "purchasedItemCount" column is not matching the number of items in "rewardsReceiptItemList".
-- Question to business - Which quantity should be considered? Should the quantity purchased plus the quantity flagged in the reward receipt item list equal purchased item count on the receipt?
SELECT 
    rb.receipt_id, 
    rr.receipt_id, 
    rb.purchaseditemcount, 
    IFF(SUM(rr.quantitypurchased) IS NULL, 0, SUM(rr.quantitypurchased)) AS quantitypurchased,
    IFF(SUM(rr.userFlaggedQuantity) IS NULL, 0, SUM(rr.userFlaggedQuantity)) AS qty_flagged,
    (IFF(SUM(rr.quantitypurchased) IS NULL, 0, SUM(rr.quantitypurchased)) + IFF(SUM(rr.userFlaggedQuantity) IS NULL, 0, SUM(rr.userFlaggedQuantity))) AS total_qty,
    CASE 
        WHEN purchaseditemcount <> (SUM(rr.quantitypurchased) + SUM(rr.userFlaggedQuantity)) THEN 'MISMATCH'
        WHEN purchaseditemcount IS NOT NULL AND COUNT(rr.item_index_num) IS NULL THEN 'MISMATCH'
    END AS DATA_ISSUE
FROM T2_RECEIPTS_BASE rb
INNER JOIN T2_REWARDS_RECEIPT_ITEM_LIST rr ON rr.receipt_id = rb.receipt_id
GROUP BY rb.receipt_id, rr.receipt_id, rb.purchaseditemcount;


-- 2. Points earned should match the sum of points earned per item. Is this a valid assumption? If so, there are many that do not match.
SELECT 
    rb.receipt_id, 
    rr.receipt_id, 
    rb.pointsearned, 
    IFF(SUM(rr.POINTSEARNED) IS NULL, 0, SUM(rr.POINTSEARNED)) AS ITEM_POINTS_EARNED,
    CASE 
        WHEN rb.pointsearned <> SUM(rr.POINTSEARNED) THEN 'MISMATCH'
        WHEN rb.pointsearned IS NOT NULL AND SUM(rr.POINTSEARNED) IS NULL THEN 'MISMATCH'
    END AS DATA_ISSUE
FROM T2_RECEIPTS_BASE rb
INNER JOIN T2_REWARDS_RECEIPT_ITEM_LIST rr ON rr.receipt_id = rb.receipt_id
GROUP BY rb.receipt_id, rr.receipt_id, rb.pointsearned;

--========================================================================================================================================

-- Uniqueness test for the Primary keys and Composite keys based on the ER diagram

-- Observation - Duplicate values are present
SELECT user_id, COUNT(*) AS NUM_ROWS
FROM T2_USERS_BASE
GROUP BY user_id
HAVING NUM_ROWS > 1;

-- Observation - All receipt id's are unique.
SELECT receipt_id, COUNT(*) AS NUM_ROWS
FROM T2_RECEIPTS_BASE
GROUP BY receipt_id
HAVING NUM_ROWS > 1;

-- Observation - All receipt items are unique
SELECT COUNT(*) AS TOTAL_ROWS, COUNT(DISTINCT receipt_id, item_index_num) AS UNIQUE_RECEIPT_ITEMS
FROM T2_REWARDS_RECEIPT_ITEM_LIST;

-- Observation - Duplicate values are present
SELECT barcode, COUNT(*) AS NUM_ROWS
FROM T2_BRANDS_BASE
GROUP BY barcode
HAVING NUM_ROWS > 1;
-- The following barcodes have duplicates
-- Question to the business - Which brand_id should be considered in case of duplicates
SELECT *
FROM T2_BRANDS_BASE
WHERE BARCODE = '511111004790';
/*
511111204923
511111004790
511111504788
511111704140
511111305125
511111605058
511111504139
*/


--=============================================================================================================================

-- Null values test

-- Observation - There are null values in Category, Category Code, Brand Code columns
SELECT *
FROM T2_BRANDS_BASE
WHERE CATEGORYCODE IS NULL;


-- Observation - All baking, candy & sweets category brands are test ones.
-- Observation - Some rows under Magazines and Health & Wellness have Barcode in Brandcode. ex: 511111305125, 511111405696
SELECT *
FROM T2_BRANDS_BASE
WHERE LOWER(CATEGORY) IN ('baking', 'candy & sweets', 'magazines', 'health & wellness');


-- Observation - Some users have no state
-- Observation - There are nulls in Sign up source column
SELECT *
FROM T2_USERS_BASE
WHERE signupsource IS NULL OR state IS NULL;


--===========================================================================================================================

-- Non-negative test

-- Observation - All values are positive
SELECT *
FROM T2_RECEIPTS_BASE
WHERE TOTALSPENT < 0;

-- Observation - All values are positive
SELECT *
FROM T2_REWARDS_RECEIPT_ITEM_LIST
WHERE FINALPRICE < 0;

-- Observation - All values are positive
SELECT *
FROM T2_REWARDS_RECEIPT_ITEM_LIST
WHERE ITEMPRICE < 0;


--================================================================================================================

-- Accepted Values test

-- Some rows contain non-descriptive values in the Brandcode column
SELECT *
FROM T2_BRANDS_BASE
WHERE BRANDCODE LIKE('5111%') OR BRANDCODE LIKE ('TEST%') OR BRANDCODE IS NULL;


--=================================================================================================================

-- Insufficient data in base table
-- There are far fewer barcodes in Brands data not matching with barocdes in receipts
SELECT DISTINCT BARCODE
FROM  T2_REWARDS_RECEIPT_ITEM_LIST
WHERE BARCODE NOT IN (SELECT BARCODE FROM T2_BRANDS_BASE);


