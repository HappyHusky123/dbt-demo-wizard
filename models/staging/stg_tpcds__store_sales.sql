{#
    Store sales transaction lines, renamed and typed. No business logic.

    The date key filter is the single most important line in this project.
    STORE_SALES is roughly 28.8 billion rows at the 10 TB scale factor and is
    partitioned on ss_sold_date_sk, so this predicate is what keeps the demo
    inside the 5 minute command timeout that dbt Wizard enforces.

    Rows with a null ss_sold_date_sk exist in the benchmark and are excluded by
    the between, which is the behaviour we want.
#}

with source as (

    select * from {{ source('tpcds', 'store_sales') }}
    where ss_sold_date_sk between {{ var('tpcds_start_date_sk') }}
                              and {{ var('tpcds_end_date_sk') }}

),

renamed as (

    select
        -- keys
        ss_ticket_number                            as ticket_number,
        ss_item_sk                                  as item_key,
        ss_sold_date_sk                             as sold_date_key,
        ss_sold_time_sk                             as sold_time_key,
        ss_customer_sk                              as customer_key,
        ss_cdemo_sk                                 as customer_demographics_key,
        ss_hdemo_sk                                 as household_demographics_key,
        ss_addr_sk                                  as customer_address_key,
        ss_store_sk                                 as store_key,
        ss_promo_sk                                 as promotion_key,

        -- measures
        ss_quantity                                 as quantity_sold,
        cast(ss_wholesale_cost     as number(7, 2)) as unit_wholesale_cost,
        cast(ss_list_price         as number(7, 2)) as unit_list_price,
        cast(ss_sales_price        as number(7, 2)) as unit_sales_price,
        cast(ss_ext_list_price     as number(7, 2)) as extended_list_amount,
        cast(ss_ext_sales_price    as number(7, 2)) as extended_sales_amount,
        cast(ss_ext_wholesale_cost as number(7, 2)) as extended_wholesale_cost_amount,
        cast(ss_ext_discount_amt   as number(7, 2)) as extended_discount_amount,
        cast(ss_ext_tax            as number(7, 2)) as extended_tax_amount,
        cast(ss_coupon_amt         as number(7, 2)) as coupon_amount,
        cast(ss_net_paid           as number(7, 2)) as net_paid_amount,
        cast(ss_net_paid_inc_tax   as number(7, 2)) as net_paid_inc_tax_amount,
        cast(ss_net_profit         as number(7, 2)) as net_profit_amount

    from source

)

select * from renamed
