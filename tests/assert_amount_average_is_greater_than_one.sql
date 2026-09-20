{{ config(enabled = false) }}
select
    customer_id, 
    avg(order_total) as average_amount
from {{ ref('stg_jaffle_shop__orders') }}
group by 1
having count(customer_id) > 1 and average_amount < 1