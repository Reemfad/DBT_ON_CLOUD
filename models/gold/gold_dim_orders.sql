{{ config(materialized='table',schema='gold') }}

SELECT
    order_key,
    order_id,
    order_status,
    order_status_group,
    order_approved_at,
    delivered_to_carrier_at,
    estimated_delivery_at,
    delivered_to_customer_at,
    is_late_delivery,
    delivery_delay_days,
    fulfillment_days,
    source_file
    --_ingestion_ts
FROM {{ ref('silver_orders') }}