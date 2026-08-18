WITH daily_channel AS (

    SELECT

        order_date,
        channel,

        COUNT(DISTINCT order_id)
            AS total_orders,

        COUNT(
            DISTINCT CASE
                WHEN payment_status = 'success'
                THEN order_id
            END
        ) AS successful_orders,

        COUNT(
            DISTINCT CASE
                WHEN payment_status = 'cancelled'
                THEN order_id
            END
        ) AS cancelled_orders,

        SUM(
            CASE
                WHEN payment_status = 'success'
                THEN gross_amount
                ELSE 0
            END
        ) AS total_gross_revenue,

        SUM(
            CASE
                WHEN payment_status = 'success'
                THEN net_amount
                ELSE 0
            END
        ) AS total_net_revenue,

        AVG(
            CASE
                WHEN payment_status = 'success'
                THEN net_amount
            END
        ) AS avg_order_value

    FROM {{ ref('fct_orders') }}

    GROUP BY
        order_date,
        channel

),

payment_counts AS (

    SELECT

        order_date,
        channel,
        payment_method,

        COUNT(*) AS payment_count

    FROM {{ ref('fct_orders') }}

    WHERE payment_status = 'success'

    GROUP BY
        order_date,
        channel,
        payment_method

),

payment_ranked AS (

    SELECT

        order_date,
        channel,
        payment_method,

        ROW_NUMBER() OVER (

            PARTITION BY order_date, channel

            ORDER BY payment_count DESC, payment_method

        ) AS rn

    FROM payment_counts

)

SELECT

    d.order_date,
    d.channel,

    d.total_orders,
    d.successful_orders,
    d.cancelled_orders,

    ROUND(
        d.successful_orders
        / NULLIF(d.total_orders, 0) * 100,
        2
    ) AS success_rate_pct,

    d.total_gross_revenue,
    d.total_net_revenue,
    d.avg_order_value,

    p.payment_method
        AS most_used_payment_method

FROM daily_channel d

LEFT JOIN payment_ranked p

    ON d.order_date = p.order_date
    AND d.channel = p.channel
    AND p.rn = 1