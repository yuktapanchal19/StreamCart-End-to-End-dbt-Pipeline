    WITH customer_with_country AS (

    SELECT

        c.*,

        cc.country_name,
        cc.region,
        cc.currency_default,
        cc.tax_rate_pct

    FROM {{ ref('int_customer_summary') }} c

    LEFT JOIN {{ ref('country_config') }} cc

        ON c.country_code = cc.country_code

)

SELECT

    customer_id,
    customer_name,
    email,
    phone,
    customer_tier,
    city,
    country_code,

    country_name,
    region,
    currency_default,
    tax_rate_pct,

    total_orders,
    total_gross_revenue,
    total_net_revenue,

    ROUND(
        {{ dbt_utils.safe_divide(
            "total_net_revenue",
            "total_orders"
        ) }},
        2
    ) AS avg_order_value,

    customer_segment,
    days_since_last_order

FROM customer_with_country