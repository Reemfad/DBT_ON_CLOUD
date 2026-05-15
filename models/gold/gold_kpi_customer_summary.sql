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
    c.customer_key,
    c.customer_id,
    c.country,
    c.market_type,
    COUNT(DISTINCT f.invoice_id)        AS total_invoices,
    COUNT(*)                            AS total_transactions,
    SUM(f.quantity)                     AS total_units_purchased,
    ROUND(SUM(f.total_amount), 2)       AS total_spend,
    ROUND(AVG(f.total_amount), 2)       AS avg_transaction_value,
    ROUND(
        SUM(f.total_amount) /
        COUNT(DISTINCT f.invoice_id), 2
    )                                   AS avg_invoice_value,
    MIN(f.invoice_date)                 AS first_purchase_date,
    MAX(f.invoice_date)                 AS last_purchase_date,
    DATEDIFF(
        MAX(f.invoice_date),
        MIN(f.invoice_date)
    )                                   AS customer_lifetime_days,

    -- CUSTOMER SEGMENT based on total spend
    CASE
        WHEN SUM(f.total_amount) >= 10000 THEN 'VIP'
        WHEN SUM(f.total_amount) >= 5000  THEN 'Loyal'
        WHEN SUM(f.total_amount) >= 1000  THEN 'Regular'
        ELSE                                   'Occasional'
    END                                 AS customer_segment

FROM customers c
LEFT JOIN fact f
    ON c.customer_key = f.customer_key
GROUP BY
    c.customer_key,
    c.customer_id,
    c.country,
    c.market_type
ORDER BY total_spend DESC