{% macro safe_net_amount(gross, disc) %}

ROUND(

    {{ gross }}

    *

    (

        1 -

        COALESCE({{ disc }},0)

        /100

    ),

    2

)

{% endmacro %}