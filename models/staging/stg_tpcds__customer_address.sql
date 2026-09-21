{#
    Address dimension, renamed and typed. Roughly 32.5 million rows at the
    10 TB scale factor.

    Referenced both by customer, as a current address, and by the fact tables,
    as the address a sale was billed to. Those are not always the same address.
#}

with source as (

    select * from {{ source('tpcds', 'customer_address') }}

),

renamed as (

    select
        -- keys
        ca_address_sk                       as customer_address_key,
        ca_address_id                       as customer_address_id,

        -- street
        ca_street_number                    as street_number,
        ca_street_name                      as street_name,
        ca_street_type                      as street_type,
        ca_suite_number                     as suite_number,

        -- region
        ca_city                             as city_name,
        ca_county                           as county_name,
        ca_state                            as state_code,
        ca_zip                              as postal_code,
        ca_country                          as country_name,

        -- attributes
        cast(ca_gmt_offset as number(5, 2)) as gmt_offset,
        ca_location_type                    as location_type

    from source

)

select * from renamed
