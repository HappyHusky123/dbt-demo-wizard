{#
    Fails when the average of a column, optionally within each group, is at or
    below a floor.

    Useful on measures where a single bad row is noise but a whole group tipping
    negative means the upstream logic broke. A not_null test cannot catch a
    margin calculation that started subtracting the wrong column; this can.

    Usage:

      columns:
        - name: gross_margin_amount
          data_tests:
            - expect_average_greater_than:
                min_value: -50
                group_by_column: sold_date_key
#}

{% test expect_average_greater_than(model, column_name, min_value=0, group_by_column=none) %}

with measured as (

    select
        {% if group_by_column %}
        {{ group_by_column }} as group_value,
        {% else %}
        1 as group_value,
        {% endif %}
        avg({{ column_name }}) as average_value

    from {{ model }}
    group by 1

)

select
    group_value,
    average_value

from measured
where average_value <= {{ min_value }}

{% endtest %}
