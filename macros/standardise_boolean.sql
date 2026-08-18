{% macro standardise_boolean(col) %}

CASE

    WHEN UPPER(TRIM({{ col }}))

         IN ('TRUE','1','YES','Y')

    THEN TRUE

    ELSE FALSE

END

{% endmacro %}