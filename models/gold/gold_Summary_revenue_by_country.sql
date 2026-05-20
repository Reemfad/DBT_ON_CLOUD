{{ config(materialized='table',
 schema='gold') }}


WITH fact AS (
    SELECT *
    FROM {{ ref('gold_fact_transactions') }}
),

dim_customers AS (
    SELECT *
    FROM {{ ref('gold_dim_customers') }}
)

SELECT
    c.country  ,
    c.market_type,
    COUNT(DISTINCT f.invoice_id)        AS total_invoices,
    COUNT(DISTINCT f.customer_id)       AS total_customers,
    COUNT(*)                            AS total_transactions,
    SUM(f.quantity)                     AS total_units_sold,
    ROUND(SUM(f.total_amount), 2)       AS total_revenue,
    ROUND(AVG(f.total_amount), 2)       AS avg_transaction_value,
    ROUND(
        SUM(f.total_amount) /
        COUNT(DISTINCT f.customer_id), 2
    --WHERE country IS NOT NULL 
    )                                   AS revenue_per_customer
FROM fact f

LEFT JOIN dim_customers c
    ON f.customer_key = c.customer_key
    WHERE c.country IS NOT NULL
GROUP BY
    
    c.country,
    c.market_type
