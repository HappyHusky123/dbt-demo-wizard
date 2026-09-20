with all_orders as (

    select 
        order_id,
        product_name,
        order_total,
        order_total - 10 as total_minus_fee
    from 
        {{ ref("int_product_orders") }}

)

select * from all_orders