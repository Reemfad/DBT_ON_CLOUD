{{ config(materialized='table',
 schema='gold') }}


WITH fact AS (
    SELECT *
    FROM {{ ref('gold_fact_transactions') }}
),

products AS (
    SELECT *
    FROM {{ ref('gold_dim_products') }}
)

SELECT
    p.product_key,
    p.stock_code,
    p.description,
    p.price_category,
    COUNT(DISTINCT f.invoice_id)    AS times_invoiced,
    COUNT(DISTINCT f.customer_id)   AS unique_customers,
    SUM(f.quantity)                 AS total_units_sold,
    ROUND(SUM(f.total_amount), 2)   AS total_revenue,
    ROUND(AVG(f.unit_price), 2)     AS avg_unit_price,
    ROUND(AVG(f.total_amount), 2)   AS avg_transaction_value
FROM fact f
LEFT JOIN products p
    ON f.product_key = p.product_key
GROUP BY
    p.product_key,
    p.stock_code,
    p.description,
    p.price_category
ORDER BY total_revenue DESC