{% snapshot customer_tier_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='_loaded_at'
    )
}}

WITH raw_orders AS (

    SELECT

        PARSE_JSON(data) AS data,
        _loaded_at

    FROM {{ source('raw_streamcart', 'raw_orders') }}

),

customer_states AS (

    SELECT

        TRIM(data:customer:id::STRING) AS customer_id,

        INITCAP(
            LOWER(
                TRIM(data:customer:name::STRING)
            )
        ) AS customer_name,

        COALESCE(
            INITCAP(
                LOWER(
                    data:customer:tier::STRING
                )
            ),
            'Standard'
        ) AS customer_tier,

        INITCAP(
            LOWER(
                data:customer:address:city::STRING
            )
        ) AS city,

        _loaded_at,

        ROW_NUMBER() OVER (

            PARTITION BY
                TRIM(data:customer:id::STRING)

            ORDER BY
                _loaded_at DESC

        ) AS rn

    FROM raw_orders

),
latest_customer_state AS (

    SELECT
        customer_id,
        customer_name,
        customer_tier,
        city,
        _loaded_at

    FROM customer_states

    WHERE rn = 1

)

SELECT *
FROM latest_customer_state

{% endsnapshot %}