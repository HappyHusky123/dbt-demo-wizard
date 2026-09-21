{#
    Divide without blowing up on a zero or null denominator.

    Rate and percentage calculations in the DATA_VIZ layer divide by counts and
    amounts that can legitimately be zero, for example a store with sales but no
    returns on a given day. Snowflake raises a division by zero error rather
    than returning null, which fails the whole model.
#}

{% macro safe_divide(numerator, denominator, default_value='null') -%}

    case
        when coalesce({{ denominator }}, 0) = 0 then {{ default_value }}
        else {{ numerator }} / {{ denominator }}
    end

{%- endmacro %}
