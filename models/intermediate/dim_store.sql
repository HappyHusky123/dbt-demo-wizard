{#
    Store dimension.

    Two pieces of business logic live here:

    1. The sales region, which does not exist anywhere in TPC-DS. It comes from
       the store_sales_regions seed, joined on state code. Stores in a state the
       seed does not cover fall back to Unassigned rather than null, so regional
       totals never silently drop a store.
    2. The same slowly changing dimension handling as dim_item. Every store
       version is kept and flagged, because the facts join on store_key.
#}

with stores as (

    select * from {{ ref('stg_tpcds__store') }}

),

regions as (

    select * from {{ ref('store_sales_regions') }}

),

final as (

    select
        -- keys
        stores.store_key,
        stores.store_id,

        -- descriptive
        stores.store_name,
        stores.store_manager_name,
        stores.employee_count,
        stores.floor_space_square_feet,
        stores.operating_hours,

        -- organisational hierarchy
        stores.market_id,
        stores.market_description,
        stores.market_manager_name,
        stores.division_name,
        stores.company_name,

        -- location
        stores.city_name,
        stores.county_name,
        stores.state_code,
        stores.postal_code,
        stores.country_name,
        coalesce(regions.sales_region, 'Unassigned')    as sales_region,
        coalesce(regions.region_manager_name, 'Unassigned') as region_manager_name,

        -- one label for map and table labelling
        stores.city_name || ', ' || stores.state_code   as store_location,

        stores.sales_tax_percentage,

        -- slowly changing dimension handling
        stores.record_start_date,
        stores.record_end_date,
        stores.record_end_date is null                  as is_current_record,
        stores.closed_date_key is not null              as is_closed

    from stores
    left join regions
        on stores.state_code = regions.state_code

)

select * from final
