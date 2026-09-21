{#
    Store returns fact at return line grain: one row per item per return ticket.

    Grain matches fct_store_sales, so the two join cleanly on ticket_number and
    item_key. They are kept as separate facts rather than merged into one,
    because a sale and its return are separate events on separate dates, and
    flattening them would make any date based total wrong.

    The date here is the returned date, not the sold date. A return in the
    window can belong to a sale outside it.
#}

with returns as (

    select * from {{ ref('stg_tpcds__store_returns') }}

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

final as (

    select
        -- degenerate and foreign keys
        returns.ticket_number,
        returns.item_key,
        returns.returned_date_key,
        returns.customer_key,
        returns.store_key,
        returns.return_reason_key,
        returns.customer_address_key,
        returns.customer_demographics_key,

        -- date attributes, denormalised for convenience
        dates.calendar_date                                 as returned_date,
        dates.calendar_year                                 as returned_year,
        dates.month_of_year                                 as returned_month_of_year,
        dates.year_month                                    as returned_year_month,

        -- measures
        returns.quantity_returned,
        returns.return_amount,
        returns.return_tax_amount,
        returns.return_amount_inc_tax,
        returns.return_fee_amount,
        returns.return_shipping_cost_amount,
        returns.refunded_cash_amount,
        returns.reversed_charge_amount,
        returns.store_credit_amount,
        returns.net_loss_amount,

        -- what the customer actually got back, in whatever form
        returns.refunded_cash_amount
            + returns.reversed_charge_amount
            + returns.store_credit_amount                   as total_refunded_amount

    from returns
    left join dates
        on returns.returned_date_key = dates.date_key

)

select * from final
