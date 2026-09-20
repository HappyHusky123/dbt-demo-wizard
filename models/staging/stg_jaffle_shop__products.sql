with final as (

    select 
        sku,
        name as product_name,
        type as product_type,
        price as product_price,
        description as product_description
    from 
        {{ source('jaffle_shop', 'products')}}

)

select * from final 