with all_orders as (

    select 
        order_id,
        customer_id,
        product_name,
        order_total
    from 
        {{ ref("int_product_orders") }}

)

select * from all_orders