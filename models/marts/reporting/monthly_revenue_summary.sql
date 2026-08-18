WITH monthly_category AS (

    SELECT

        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        category,

        SUM(net_amount) AS category_net_revenue

    FROM {{ ref('fct_orders') }}

    WHERE payment_status = 'success'

    GROUP BY
        YEAR(order_date),
        MONTH(order_date),
        category

),

category_ranked AS (

    SELECT

        order_year,
        order_month,

        FIRST_VALUE(category) OVER (

            PARTITION BY order_year, order_month

            ORDER BY category_net_revenue DESC

        ) AS top_category

    FROM monthly_category

),

monthly_channel AS (

    SELECT

        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        channel,

        COUNT(DISTINCT order_id) AS channel_order_count

    FROM {{ ref('fct_orders') }}

    WHERE payment_status = 'success'

    GROUP BY
        YEAR(order_date),
        MONTH(order_date),
        channel

),

channel_ranked AS (

    SELECT

        order_year,
        order_month,

        FIRST_VALUE(channel) OVER (

            PARTITION BY order_year, order_month

            ORDER BY channel_order_count DESC

        ) AS top_channel

    FROM monthly_channel

),

monthly_totals AS (

    SELECT

        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,

        COUNT(DISTINCT order_id) AS total_orders,

        SUM(gross_amount) AS total_gross_revenue,

        SUM(net_amount) AS total_net_revenue,

        SUM(gross_amount - net_amount)
            AS total_discount_given,

        AVG(discount_pct) AS avg_discount_pct

    FROM {{ ref('fct_orders') }}

    WHERE payment_status = 'success'

    GROUP BY
        YEAR(order_date),
        MONTH(order_date)

)

SELECT

    m.order_year,
    m.order_month,

    m.total_orders,
    m.total_gross_revenue,
    m.total_net_revenue,
    m.total_discount_given,
    m.avg_discount_pct,

    c.top_category,
    ch.top_channel

FROM monthly_totals m

LEFT JOIN category_ranked c
    ON m.order_year = c.order_year
    AND m.order_month = c.order_month

LEFT JOIN channel_ranked ch
    ON m.order_year = ch.order_year
    AND m.order_month = ch.order_month

QUALIFY ROW_NUMBER() OVER (
    PARTITION BY m.order_year, m.order_month
    ORDER BY m.order_year
) = 1