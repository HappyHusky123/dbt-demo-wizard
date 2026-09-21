{#
    Sales by customer spend segment and month, split by generation and gender.

    This model carries the heaviest join in the project: the sales fact against
    sixty five million customers. Only the four columns actually needed are
    selected from dim_customer so Snowflake prunes the build side rather than
    hashing the whole dimension.

    The segment reflects the customer's current demographics, not their
    demographics at the time of sale. The fact does carry a
    customer_demographics_key that would give the as at version, but it would
    mean duplicating the segment banding logic that already lives in
    dim_customer. One definition in one place is worth more here than point in
    time accuracy on a demo dataset.
#}

with sales as (

    select
        sold_year_month,
        customer_key,
        ticket_number,
        quantity_sold,
        net_paid_amount,
        gross_margin_amount,
        total_discount_amount
    from {{ ref('fct_store_sales') }}

),

customers as (

    select
        customer_key,
        customer_segment,
        generation_band,
        gender
    from {{ ref('dim_customer') }}

),

joined as (

    select
        sales.sold_year_month                           as year_month,
        coalesce(customers.customer_segment, 'Unknown') as customer_segment,
        coalesce(customers.generation_band, 'Unknown')  as generation_band,
        coalesce(customers.gender, 'Unknown')           as gender,
        sales.customer_key,
        sales.ticket_number,
        sales.quantity_sold,
        sales.net_paid_amount,
        sales.gross_margin_amount,
        sales.total_discount_amount
    from sales
    left join customers
        on sales.customer_key = customers.customer_key

),

final as (

    select
        -- grain
        year_month,
        customer_segment,
        generation_band,
        gender,

        -- volume
        count(distinct customer_key)        as active_customer_count,
        count(distinct ticket_number)       as transaction_count,
        sum(quantity_sold)                  as units_sold,

        -- value
        sum(net_paid_amount)                as net_sales_amount,
        sum(gross_margin_amount)            as gross_margin_amount,
        sum(total_discount_amount)          as discount_amount,
        {{ safe_divide('sum(gross_margin_amount)', 'sum(net_paid_amount)', 0) }}
                                            as gross_margin_pct,

        -- per customer and per basket economics
        {{ safe_divide('sum(net_paid_amount)', 'count(distinct customer_key)', 0) }}
                                            as sales_per_customer,
        {{ safe_divide('sum(net_paid_amount)', 'count(distinct ticket_number)', 0) }}
                                            as average_transaction_amount

    from joined
    group by 1, 2, 3, 4

)

select * from final
