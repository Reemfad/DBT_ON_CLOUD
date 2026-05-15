{{ config(materialized='table', schema='gold') }}

SELECT
    customer_key,
    customer_id,
    country,
    market_type,
    source_file
    --_ingestion_ts
FROM {{ ref('silver_customer') }}
