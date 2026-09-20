{{ config(materialized='view') }}

with so_sexy as (

    select 
        customer_id, 
        name,
        '{{ var("start_date") }}'::DATE as start_date,
        '{{ var("string_value") }}' as fun_saying,
        100 - {{ var("max_count_value")}} as math,
        1 as my_number,
        2 as my_second_number
    from 
        {{ ref('stg_jaffle_shop__customers') }}
)

select * from so_sexy