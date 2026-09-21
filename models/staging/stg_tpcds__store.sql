{#
    Physical store dimension, renamed and typed. Roughly 1,000 rows.

    Two things worth knowing about this table:

    1. TPC-DS misspells the tax column as s_tax_precentage. The typo is fixed
       here so it never reaches CURATED or anything downstream of it.
    2. Like item, this carries a slowly changing type 2 history. Every version is
       kept for the same reason: store_sales joins on the surrogate key, which
       points at a specific version.
#}

with source as (

    select * from {{ source('tpcds', 'store') }}

),

renamed as (

    select
        -- keys
        s_store_sk                              as store_key,
        s_store_id                              as store_id,

        -- descriptive
        s_store_name                            as store_name,
        s_manager                               as store_manager_name,
        s_number_employees                      as employee_count,
        s_floor_space                           as floor_space_square_feet,
        s_hours                                 as operating_hours,

        -- organisational hierarchy
        s_market_id                             as market_id,
        s_market_desc                           as market_description,
        s_market_manager                        as market_manager_name,
        s_geography_class                       as geography_class,
        s_division_id                           as division_id,
        s_division_name                         as division_name,
        s_company_id                            as company_id,
        s_company_name                          as company_name,

        -- address
        s_street_number                         as street_number,
        s_street_name                           as street_name,
        s_street_type                           as street_type,
        s_suite_number                          as suite_number,
        s_city                                  as city_name,
        s_county                                as county_name,
        s_state                                 as state_code,
        s_zip                                   as postal_code,
        s_country                               as country_name,
        s_gmt_offset                            as gmt_offset,

        -- the benchmark spells this "precentage"
        cast(s_tax_precentage as number(5, 2))  as sales_tax_percentage,

        -- slowly changing dimension bounds
        cast(s_rec_start_date as date)          as record_start_date,
        cast(s_rec_end_date as date)            as record_end_date,
        s_closed_date_sk                        as closed_date_key

    from source

)

select * from renamed
