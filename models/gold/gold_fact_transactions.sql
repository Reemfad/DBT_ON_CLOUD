{{ config(materialized='table',
 schema='gold') }}

WITH transactions AS (
    SELECT *
    FROM {{ ref('silver_transactions') }}
),

customers AS (
    SELECT customer_id, customer_key
    FROM {{ ref('gold_dim_customers') }}
),

products AS (
    SELECT stock_code, product_key
    FROM {{ ref('gold_dim_products') }}
),

orders AS (
    SELECT order_id, order_key
    FROM {{ ref('gold_dim_orders') }}
),

dates AS (
    SELECT full_date, date_key
    FROM {{ ref('gold_dim_date') }}
)

SELECT
    -- SURROGATE KEY
    t.transaction_key,

    -- FOREIGN KEYS TO DIMENSIONS
    c.customer_key,
    p.product_key,
    o.order_key,
    d.date_key,

    -- NATURAL KEYS (kept for traceability)
    t.invoice_id,
    t.stock_code,
    t.customer_id,
    t.order_id,

    -- MEASURES
    t.quantity,
    t.unit_price,
    t.total_amount,

    -- CATEGORISATIONS
    t.volume_category,
    t.price_category,

    -- DATES
    t.invoice_date,
    t.invoice_day,
    t.invoice_year,
    t.invoice_month,
    t.invoice_quarter,

    -- AUDIT
    t.source_sheet
    --t._source_system,
    --t._ingestion_ts

FROM transactions t
WHERE c.customer_key IS NOT NULL 
LEFT JOIN customers c ON t.customer_id  = c.customer_id
LEFT JOIN products  p ON t.stock_code   = p.stock_code
LEFT JOIN orders    o ON t.order_id     = o.order_id
LEFT JOIN dates     d ON t.invoice_day  = d.full_date