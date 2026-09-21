{#
    Store return lines, renamed and typed. No business logic.

    Filtered on the same date key window as store sales. Note that a return is
    dated when it was returned, not when the original sale happened, so a narrow
    window will contain returns whose matching sale falls outside it. That is
    expected and is what assert_no_returns_without_sales tolerates.
#}

with source as (

    select * from {{ source('tpcds', 'store_returns') }}
    where sr_returned_date_sk between {{ var('tpcds_start_date_sk') }}
                                  and {{ var('tpcds_end_date_sk') }}

),

renamed as (

    select
        -- keys
        sr_ticket_number                           as ticket_number,
        sr_item_sk                                 as item_key,
        sr_returned_date_sk                        as returned_date_key,
        sr_return_time_sk                          as returned_time_key,
        sr_customer_sk                             as customer_key,
        sr_cdemo_sk                                as customer_demographics_key,
        sr_hdemo_sk                                as household_demographics_key,
        sr_addr_sk                                 as customer_address_key,
        sr_store_sk                                as store_key,
        sr_reason_sk                               as return_reason_key,

        -- measures
        sr_return_quantity                         as quantity_returned,
        cast(sr_return_amt        as number(7, 2)) as return_amount,
        cast(sr_return_tax        as number(7, 2)) as return_tax_amount,
        cast(sr_return_amt_inc_tax as number(7, 2)) as return_amount_inc_tax,
        cast(sr_fee               as number(7, 2)) as return_fee_amount,
        cast(sr_return_ship_cost  as number(7, 2)) as return_shipping_cost_amount,
        cast(sr_refunded_cash     as number(7, 2)) as refunded_cash_amount,
        cast(sr_reversed_charge   as number(7, 2)) as reversed_charge_amount,
        cast(sr_store_credit      as number(7, 2)) as store_credit_amount,
        cast(sr_net_loss          as number(7, 2)) as net_loss_amount

    from source

)

select * from renamed
