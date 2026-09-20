{{ config(materialized='table')}}

with customers_final as (

    select
        customer_id,
        name as customer_name,
        '{{ var("start_date") }}'::DATE as cus_start_date,
        100 - {{ var("max_count_value") }} as subtract_value,
        '{{ var("string_value") }}' as greeting
    from
        {{ ref('stg_jaffle_shop__customers') }}
)

select * from customers_final