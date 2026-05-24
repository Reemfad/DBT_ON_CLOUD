{{config(materialized='table', schema='silver') }}

WITH source AS (
    SELECT *
    FROM {{ source('bronze', 'customers') }}
),

-- DATA QUALITY: remove invalid customer records
validated AS (
    SELECT *
    FROM source
    WHERE Customer_id    IS NOT NULL
      AND try_cast(Customer_id AS STRING) != ''
      --AND Customer_id    != ''
      AND Country       IS NOT NULL
      AND Country       != ''
),

-- DATA QUALITY: deduplicate keeping most recent record per customer
deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY Customer_id
            ORDER BY (SELECT NULL)
        ) AS row_num
    FROM validated
),

final AS (
    SELECT
        -- SURROGATE KEY
        {{ dbt_utils.generate_surrogate_key(['Customer_id']) }}
                                                        AS customer_key,

        -- NATURAL KEY
        CAST(Customer_id     AS STRING)                  AS customer_id,

        -- CLEANING: title case, trim whitespace
        INITCAP(TRIM(Country))                          AS country,

        -- BUSINESS DERIVED COLUMNS
        CASE
            WHEN INITCAP(TRIM(Country)) = 'United Kingdom'
            THEN 'Domestic'
            ELSE 'International'
        END                                             AS market_type,

        UPPER(TRIM(Country))                            AS country_code_raw,

        -- AUDIT COLUMNS
        source_file
        --_ingestion_ts

    FROM deduplicated
    WHERE row_num = 1
)

SELECT * FROM final