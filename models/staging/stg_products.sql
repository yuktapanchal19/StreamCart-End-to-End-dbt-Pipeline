WITH raw_products AS (

    SELECT

        PARSE_JSON(data) AS data,

        _loaded_at,

        _source

    FROM {{ source('raw_streamcart','raw_products') }}

),

deduplicated AS (

    SELECT

        data,

        _loaded_at,

        _source,

        ROW_NUMBER() OVER (

            PARTITION BY
                TRIM(data:product_id::STRING)

            ORDER BY
                _loaded_at DESC

        ) AS rn

    FROM raw_products

),

latest_products AS (

    SELECT *

    FROM deduplicated

    WHERE rn = 1

),cleaned_products AS (

    SELECT

        /*=========================
          Product Details
        =========================*/

        TRIM(
            data:product_id::STRING
        ) AS product_id,

        TRIM(
            data:name::STRING
        ) AS product_name,

        INITCAP(
            LOWER(
                TRIM(data:category::STRING)
            )
        ) AS category,

        LOWER(
            TRIM(data:sub_category::STRING)
        ) AS sub_category,

        INITCAP(
            LOWER(
                TRIM(data:brand::STRING)
            )
        ) AS brand,

        {{ standardise_boolean("data:is_available::STRING") }} AS is_available,

        ARRAY_TO_STRING(

            data:tags,

            ','

        ) AS tags,

        TRY_TO_DOUBLE(
            data:specs:weight_kg::STRING
        ) AS weight_kg,

        TRY_TO_NUMBER(
            data:specs:warranty_yr::STRING
        ) AS warranty_years,

        TRY_TO_DOUBLE(
            data:pricing:cost_price::STRING
        ) AS cost_price,

        TRY_TO_DOUBLE(
            data:pricing:list_price::STRING
        ) AS list_price,

        TRY_TO_NUMBER(
            data:stock:qty_on_hand::STRING
        ) AS qty_on_hand,

        TRY_TO_NUMBER(
            data:stock:reorder_lvl::STRING
        ) AS reorder_level,

        UPPER(
            TRIM(
                data:stock:warehouse::STRING
            )
        ) AS warehouse_code

    FROM latest_products

),final AS (

    SELECT

        product_id,

        product_name,

        category,

        sub_category,

        brand,

        is_available,

        tags,

        weight_kg,

        warranty_years,

        cost_price,

        list_price,

        qty_on_hand,

        reorder_level,

        warehouse_code,

        /*=========================
          Derived Columns
        =========================*/

        ROUND(

            (

                list_price - cost_price

            )

            /

            NULLIF(list_price,0)

            *100,

            2

        ) AS margin_pct,

        CASE

            WHEN qty_on_hand <= reorder_level

            THEN TRUE

            ELSE FALSE

        END AS is_low_stock

    FROM cleaned_products

)

SELECT

    product_id,

    product_name,

    category,

    sub_category,

    brand,

    is_available,

    tags,

    weight_kg,

    warranty_years,

    cost_price,

    list_price,

    qty_on_hand,

    reorder_level,

    warehouse_code,

    margin_pct,

    is_low_stock

FROM final