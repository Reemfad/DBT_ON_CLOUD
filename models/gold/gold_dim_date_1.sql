{{ config(materialized='table', schema='gold') }}


WITH date_spine AS (
    SELECT
        EXPLODE(
            SEQUENCE(
                DATE_TRUNC('hour', MIN(invoice_date)),
                DATE_TRUNC('hour', MAX(invoice_date)),
                INTERVAL 1 HOUR
            )
        ) AS datetime
    FROM {{ ref('silver_transactions') }}
    WHERE invoice_date IS NOT NULL
),

final AS (
    SELECT
        -- SURROGATE KEY
        {{ dbt_utils.generate_surrogate_key(['datetime']) }}
                                        AS date_key,

        -- FULL DATETIME
        datetime                        AS full_datetime,

        -- DATE PARTS
        CAST(DATE(datetime) AS DATE)    AS full_date,
        YEAR(datetime)                  AS year,
        QUARTER(datetime)               AS quarter,
        MONTH(datetime)                 AS month,
        MONTHNAME(datetime)             AS month_name,
        DAY(datetime)                   AS day,
        DAYOFWEEK(datetime)             AS day_of_week,
        DAYNAME(datetime)               AS day_name,
        HOUR(datetime)                  AS hour,

        -- HOUR LABEL for Power BI display
        CONCAT(
            LPAD(CAST(HOUR(datetime) AS STRING), 2, '0'),
            ':00'
        )                               AS hour_label,

        -- DATE TRUNCATIONS
        DATE_TRUNC('hour',    datetime) AS hour_start,
        DATE_TRUNC('day',     datetime) AS day_start,
        DATE_TRUNC('month',   datetime) AS month_start,
        DATE_TRUNC('quarter', datetime) AS quarter_start,
        DATE_TRUNC('year',    datetime) AS year_start,

        -- FLAGS
        CASE
            WHEN DAYOFWEEK(datetime) IN (1, 7)
            THEN TRUE
            ELSE FALSE
        END                             AS is_weekend,

        CASE
            WHEN HOUR(datetime) BETWEEN 9 AND 17
            THEN 'Business Hours'
            WHEN HOUR(datetime) BETWEEN 18 AND 21
            THEN 'Evening'
            ELSE 'Off Hours'
        END                             AS time_of_day_category

    FROM date_spine
)

SELECT * FROM final