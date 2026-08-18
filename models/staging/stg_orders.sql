{{ config(
    materialized='incremental',
    unique_key='event_id',
    incremental_strategy='merge'
) }}

WITH raw_orders AS (

    SELECT
        PARSE_JSON(data) AS data,
        _loaded_at,
        _source

    FROM {{ source('raw_streamcart', 'raw_orders') }}

    {% if is_incremental() %}

    WHERE _loaded_at > (
        SELECT MAX(_loaded_at)
        FROM {{ this }}
    )

    {% endif %}

),

deduplicated AS (

    SELECT

        data,
        _loaded_at,
        _source,

        ROW_NUMBER() OVER (

            PARTITION BY
                TRIM(data:event_id::STRING)

            ORDER BY
                _loaded_at DESC

        ) AS rn

    FROM raw_orders

),

latest_orders AS (

    SELECT *

    FROM deduplicated

    WHERE
        rn = 1

        AND LOWER(
            data:metadata:is_test_event::STRING
        ) <> 'true'

),

flatten_items AS (

    SELECT

        l.data,
        l._loaded_at,
        l._source,

        item.value AS item

    FROM latest_orders l,

    LATERAL FLATTEN(
        INPUT => l.data:order:items
    ) item

),

cleaned_orders AS (

    SELECT

        /* ==========================
           Incremental Metadata
        ========================== */

        _loaded_at,

        /* ==========================
           Event Information
        ========================== */

        TRIM(
            data:event_id::STRING
        ) AS event_id,

        CASE

            WHEN LOWER(
                TRIM(data:event_type::STRING)
            ) = 'order_placed'
                THEN 'order_placed'

            WHEN LOWER(
                TRIM(data:event_type::STRING)
            ) = 'order_cancelled'
                THEN 'order_cancelled'

            WHEN LOWER(
                TRIM(data:event_type::STRING)
            ) = 'add_to_cart'
                THEN 'add_to_cart'

            WHEN LOWER(
                TRIM(data:event_type::STRING)
            ) = 'checkout'
                THEN 'checkout'

            ELSE 'page_view'

        END AS event_type,

        TO_TIMESTAMP(
            data:occurred_at::STRING,
            'DD/MM/YYYY HH24:MI:SS'
        ) AS occurred_at,

        /* ==========================
           Customer Information
        ========================== */

        TRIM(
            data:customer:id::STRING
        ) AS customer_id,

        INITCAP(
            LOWER(
                TRIM(data:customer:name::STRING)
            )
        ) AS customer_name,

        LOWER(
            TRIM(data:customer:email::STRING)
        ) AS email,

        RIGHT(
            REGEXP_REPLACE(
                data:customer:phone::STRING,
                '[^0-9]',
                ''
            ),
            10
        ) AS phone,

        COALESCE(
            INITCAP(
                LOWER(data:customer:tier::STRING)
            ),
            'Standard'
        ) AS customer_tier,

        INITCAP(
            LOWER(
                data:customer:address:city::STRING
            )
        ) AS city,

        UPPER(
            TRIM(
                data:customer:address:country::STRING
            )
        ) AS country_code,

        /* ==========================
           Order Information
        ========================== */

        TRIM(
            data:order:order_id::STRING
        ) AS order_id,

        LOWER(
            REPLACE(
                TRIM(data:order:channel::STRING),
                ' ',
                '_'
            )
        ) AS channel,

        {{ parse_date_flexible(
            "data:order:placed_at::STRING",
            "DD/MM/YYYY",
            "YYYY-MM-DD"
        ) }} AS order_date,

        UPPER(
            TRIM(
                data:order:currency::STRING
            )
        ) AS currency_code,

        {{ clean_amount(
            "data:order:total_amount::STRING"
        ) }} AS order_total,

        item,

        data

    FROM flatten_items

),

item_details AS (

    SELECT

        /* ==========================
           Incremental Metadata
        ========================== */

        _loaded_at,

        /* ==========================
           Event Information
        ========================== */

        event_id,
        event_type,
        occurred_at,

        customer_id,
        customer_name,
        email,
        phone,
        customer_tier,
        city,
        country_code,

        order_id,
        channel,
        order_date,
        currency_code,
        order_total,

        /* ==========================
           Item Details
        ========================== */

        TRIM(
            item:product_id::STRING
        ) AS product_id,

        CASE

            WHEN TRY_TO_NUMBER(
                item:qty::STRING
            ) IS NULL
                THEN NULL

            WHEN TRY_TO_NUMBER(
                item:qty::STRING
            ) = 0
                THEN NULL

            ELSE TRY_TO_NUMBER(
                item:qty::STRING
            )

        END AS quantity,

        {{ clean_amount(
            "item:unit_price::STRING"
        ) }} AS unit_price,

        CASE

            WHEN TRY_TO_NUMBER(
                item:discount_pct::STRING
            ) > 60
                THEN NULL

            ELSE TRY_TO_NUMBER(
                item:discount_pct::STRING
            )

        END AS discount_pct,

        /* ==========================
           Payment Details
        ========================== */

        LOWER(
            REPLACE(
                TRIM(
                    data:order:payment:method::STRING
                ),
                ' ',
                '_'
            )
        ) AS payment_method,

        LOWER(
            TRIM(
                data:order:payment:status::STRING
            )
        ) AS payment_status

    FROM cleaned_orders

),

final AS (

    SELECT

        /* ==========================
           Incremental Metadata
        ========================== */

        _loaded_at,

        /* ==========================
           Event Information
        ========================== */

        event_id,
        event_type,
        occurred_at,

        customer_id,

        {% if target.name == 'prod' %}

        customer_name,
        email,

        {% else %}

        customer_name,
        email,

        {% endif %}

        phone,
        customer_tier,
        city,
        country_code,

        /* ==========================
           Order Information
        ========================== */

        order_id,
        channel,
        order_date,
        currency_code,
        order_total,

        /* ==========================
           Item Information
        ========================== */

        product_id,
        quantity,
        unit_price,
        discount_pct,

        /* ==========================
           Payment Information
        ========================== */

        payment_method,
        payment_status,

        /* ==========================
           Derived Columns
        ========================== */

        CASE

            WHEN quantity IS NULL
                OR unit_price IS NULL

                THEN NULL

            ELSE quantity * unit_price

        END AS gross_amount,

        {{ safe_net_amount(
            "quantity * unit_price",
            "discount_pct"
        ) }} AS net_amount

    FROM item_details

)

SELECT

    /* ==========================
       Incremental Metadata
    ========================== */

    _loaded_at,

    /* ==========================
       Final Output
    ========================== */

    event_id,
    event_type,
    occurred_at,

    customer_id,
    customer_name,
    email,
    phone,
    customer_tier,
    city,
    country_code,

    order_id,
    channel,
    order_date,
    currency_code,
    order_total,

    product_id,
    quantity,
    unit_price,
    discount_pct,

    payment_method,
    payment_status,

    gross_amount,
    net_amount

FROM final