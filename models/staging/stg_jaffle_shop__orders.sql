with

source as (

    select         
        id as order_id
        ,customer as customer_id
        ,store_id
        ,ordered_at
        ,tax_paid
        ,subtotal
        ,order_total
    from {{ source('jaffle_shop', 'orders') }}

)

select * from source