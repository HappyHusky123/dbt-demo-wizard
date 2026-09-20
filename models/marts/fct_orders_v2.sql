with orders as (

    select 
        order_id
        ,customer_id
        ,store_id
        ,ordered_at
        ,tax_paid
        ,subtotal
        ,order_total
    
    from {{ ref('stg_jaffle_shop__orders') }}

), stores as (

    select 
        store_id
        ,city_name
        ,opened_at 
        ,tax_rate
    
    from {{ ref('stg_jaffle_shop__stores') }}

), transformed as (

    select
        orders.order_id
        ,orders.customer_id
        ,orders.store_id
        ,orders.ordered_at
        ,orders.tax_paid
        ,orders.subtotal
        ,orders.order_total as order_amount
        ,orders.ordered_at::date as location_ordered_at
        ,stores.city_name
    from 
        orders
    inner join
        stores
    on
        orders.store_id = stores.store_id

)

select * from transformed