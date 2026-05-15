{{ config(materialized='table',
 schema='gold') }}


WITH fact AS (
    SELECT *
    FROM {{ ref('gold_fact_transactions') }}
),

customers AS (
    SELECT *
    FROM {{ ref('gold_dim_customers') }}
)

SELECT
    f.invoice_id,
    f.invoice_date,
    f.customer_id,
    c.country,
    c.market_type,
    --c.customer_segment,
    COUNT(*)                        AS total_line_items,
    SUM(f.quantity)                 AS total_units,
    ROUND(SUM(f.total_amount), 2)   AS invoice_total,
    ROUND(AVG(f.unit_price), 2)     AS avg_unit_price,

    CASE
        WHEN SUM(f.total_amount) >= 1000 THEN 'High Value'
        WHEN SUM(f.total_amount) >= 500  THEN 'Mid Value'
        ELSE                                  'Low Value'
    END                             AS invoice_value_band

FROM fact f
LEFT JOIN customers c
    ON f.customer_key = c.customer_key
GROUP BY
    f.invoice_id,
    f.invoice_date,
    f.customer_id,
    c.country,
    c.market_type
    --c.customer_segment
ORDER BY invoice_date DESC