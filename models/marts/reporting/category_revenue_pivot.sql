{% set categories = ['Electronics', 'Apparel', 'Home Goods'] %}

WITH customer_category_revenue AS (

    SELECT
        o.customer_id,
        p.category,
        SUM(o.net_amount) AS net_revenue

    FROM {{ ref('stg_orders') }} o

    INNER JOIN {{ ref('stg_products') }} p
        ON o.product_id = p.product_id

    WHERE o.payment_status = 'success'

    GROUP BY
        o.customer_id,
        p.category

)

SELECT

    customer_id,

    {% for cat in categories %}

    SUM(
        CASE
            WHEN category = '{{ cat }}'
            THEN net_revenue
            ELSE 0
        END
    ) AS {{ cat | lower | replace(' ', '_') }}_revenue

    {% if not loop.last %},{% endif %}

    {% endfor %}

FROM customer_category_revenue

GROUP BY customer_id