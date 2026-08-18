WITH product_sales AS (

    SELECT

        product_id,

        SUM(quantity) AS total_units_sold,

        SUM(net_amount) AS total_net_revenue,

        AVG(discount_pct) AS avg_discount_pct

    FROM {{ ref('fct_orders') }}

    WHERE payment_status = 'success'

    GROUP BY product_id

),

product_data AS (

    SELECT

        p.product_id,
        p.product_name,
        p.category,
        p.sub_category,
        p.brand,
        p.margin_pct,
        p.is_low_stock,

        COALESCE(
            s.total_units_sold,
            0
        ) AS total_units_sold,

        COALESCE(
            s.total_net_revenue,
            0
        ) AS total_net_revenue,

        s.avg_discount_pct,

        p.qty_on_hand,
        p.reorder_level,
        p.warehouse_code

    FROM {{ ref('stg_products') }} p

    LEFT JOIN product_sales s
        ON p.product_id = s.product_id

),

ranked AS (

    SELECT

        *,

        RANK() OVER (

            PARTITION BY category

            ORDER BY total_net_revenue DESC

        ) AS revenue_rank

    FROM product_data

)

SELECT *

FROM ranked