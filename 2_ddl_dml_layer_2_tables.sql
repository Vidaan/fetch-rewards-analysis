-- Tables in layer 1

SELECT * FROM T_BRANDS_JSON;
SELECT * FROM T_RECEIPTS_JSON;
SELECT * FROM T_USERS_JSON;

-- Tables in layer 2

SELECT * FROM T2_BRANDS_BASE;
SELECT * FROM T2_RECEIPTS_BASE;
SELECT * FROM T2_REWARDS_RECEIPT_ITEM_LIST;
SELECT * FROM T2_USERS_BASE;

-- Table in layer 3

SELECT * FROM T3_USER_RECEIPT_ITEM;

--===========================================================================================

-- DDL and DML


-- Layer 2

-- BRANDS

CREATE OR REPLACE TABLE T2_BRANDS_BASE AS (
  SELECT 
      PARSE_JSON(JSON_DATA:"_id"):"$oid"::VARCHAR as brand_id,
      JSON_DATA:"barcode"::VARCHAR as barcode,
      JSON_DATA:"category"::VARCHAR as category,
      JSON_DATA:"categoryCode"::VARCHAR as categoryCode,
      -- JSON_DATA:"cpg" as cpg,
      PARSE_JSON(PARSE_JSON(JSON_DATA:"cpg"):"$id"):"$oid"::VARCHAR as cpg_id_oid,
      PARSE_JSON(JSON_DATA:"cpg"):"$ref"::VARCHAR as cpg_ref,
      JSON_DATA:"name"::VARCHAR as name,
      JSON_DATA:"topBrand"::VARCHAR as topBrand,
      JSON_DATA:"brandCode"::VARCHAR as brandCode
  FROM T_BRANDS_JSON
);



-- RECEIPTS

SELECT * FROM T2_RECEIPTS_BASE;

CREATE OR REPLACE TABLE T2_RECEIPTS_BASE AS (
  SELECT 
      PARSE_JSON(JSON_DATA:"_id"):"$oid"::VARCHAR as receipt_id,
      JSON_DATA:"bonusPointsEarned"::NUMBER as bonusPointsEarned,
      JSON_DATA:"bonusPointsEarnedReason"::VARCHAR as bonusPointsEarnedReason,
      ((PARSE_JSON(JSON_DATA:"createDate"):"$date")::NUMBER/1000)::TIMESTAMP as createDate,
      ((PARSE_JSON(JSON_DATA:"dateScanned"):"$date")::NUMBER/1000)::TIMESTAMP as dateScanned,
      ((PARSE_JSON(JSON_DATA:"finishedDate"):"$date")::NUMBER/1000)::TIMESTAMP as finishedDate,
      ((PARSE_JSON(JSON_DATA:"modifyDate"):"$date")::NUMBER/1000)::TIMESTAMP as modifyDate,
      ((PARSE_JSON(JSON_DATA:"pointsAwardedDate"):"$date")::NUMBER/1000)::TIMESTAMP as pointsAwardedDate,
      JSON_DATA:"pointsEarned"::FLOAT as pointsEarned,
      ((PARSE_JSON(JSON_DATA:"purchaseDate"):"$date")::NUMBER/1000)::TIMESTAMP as purchaseDate,
      JSON_DATA:"purchasedItemCount"::NUMBER as purchasedItemCount,
      JSON_DATA:"rewardsReceiptStatus"::VARCHAR as rewardsReceiptStatus,
      JSON_DATA:"totalSpent"::FLOAT as totalSpent,
      JSON_DATA:"userId"::VARCHAR as user_id
  FROM T_RECEIPTS_JSON r
);


-- RECEIPTS AND ITEMS

CREATE OR REPLACE TABLE T2_REWARDS_RECEIPT_ITEM_LIST AS (
  with itemwise as (
  SELECT 
      PARSE_JSON(JSON_DATA:"_id"):"$oid" as receipt_id,
      TO_JSON(JSON_DATA:"rewardsReceiptItemList") as rewardsReceiptItemList,
      f.index AS index_num,
      f.value AS json_substr
  FROM  T_RECEIPTS_JSON r,
  LATERAL FLATTEN(INPUT => r.JSON_DATA:"rewardsReceiptItemList") f
  ),
  
  item_description_wise as (
  SELECT 
      receipt_id,
      index_num,
      f.key AS key_desc,
      f.value AS key_val
  FROM  itemwise i,
  LATERAL FLATTEN(INPUT => json_substr, recursive => true) f
  ),
  
  item_features AS (
  SELECT *
  FROM item_description_wise 
  PIVOT(MAX (key_val) FOR key_desc IN 
  ('barcode',
  'description',
  'finalPrice',
  'itemPrice',
  'needsFetchReview',
  'partnerItemId',
  'preventTargetGapPoints',
  'quantityPurchased',
  'userFlaggedBarcode',
  'userFlaggedNewItem',
  'userFlaggedPrice',
  'userFlaggedQuantity',
  'needsFetchReviewReason',
  'pointsNotAwardedReason',
  'pointsPayerId',
  'rewardsGroup',
  'rewardsProductPartnerId',
  'userFlaggedDescription',
  'originalMetaBriteBarcode',
  'originalMetaBriteDescription',
  'brandCode',
  'competitorRewardsGroup',
  'discountedItemPrice',
  'originalReceiptItemText',
  'itemNumber',
  'originalMetaBriteQuantityPurchased',
  'pointsEarned',
  'targetPrice',
  'competitiveProduct',
  'originalFinalPrice',
  'originalMetaBriteItemPrice',
  'deleted',
  'priceAfterCoupon',
  'metabriteCampaignId'
  ))
  )
  
  
  SELECT 
      receipt_id::VARCHAR AS receipt_id, 
      index_num::NUMBER AS item_index_num,
      "'barcode'"::VARCHAR AS barcode,
      "'description'"::VARCHAR AS description,
      "'finalPrice'"::FLOAT AS finalPrice,
      "'itemPrice'"::FLOAT AS itemPrice,
      "'needsFetchReview'"::VARCHAR AS needsFetchReview,
      "'partnerItemId'"::VARCHAR AS partnerItemId,
      "'preventTargetGapPoints'"::VARCHAR AS preventTargetGapPoints,
      "'quantityPurchased'"::NUMBER AS quantityPurchased,
      "'userFlaggedBarcode'"::VARCHAR AS userFlaggedBarcode,
      "'userFlaggedNewItem'"::VARCHAR AS userFlaggedNewItem,
      "'userFlaggedPrice'"::FLOAT AS userFlaggedPrice,
      "'userFlaggedQuantity'"::NUMBER AS userFlaggedQuantity,
      "'needsFetchReviewReason'"::VARCHAR AS needsFetchReviewReason,
      "'pointsNotAwardedReason'"::VARCHAR AS pointsNotAwardedReason,
      "'pointsPayerId'"::VARCHAR AS pointsPayerId,
      "'rewardsGroup'"::VARCHAR AS rewardsGroup,
      "'rewardsProductPartnerId'"::VARCHAR AS rewardsProductPartnerId,
      "'userFlaggedDescription'"::VARCHAR AS userFlaggedDescription,
      "'originalMetaBriteBarcode'"::VARCHAR AS originalMetaBriteBarcode,
      "'originalMetaBriteDescription'"::VARCHAR AS originalMetaBriteDescription,
      "'brandCode'"::VARCHAR AS brandCode,
      "'competitorRewardsGroup'"::VARCHAR AS competitorRewardsGroup,
      "'discountedItemPrice'"::FLOAT AS discountedItemPrice,
      "'originalReceiptItemText'"::VARCHAR AS originalReceiptItemText,
      "'itemNumber'"::VARCHAR AS itemNumber,
      "'originalMetaBriteQuantityPurchased'"::NUMBER AS originalMetaBriteQuantityPurchased,
      "'pointsEarned'"::FLOAT AS pointsEarned,
      "'targetPrice'"::FLOAT AS targetPrice,
      "'competitiveProduct'"::VARCHAR AS competitiveProduct,
      "'originalFinalPrice'"::FLOAT AS originalFinalPrice,
      "'originalMetaBriteItemPrice'"::FLOAT AS originalMetaBriteItemPrice,
      "'deleted'"::VARCHAR AS deleted,
      "'priceAfterCoupon'"::FLOAT AS priceAfterCoupon,
      "'metabriteCampaignId'"::VARCHAR AS metabriteCampaignId
  
  FROM item_features
);


-- USERS

CREATE OR REPLACE TABLE T2_USERS_BASE AS (
  SELECT 
      PARSE_JSON(JSON_DATA:"_id"):"$oid"::VARCHAR AS user_id,
      JSON_DATA:"active"::VARCHAR AS active,
      ((PARSE_JSON(JSON_DATA:"createdDate"):"$date")::NUMBER/1000)::TIMESTAMP AS createdDate,
      ((PARSE_JSON(JSON_DATA:"lastLogin"):"$date")::NUMBER/1000)::TIMESTAMP AS lastLogin,
      JSON_DATA:"role"::VARCHAR AS user_role,
      JSON_DATA:"signUpSource"::VARCHAR AS signUpSource,
      JSON_DATA:"state"::VARCHAR AS state
  FROM T_USERS_JSON
);

--================================================================================================

-- Layer 3

-- USER AND RECEIPT DATA

CREATE OR REPLACE TABLE T3_USER_RECEIPT_ITEM AS (
    SELECT 
            rb.RECEIPT_ID, 
            rb.user_id,
            rb.createdate,
            rb.datescanned,
            rb.finisheddate,
            rb.modifydate,
            rb.pointsawardeddate,
            rb.purchasedate,
            CASE
                -- this logic can be replaced when the Brands table is updated with all possible barcodes and descriptions.
                WHEN BRANDCODE = 'BRAND' THEN UPPER(SPLIT_PART(rr.REWARDSGROUP, ' ', 1))    -- items with barcode as brand are mislabeled
                WHEN BRANDCODE IS NOT NULL THEN BRANDCODE                                   -- Using brandcode when it is not null 
                ELSE UPPER(SPLIT_PART(rr.DESCRIPTION, ' ', 1))                              -- Using the first word of the description when above two cases fail
            END AS brand,
            rr.finalprice,
            rr.itemprice
    FROM T2_RECEIPTS_BASE rb
    LEFT JOIN T2_REWARDS_RECEIPT_ITEM_LIST rr ON rr.receipt_id = rb.receipt_id
);
