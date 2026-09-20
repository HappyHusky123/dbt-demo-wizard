{{ config(materialized='view', meta={"contains_pii":true}) }}

with products as (

    select 
        sku,
        product_name,
        product_type,
        product_price,
        product_description
    from 
        {{ ref('stg_jaffle_shop__products')}}

), orders as (

        select         
        order_id
        ,customer_id
        ,store_id
        ,ordered_at
        ,tax_paid
        ,subtotal
        ,order_total
    from {{ ref('stg_jaffle_shop__orders') }}

), items as (

    select 
        item_id,
        order_id,
        product_sku
    from {{ ref('stg_jaffle_shop__items') }}

), product_orders as (

    select 
        orders.order_id,
        orders.customer_id,
        products.product_name,
        orders.order_total
    from 
        items
    inner join
        orders
    on 
        items.order_id = orders.order_id
    inner join
        products 
    on 
        products.sku = items.product_sku

) 

select * from product_orders 