
 {{ config(materialized='table',
 schema='gold') }}


SELECT
    invoice_month             AS revenue_month,
    invoice_year                    AS year,
    invoice_month                   AS month,
    invoice_quarter                 AS quarter,
    COUNT(DISTINCT invoice_id)      AS total_invoices,
    COUNT(DISTINCT customer_id)     AS unique_customers,
    COUNT(*)                        AS total_transactions,
    SUM(quantity)                   AS total_units_sold,
    ROUND(SUM(total_amount), 2)     AS total_revenue,
    ROUND(AVG(total_amount), 2)     AS avg_transaction_value,
    ROUND(
        SUM(total_amount) /
        COUNT(DISTINCT invoice_id), 2
    )                               AS avg_invoice_value
FROM {{ ref('gold_fact_transactions') }}
GROUP BY
    --invoice_month_start,
    invoice_year,
    invoice_month,
    invoice_quarter
ORDER BY revenue_month