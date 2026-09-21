-- A return line should never take back more units than the matching sale line
-- sold. Anything that does means the two facts have drifted out of grain with
-- each other, which is the failure mode that would quietly corrupt every return
-- rate in the DATA_VIZ layer.
--
-- The join is deliberately inner. Both facts are filtered to the same date key
-- window, but a return is dated when it happened rather than when the original
-- sale did, so returns whose sale falls outside the window legitimately have no
-- match. Those are not a defect and are not what this test is looking for.

with sales as (

    select
        ticket_number,
        item_key,
        quantity_sold
    from {{ ref('fct_store_sales') }}

),

returns as (

    select
        ticket_number,
        item_key,
        quantity_returned
    from {{ ref('fct_store_returns') }}

)

select
    returns.ticket_number,
    returns.item_key,
    returns.quantity_returned,
    sales.quantity_sold

from returns
inner join sales
    on returns.ticket_number = sales.ticket_number
    and returns.item_key = sales.item_key

where returns.quantity_returned > sales.quantity_sold
