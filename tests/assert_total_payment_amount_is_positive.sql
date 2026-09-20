select
    order_total
from {{ ref('stg_jaffle_shop__orders') }}
where
    order_total < 0