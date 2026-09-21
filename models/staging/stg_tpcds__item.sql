{#
    Product catalogue, renamed and typed.

    This table carries a slowly changing type 2 history. i_item_sk identifies a
    specific version of a product and is what store_sales joins on. i_item_id
    identifies the product across all of its versions.

    Every version is kept. Filtering to current records here would silently drop
    fact rows whose surrogate key points at a superseded version.
#}

with source as (

    select * from {{ source('tpcds', 'item') }}

),

renamed as (

    select
        -- keys
        i_item_sk                           as item_key,
        i_item_id                           as item_id,

        -- descriptive
        i_product_name                      as product_name,
        i_item_desc                         as item_description,
        i_brand_id                          as brand_id,
        i_brand                             as brand_name,
        i_class_id                          as class_id,
        i_class                             as class_name,
        i_category_id                       as category_id,
        i_category                          as category_name,
        i_manufact_id                       as manufacturer_id,
        i_manufact                          as manufacturer_name,
        i_size                              as item_size,
        i_color                             as item_color,
        i_units                             as unit_of_measure,
        i_container                         as container_type,
        i_formulation                       as formulation,
        i_manager_id                        as manager_id,

        -- pricing
        cast(i_current_price as number(7, 2)) as current_price,
        cast(i_wholesale_cost as number(7, 2)) as wholesale_cost,

        -- slowly changing dimension bounds
        cast(i_rec_start_date as date)      as record_start_date,
        cast(i_rec_end_date as date)        as record_end_date

    from source

)

select * from renamed
