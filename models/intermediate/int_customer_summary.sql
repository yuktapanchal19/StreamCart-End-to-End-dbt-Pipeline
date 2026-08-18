WITH successful_orders AS (

    SELECT *
    FROM {{ ref('int_orders_enriched') }}

    WHERE payment_status = 'success'

),

customer_summary AS (

    SELECT

        customer_id,

        MAX(customer_name) AS customer_name,
        MAX(email) AS email,
        MAX(phone) AS phone,
        MAX(customer_tier) AS customer_tier,
        MAX(city) AS city,
        MAX(country_code) AS country_code,

        COUNT(DISTINCT order_id) AS total_orders,

        SUM(gross_amount) AS total_gross_revenue,

        SUM(net_amount) AS total_net_revenue,

        ROUND(
            {{ dbt_utils.safe_divide(
                "SUM(net_amount)",
                "COUNT(DISTINCT order_id)"
            ) }},
            2
        ) AS avg_order_value,

        DATEDIFF(
            'day',
            MAX(order_date),
            CURRENT_DATE
        ) AS days_since_last_order

    FROM successful_orders

    GROUP BY customer_id

)

SELECT

    customer_id,
    customer_name,
    email,
    phone,
    customer_tier,
    city,
    country_code,

    total_orders,
    total_gross_revenue,
    total_net_revenue,
    avg_order_value,

    CASE
        WHEN total_orders >= 10 THEN 'Platinum'
        WHEN total_orders >= 5 THEN 'Gold'
        WHEN total_orders >= 2 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_segment,

    days_since_last_order

FROM customer_summary