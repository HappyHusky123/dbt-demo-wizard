with analysis as (

    select 
        customers.customer_name,
        sum(orders.order_total) as total_spend
    from
        {{ ref('fct_orders', v=1)}} as orders
    inner join 
        {{ ref('dim_customer') }} as customers
    on
        customers.customer_id = orders.customer_id
    group by
        customers.customer_name

), analysis_final as (

    select 
        customer_name,
        {{ cents_to_dollars( 'total_spend' ) }} as total_spend_conversion
    from 
        analysis
)

select * from analysis_final