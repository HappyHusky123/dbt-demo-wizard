{#
    Product category performance by month. One row per category per month.

    Sales and returns are aggregated to the category grain separately before
    being joined, for the same reason as rpt_daily_store_sales: joining two
    facts at line grain first would multiply the rows.

    Returns are attributed to the month the return happened, not the month of
    the original sale, so a category's return rate can exceed 100 percent in a
    month where an earlier month's sales came back. That is a property of the
    data, not a bug, and the return window is what the tpcds date variables
    control.
#}

with sales as (

    select
        sales.sold_year_month           as year_month,
        items.category_name,
        count(distinct sales.ticket_number) as transaction_count,
        count(distinct sales.item_key)  as distinct_products_sold,
        sum(sales.quantity_sold)        as units_sold,
        sum(sales.extended_sales_amount) as gross_sales_amount,
        sum(sales.total_discount_amount) as discount_amount,
        sum(sales.net_paid_amount)      as net_sales_amount,
        sum(sales.gross_margin_amount)  as gross_margin_amount,
        sum(
            case when sales.is_promotional_sale then sales.net_paid_amount else 0 end
        )                               as promotional_sales_amount
    from {{ ref('fct_store_sales') }} as sales
    inner join {{ ref('dim_item') }} as items
        on sales.item_key = items.item_key
    group by 1, 2

),

returns as (

    select
        returns.returned_year_month     as year_month,
        items.category_name,
        sum(returns.quantity_returned)  as units_returned,
        sum(returns.return_amount)      as return_amount
    from {{ ref('fct_store_returns') }} as returns
    inner join {{ ref('dim_item') }} as items
        on returns.item_key = items.item_key
    group by 1, 2

),

final as (

    select
        -- grain
        sales.year_month,
        coalesce(sales.category_name, 'Unknown')            as category_name,

        -- volume
        sales.transaction_count,
        sales.distinct_products_sold,
        sales.units_sold,

        -- value
        sales.gross_sales_amount,
        sales.discount_amount,
        sales.net_sales_amount,
        sales.gross_margin_amount,
        {{ safe_divide('sales.gross_margin_amount', 'sales.net_sales_amount', 0) }}
                                                            as gross_margin_pct,

        -- promotion effectiveness
        sales.promotional_sales_amount,
        {{ safe_divide('sales.promotional_sales_amount', 'sales.net_sales_amount', 0) }}
                                                            as promotional_sales_pct,

        -- returns
        coalesce(returns.units_returned, 0)                 as units_returned,
        coalesce(returns.return_amount, 0)                  as return_amount,
        {{ safe_divide(
            'coalesce(returns.return_amount, 0)',
            'sales.gross_sales_amount',
            0
        ) }}                                                as return_rate_pct,

        -- per unit economics
        {{ safe_divide('sales.net_sales_amount', 'sales.units_sold', 0) }}
                                                            as average_unit_price

    from sales
    left join returns
        on sales.year_month = returns.year_month
        and sales.category_name = returns.category_name

)

select * from final
