SELECT
    o.*,

    p.product_name,
    p.category,
    p.sub_category,
    p.brand,
    p.margin_pct,
    p.is_low_stock,

    CASE
        WHEN o.discount_pct > 0 THEN TRUE
        ELSE FALSE
    END AS is_discounted

FROM {{ ref('stg_orders') }} AS o

INNER JOIN {{ ref('stg_products') }} AS p
    ON o.product_id = p.product_id

WHERE o.event_type = 'order_placed'