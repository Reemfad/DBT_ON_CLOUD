{{ config(materialized='table',
 schema='gold') }}


WITH date_spine AS (
    SELECT
        EXPLODE(
            SEQUENCE(
                MIN(invoice_day),
                MAX(invoice_day),
                INTERVAL 1 DAY
            )
        ) AS date
    FROM {{ ref('silver_transactions') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['date']) }}
                                AS date_key,
    date                        AS full_date,
    YEAR(date)                  AS year,
    QUARTER(date)               AS quarter,
    MONTH(date)                 AS month,
    MONTHNAME(date)             AS month_name,
    DAY(date)                   AS day,
    DAYOFWEEK(date)             AS day_of_week,
    DAYNAME(date)               AS day_name,
    DATE_TRUNC('month', date)   AS month_start,
    DATE_TRUNC('quarter', date) AS quarter_start,
    DATE_TRUNC('year', date)    AS year_start,
    CASE
        WHEN DAYOFWEEK(date) IN (1, 7)
        THEN TRUE
        ELSE FALSE
    END                         AS is_weekend
FROM date_spine