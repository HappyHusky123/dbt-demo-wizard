{#
    Store sales fact at transaction line grain: one row per item per ticket.

    This is the model the rest of the project hangs off, and the one to point an
    impact question at during the demo. Everything in models/marts reads from
    here.

    Business logic applied here:

    - Gross margin, calculated from what the customer actually paid against
      wholesale cost. The benchmark ships its own net_profit_amount; it is kept
      alongside so the two can be compared rather than silently disagreeing.
    - The sold date is denormalised from dim_date. Every consumer wants it and
      none of them should have to join 73,000 rows to get it.
    - The eight Y/N promotion channel flags are collapsed into one readable
      list. Nothing downstream should have to know there were eight columns.

    Materialised as a plain table. An incremental delete+insert on
    sold_date_key is the right production pattern for a fact this size, but a
    full refresh is one less thing to explain on stage.
#}

with sales as (

    select * from {{ ref('stg_tpcds__store_sales') }}

),

dates as (

    select
        date_key,
        calendar_date,
        calendar_year,
        month_of_year,
        year_month
    from {{ ref('dim_date') }}

),

promotions as (

    select
        promotion_key,
        promotion_name,
        promotion_purpose,
        promotion_cost,
        nullif(
            array_to_string(
                array_construct_compact(
                    case when channel_direct_mail_flag = 'Y' then 'Direct Mail' end,
                    case when channel_email_flag       = 'Y' then 'Email'       end,
                    case when channel_catalog_flag     = 'Y' then 'Catalog'     end,
                    case when channel_tv_flag          = 'Y' then 'TV'          end,
                    case when channel_radio_flag       = 'Y' then 'Radio'       end,
                    case when channel_press_flag       = 'Y' then 'Press'       end,
                    case when channel_event_flag       = 'Y' then 'Event'       end,
                    case when channel_demo_flag        = 'Y' then 'Demo'        end
                ),
                ', '
            ),
            ''
        ) as promotion_channels
    from {{ ref('stg_tpcds__promotion') }}

),

final as (

    select
        -- degenerate and foreign keys
        sales.ticket_number,
        sales.item_key,
        sales.sold_date_key,
        sales.customer_key,
        sales.store_key,
        sales.promotion_key,
        sales.customer_address_key,
        sales.customer_demographics_key,

        -- date attributes, denormalised for convenience
        dates.calendar_date                                     as sold_date,
        dates.calendar_year                                     as sold_year,
        dates.month_of_year                                     as sold_month_of_year,
        dates.year_month                                        as sold_year_month,

        -- promotion attributes
        promotions.promotion_name,
        promotions.promotion_purpose,
        promotions.promotion_channels,
        sales.promotion_key is not null                         as is_promotional_sale,

        -- measures as sold
        sales.quantity_sold,
        sales.unit_list_price,
        sales.unit_sales_price,
        sales.extended_list_amount,
        sales.extended_sales_amount,
        sales.extended_wholesale_cost_amount,
        sales.extended_discount_amount,
        sales.extended_tax_amount,
        sales.coupon_amount,
        sales.net_paid_amount,
        sales.net_paid_inc_tax_amount,

        -- our margin, from what was actually paid against wholesale cost
        sales.net_paid_amount - sales.extended_wholesale_cost_amount
                                                                as gross_margin_amount,

        -- the benchmark's own profit figure, kept for comparison
        sales.net_profit_amount                                 as benchmark_net_profit_amount,

        -- discount depth, useful for the promotion analysis in DATA_VIZ
        sales.extended_discount_amount + sales.coupon_amount    as total_discount_amount

    from sales
    left join dates
        on sales.sold_date_key = dates.date_key
    left join promotions
        on sales.promotion_key = promotions.promotion_key

)

select * from final
