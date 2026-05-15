{{ config(materialized='table', schema='silver') }}
WITH source AS (
    SELECT *
    FROM {{ source('bronze', 'orders') }}
),

-- DATA QUALITY: remove structurally invalid orders
validated AS (
    SELECT *
    FROM source
    WHERE order_id      IS NOT NULL
      AND order_id      != ''
      AND order_status  IS NOT NULL
      AND order_status  != ''
),

-- DATA QUALITY: deduplicate keeping most recent version of each order
deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY order_approved_at DESC
        ) AS row_num
    FROM validated
),

final AS (
    SELECT
        -- SURROGATE KEY
        {{ dbt_utils.generate_surrogate_key(['order_id']) }}
                                                        AS order_key,

        -- NATURAL KEY
        CAST(order_id           AS STRING)              AS order_id,

        -- CLEANING: standardise status to lowercase
        LOWER(TRIM(order_status))                       AS order_status,

        -- TYPED DATE COLUMNS
        CAST(order_approved_at
                                AS TIMESTAMP)           AS order_approved_at,
        CAST(order_delivered_carrier_date
                                AS TIMESTAMP)           AS delivered_to_carrier_at,
        CAST(order_estimated_delivered_date
                                AS TIMESTAMP)           AS estimated_delivery_at,
        CAST(order_delivered_customer_date
                                AS TIMESTAMP)           AS delivered_to_customer_at,

        -- BUSINESS DERIVED COLUMNS

        -- was the order delivered late
        CASE
            WHEN order_delivered_customer_date IS NULL
            THEN NULL
            WHEN order_delivered_customer_date
                 > order_estimated_delivered_date
            THEN TRUE
            ELSE FALSE
        END                                             AS is_late_delivery,

        -- how many days late or early (positive = late, negative = early)
        CASE
            WHEN order_delivered_customer_date IS NULL
              OR order_estimated_delivered_date IS NULL
            THEN NULL
            ELSE DATEDIFF(
                    order_delivered_customer_date,
                    order_estimated_delivered_date
                 )
        END                                             AS delivery_delay_days,

        -- total days from order approval to customer receipt
        CASE
            WHEN order_delivered_customer_date IS NULL
              OR order_approved_at IS NULL
            THEN NULL
            ELSE DATEDIFF(
                    order_delivered_customer_date,
                    order_approved_at
                 )
        END                                             AS fulfillment_days,

        -- order status grouping for reporting
        CASE
            WHEN LOWER(TRIM(order_status)) = 'delivered'   THEN 'Completed'
            WHEN LOWER(TRIM(order_status)) IN (
                 'shipped', 'processing', 'invoiced')       THEN 'In Progress'
            WHEN LOWER(TRIM(order_status)) = 'cancelled'   THEN 'Cancelled'
            ELSE                                                 'Other'
        END                                             AS order_status_group,

        -- AUDIT COLUMNS
        source_file
        --_ingestion_ts

    FROM deduplicated
    WHERE row_num = 1
)

SELECT * FROM final