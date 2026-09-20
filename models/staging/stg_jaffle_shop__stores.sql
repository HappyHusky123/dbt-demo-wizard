with

source as (

    select 
        id as store_id
        ,name as city_name
        ,opened_at 
        ,tax_rate
    
    from {{ source('jaffle_shop', 'stores') }}

)

select * from source