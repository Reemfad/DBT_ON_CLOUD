{{ config(materialized='table',
 schema='gold') }}

WITH fact AS (
    SELECT *
    FROM {{ ref('gold_fact_transactions') }}
),

orders AS (
    SELECT *
    FROM {{ ref('gold_dim_orders') }}
)

SELECT
    o.order_key,
    o.order_id,
    o.order_status,
    o.order_status_group,
    o.is_late_delivery,
    o.delivery_delay_days,
    o.fulfillment_days,
    o.order_approved_at,
    o.estimated_delivery_at,
    o.delivered_to_customer_at,
    COUNT(DISTINCT f.invoice_id)    AS invoices_per_order,
    SUM(f.quantity)                 AS total_units,
    ROUND(SUM(f.total_amount), 2)   AS order_revenue
FROM orders o
LEFT JOIN fact f
    ON o.order_key = f.order_key
GROUP BY
    o.order_key,
    o.order_id,
    o.order_status,
    o.order_status_group,
    o.is_late_delivery,
    o.delivery_delay_days,
    o.fulfillment_days,
    o.order_approved_at,
    o.estimated_delivery_at,
    o.delivered_to_customer_at
ORDER BY o.order_approved_at DESC