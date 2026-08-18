{% snapshot product_price_snapshot %}
{{
    config(
        target_schema='snapshots',
        unique_key='product_id',
        strategy='check',
        check_cols=[
            'list_price',
            'is_available'
        ]
    )
}}
WITH raw_products AS (

    SELECT
        PARSE_JSON(data) AS data,
        _loaded_at
    FROM {{ source('raw_streamcart', 'raw_products') }}
),

products AS (
    SELECT
        TRIM(
            data:product_id::STRING
        ) AS product_id,

        TRIM(
            data:name::STRING
        ) AS product_name,

        TRY_TO_DOUBLE(
            data:pricing:list_price::STRING
        ) AS list_price,

        CASE
            WHEN UPPER(
                TRIM(
                    data:is_available::STRING
                )
            ) IN ('1', 'YES', 'TRUE')

            THEN TRUE
            ELSE FALSE
        END AS is_available,
        _loaded_at,
        ROW_NUMBER() OVER (
            PARTITION BY
                TRIM(data:product_id::STRING)
            ORDER BY
                _loaded_at DESC
        ) AS rn

    FROM raw_products
),
latest_products AS (
    SELECT
        product_id,
        product_name,
        list_price,
        is_available,
        _loaded_at

    FROM products

    WHERE rn = 1

)

SELECT *

FROM latest_products

{% endsnapshot %}