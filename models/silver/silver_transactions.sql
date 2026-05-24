{{ config(materialized='table', schema='silver') }}

WITH source AS (
    SELECT *
    FROM {{ source('bronze','transactions') }}
),

-- DATA QUALITY: remove structurally invalid rows
validated AS (
    SELECT *
    FROM source
    WHERE Invoice       IS NOT NULL
      AND Invoice       != ''
      AND StockCode     IS NOT NULL
      AND StockCode     != ''
      AND Quantity      IS NOT NULL
      AND Quantity      > 0
      AND Price         IS NOT NULL
      AND Price         >= 0
      AND InvoiceDate   IS NOT NULL
      AND Customer_id    IS NOT NULL
      AND try_cast(Customer_id AS STRING) != ''
      --AND Customer_id    != ''
      AND order_id      IS NOT NULL
      AND order_id      != ''
),

-- DATA QUALITY: remove duplicates keeping most recent ingestion
deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY Invoice, StockCode
            ORDER BY InvoiceDate DESC

        ) AS row_num
    FROM validated
),

-- CLEANING + TYPING + BUSINESS COLUMNS
final AS (
   
    SELECT 
        -- SURROGATE KEY
        {{ dbt_utils.generate_surrogate_key(
            ['Invoice', 'StockCode']
        ) }}                                            AS transaction_key,

        -- FOREIGN KEYS (links to dimension tables)
        CAST(Customer_id     AS STRING)                  AS customer_id,
        CAST(order_id       AS STRING)                  AS order_id,

        -- TRANSACTION IDENTIFIERS
        CAST(Invoice        AS STRING)                  AS invoice_id,
        CAST(StockCode      AS STRING)                  AS stock_code,

        -- CLEANING: strip quotes, trim whitespace, title case
        CASE
            WHEN Description IS NULL OR TRIM(Description) = ''
            THEN 'Unknown'
            ELSE INITCAP(
                    REGEXP_REPLACE(
                        TRIM(Description), '[\"]+', ''
                    )
                 )
        END                                             AS description,

        -- TYPED MEASURES
        CAST(Quantity       AS INT)                     AS quantity,
        CAST(Price          AS DOUBLE)                  AS unit_price,

        -- BUSINESS DERIVED COLUMNS
        CAST(Quantity * Price AS DOUBLE)                AS total_amount,

        CASE
            WHEN Quantity >= 100 THEN 'High Volume'
            WHEN Quantity >= 10  THEN 'Medium Volume'
            ELSE                      'Low Volume'
        END                                             AS volume_category,

        CASE
            WHEN Price >= 10 THEN 'Premium'
            WHEN Price >= 5  THEN 'Mid Range'
            ELSE                  'Budget'
        END                                             AS price_category,

        -- DATE BREAKDOWNS (used by gold_dim_date)
        CAST(InvoiceDate    AS TIMESTAMP)               AS invoice_date,
        CAST(DATE(InvoiceDate) AS DATE)                 AS invoice_day,
        YEAR(InvoiceDate)                               AS invoice_year,
        MONTH(InvoiceDate)                              AS invoice_month,
        DAYOFWEEK(InvoiceDate)                          AS invoice_day_of_week,
        DATE_TRUNC('month', InvoiceDate)                AS invoice_month_start,
        QUARTER(InvoiceDate)                            AS invoice_quarter,

        -- AUDIT COLUMNS
        CAST(Sheet          AS STRING)                  AS source_sheet
        --_source_system,
        --_ingestion_ts

    FROM deduplicated
    WHERE row_num = 1 
    -- AND transaction_key IS NOT NULL 
   -- WHERE transaction_key IS NOT Null 
)

SELECT * FROM final
WHERE transaction_key IS NOT Null