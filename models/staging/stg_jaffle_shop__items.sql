with items as (

    select
        id as item_id,
        order_id,
        sku as product_sku
    from
        {{ source('jaffle_shop', 'items') }}

)

select * from items