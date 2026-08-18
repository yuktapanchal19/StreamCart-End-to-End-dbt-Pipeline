{% macro clean_amount(col) %}

TRY_TO_DECIMAL(

    REPLACE(

        REPLACE(

            TRIM({{ col }}),

            '$',

            ''

        ),

        ',',

        ''

    ),

12,

2

)

{% endmacro %}