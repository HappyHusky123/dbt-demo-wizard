with source as (

    select * from {{ source('stripe', 'payment') }}

)

select * from source 