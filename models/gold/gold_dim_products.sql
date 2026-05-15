{{ config(materialized='table',schema='gold') }}

WITH ranked AS (
    SELECT
        stock_code,
        description,
        unit_price,
        price_category,
        ROW_NUMBER() OVER (
            PARTITION BY stock_code
            ORDER BY invoice_date  DESC
        ) AS row_num
    FROM {{ ref('silver_transactions') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['stock_code']) }}
                                AS product_key,
    stock_code,
    description,
    unit_price                  AS latest_unit_price,
    price_category
FROM ranked
WHERE row_num = 1