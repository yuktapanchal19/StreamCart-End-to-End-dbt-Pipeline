{{ config(
    materialized='incremental',
    unique_key='order_line_key',
    incremental_strategy='merge',
    on_schema_change='sync_all_columns',
    cluster_by=['order_date'],

    post_hook=[
        "ALTER TABLE {{ this }} RESUME RECLUSTER",
        "{% if target.name == 'prod' %} GRANT SELECT ON {{ this }} TO ROLE prod_reader {% endif %}"
    ]
) }}

WITH enriched_orders AS (

    SELECT

        o.*,

        cm.channel_label,
        cm.channel_group,
        cm.is_digital

    FROM {{ ref('int_orders_enriched') }} o

    LEFT JOIN {{ ref('channel_mapping') }} cm

        ON o.channel = cm.channel_code

    {% if is_incremental() %}

    WHERE o.order_date > (
        SELECT MAX(order_date)
        FROM {{ this }}
    )

    {% endif %}

),

final AS (

    SELECT

        event_id,
        order_id,
        customer_id,
        product_id,
        order_date,

        channel,
        channel_label,
        channel_group,
        is_digital,

        currency_code,
        payment_method,
        payment_status,

        quantity,
        unit_price,
        discount_pct,
        gross_amount,
        net_amount,

        customer_name,
        customer_tier,
        city,

        product_name,
        category,
        sub_category,
        brand,

        margin_pct,
        is_low_stock,

        {{ dbt_utils.generate_surrogate_key([
            'order_id',
            'product_id'
        ]) }} AS order_line_key

        {% if var('show_margin', false) %},

        margin_pct *
        (
            1 - COALESCE(discount_pct, 0) / 100
        ) AS effective_margin_pct

        {% endif %}

    FROM enriched_orders

)

SELECT *

FROM final