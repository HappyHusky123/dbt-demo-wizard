{#
    Marketing promotions, renamed and typed. Roughly 2,000 rows.

    The channel columns arrive as one Y/N flag per channel. They are kept in
    that shape here; fct_store_sales is where they get collapsed into a single
    promotion channel description.
#}

with source as (

    select * from {{ source('tpcds', 'promotion') }}

),

renamed as (

    select
        -- keys
        p_promo_sk                      as promotion_key,
        p_promo_id                      as promotion_id,
        p_item_sk                       as item_key,
        p_start_date_sk                 as start_date_key,
        p_end_date_sk                   as end_date_key,

        -- descriptive
        p_promo_name                    as promotion_name,
        p_purpose                       as promotion_purpose,
        p_channel_details               as channel_details,
        cast(p_cost as number(15, 2))   as promotion_cost,
        p_response_target               as response_target,
        p_discount_active               as discount_active_flag,

        -- channel flags, still Y/N here
        p_channel_dmail                 as channel_direct_mail_flag,
        p_channel_email                 as channel_email_flag,
        p_channel_catalog               as channel_catalog_flag,
        p_channel_tv                    as channel_tv_flag,
        p_channel_radio                 as channel_radio_flag,
        p_channel_press                 as channel_press_flag,
        p_channel_event                 as channel_event_flag,
        p_channel_demo                  as channel_demo_flag

    from source

)

select * from renamed
