{#
    Daily sales and returns by store. One row per store per trading day.

    This model has an enforced contract, which is why every column is cast
    explicitly rather than left to whatever type an aggregate happens to return.
    A contract compares the declared type against the delivered type, and
    count(distinct ...) returning number(18,0) against a declared number(38,0)
    is exactly the kind of mismatch that fails a build for no good reason.

    Sales and returns are aggregated separately and then joined. Aggregating
    after a join between two facts at different grains would multiply the sales
    rows by the return rows and overstate everything.
#}

with sales as (

    select
        sold_date_key,
        store_key,
        count(distinct ticket_number)   as transaction_count,
        count(*)                        as line_item_count,
        sum(quantity_sold)              as units_sold,
        sum(extended_sales_amount)      as gross_sales_amount,
        sum(total_discount_amount)      as discount_amount,
        sum(net_paid_amount)            as net_sales_amount,
        sum(gross_margin_amount)        as gross_margin_amount
    from {{ ref('fct_store_sales') }}
    group by 1, 2

),

returns as (

    select
        returned_date_key,
        store_key,
        sum(quantity_returned)          as units_returned,
        sum(return_amount)              as return_amount
    from {{ ref('fct_store_returns') }}
    group by 1, 2

),

stores as (

    select * from {{ ref('dim_store') }}

),

dates as (

    select * from {{ ref('dim_date') }}

),

final as (

    select
        -- grain
        cast(dates.calendar_date as date)                       as sales_date,
        cast(sales.store_key as number(38, 0))                  as store_key,

        -- store attributes
        cast(stores.store_id as varchar)                        as store_id,
        cast(stores.store_name as varchar)                      as store_name,
        cast(stores.sales_region as varchar)                    as sales_region,
        cast(stores.state_code as varchar)                      as state_code,

        -- date attributes
        cast(dates.calendar_year as number(38, 0))              as calendar_year,
        cast(dates.year_month as varchar)                       as year_month,
        cast(dates.is_weekend as boolean)                       as is_weekend,

        -- volume
        cast(sales.transaction_count as number(38, 0))          as transaction_count,
        cast(sales.line_item_count as number(38, 0))            as line_item_count,
        cast(sales.units_sold as number(38, 0))                 as units_sold,

        -- value
        cast(sales.gross_sales_amount as number(18, 2))         as gross_sales_amount,
        cast(sales.discount_amount as number(18, 2))            as discount_amount,
        cast(sales.net_sales_amount as number(18, 2))           as net_sales_amount,
        cast(sales.gross_margin_amount as number(18, 2))        as gross_margin_amount,
        cast(
            {{ safe_divide('sales.gross_margin_amount', 'sales.net_sales_amount', 0) }}
            as number(9, 4)
        )                                                       as gross_margin_pct,

        -- returns, zero filled so a store with no returns still reports a rate
        cast(coalesce(returns.units_returned, 0) as number(38, 0))  as units_returned,
        cast(coalesce(returns.return_amount, 0) as number(18, 2))   as return_amount,
        cast(
            {{ safe_divide(
                'coalesce(returns.return_amount, 0)',
                'sales.gross_sales_amount',
                0
            ) }}
            as number(9, 4)
        )                                                       as return_rate_pct,

        -- average basket
        cast(
            {{ safe_divide('sales.net_sales_amount', 'sales.transaction_count', 0) }}
            as number(18, 2)
        )                                                       as average_transaction_amount

    from sales
    inner join dates
        on sales.sold_date_key = dates.date_key
    inner join stores
        on sales.store_key = stores.store_key
    left join returns
        on sales.sold_date_key = returns.returned_date_key
        and sales.store_key = returns.store_key

)

select * from final
