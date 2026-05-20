WITH null_checks AS (

    SELECT
        'silver_transactions'           AS table_name,
        'invoice_id'                    AS column_name,
        COUNT(*)                        AS total_rows,
        SUM(
            CASE WHEN invoice_id IS NULL
                 OR TRIM(invoice_id) = ''
            THEN 1 ELSE 0 END
        )                               AS null_or_empty_count
    FROM {{ ref('silver_transactions') }}

    UNION ALL

    SELECT
        'silver_transactions',
        'stock_code',
        COUNT(*),
        SUM(
            CASE WHEN stock_code IS NULL
                 OR TRIM(stock_code) = ''
            THEN 1 ELSE 0 END
        )
    FROM {{ ref('silver_transactions') }}

    UNION ALL

    SELECT
        'silver_transactions',
        'description',
        COUNT(*),
        SUM(
            CASE WHEN description IS NULL
                 OR TRIM(description) = ''
            THEN 1 ELSE 0 END
        )
    FROM {{ ref('silver_transactions') }}

    UNION ALL

    SELECT
        'silver_transactions',
        'customer_id',
        COUNT(*),
        SUM(
            CASE WHEN customer_id IS NULL
                 OR TRIM(customer_id) = ''
            THEN 1 ELSE 0 END
        )
    FROM {{ ref('silver_transactions') }}

    UNION ALL

    SELECT
        'silver_transactions',
        'order_id',
        COUNT(*),
        SUM(
            CASE WHEN order_id IS NULL
                 OR TRIM(order_id) = ''
            THEN 1 ELSE 0 END
        )
    FROM {{ ref('silver_transactions') }}

    UNION ALL

    SELECT
        'silver_transactions',
        'invoice_date',
        COUNT(*),
        SUM(
            CASE WHEN invoice_date IS NULL
            THEN 1 ELSE 0 END
        )
    FROM {{ ref('silver_transactions') }}

    UNION ALL

    SELECT
        'silver_transactions',
        'unit_price',
        COUNT(*),
        SUM(
            CASE WHEN unit_price IS NULL
            THEN 1 ELSE 0 END
        )
    FROM {{ ref('silver_transactions') }}

    UNION ALL

    SELECT
        'silver_transactions',
        'quantity',
        COUNT(*),
        SUM(
            CASE WHEN quantity IS NULL
            THEN 1 ELSE 0 END
        )
    FROM {{ ref('silver_transactions') }}
),

final AS (
    SELECT
        table_name,
        column_name,
        total_rows,
        null_or_empty_count,
        total_rows - null_or_empty_count        AS valid_count,
        ROUND(
            null_or_empty_count * 100.0
            / NULLIF(total_rows, 0), 2
        )                                       AS null_pct,
        ROUND(
            (total_rows - null_or_empty_count)
            * 100.0
            / NULLIF(total_rows, 0), 2
        )                                       AS valid_pct,

        -- LOG MESSAGE
        CONCAT(
            CAST(null_or_empty_count AS STRING),
            ' null or empty values were found in column [',
            column_name,
            '] out of ',
            CAST(total_rows AS STRING),
            ' total rows — ',
            CAST(
                ROUND(
                    null_or_empty_count * 100.0
                    / NULLIF(total_rows, 0), 2
                ) AS STRING
            ),
            '% affected'
        )                                       AS log_message,

        -- SEVERITY FLAG
        CASE
            WHEN null_or_empty_count = 0                    THEN 'PASS'
            WHEN null_or_empty_count * 100.0
                 / NULLIF(total_rows, 0) <= 5               THEN 'WARNING'
            WHEN null_or_empty_count * 100.0
                 / NULLIF(total_rows, 0) <= 20              THEN 'CRITICAL'
            ELSE                                                 'FAIL'
        END                                     AS severity,

        current_timestamp()                     AS checked_at

    FROM null_checks
)

SELECT * FROM final