{#
    Product dimension.

    The source carries a slowly changing type 2 history and every version is
    kept, because store_sales joins on item_key, which identifies a version
    rather than a product. Filtering to current records here would silently drop
    fact rows pointing at superseded versions.

    is_current_record is exposed instead, so anyone who genuinely wants today's
    catalogue can filter on it without losing history.
#}

with items as (

    select * from {{ ref('stg_tpcds__item') }}

),

final as (

    select
        -- keys
        item_key,
        item_id,

        -- descriptive
        product_name,
        item_description,
        brand_name,
        class_name,
        category_name,
        manufacturer_name,
        item_size,
        item_color,
        unit_of_measure,
        container_type,

        -- the full hierarchy as one sortable label
        coalesce(category_name, 'Unknown')
            || ' > ' || coalesce(class_name, 'Unknown')
            || ' > ' || coalesce(brand_name, 'Unknown')    as product_hierarchy,

        -- pricing
        current_price,
        wholesale_cost,
        current_price - wholesale_cost                      as list_margin_amount,

        -- slowly changing dimension handling
        record_start_date,
        record_end_date,
        record_end_date is null                             as is_current_record

    from items

)

select * from final
