WITH channel_revenue AS (

    SELECT

        customer_id,
        channel,
        SUM(net_amount) AS revenue

    FROM {{ ref('fct_orders') }}

    GROUP BY
        customer_id,
        channel

)

SELECT

    customer_id,

    {{ dbt_utils.pivot(
        'channel',
        ['mobile_app', 'web', 'partner_api'],
        agg='sum',
        then_value='revenue',
        else_value=0,
        prefix='',
        suffix='_revenue'
    ) }}

FROM channel_revenue

GROUP BY customer_id