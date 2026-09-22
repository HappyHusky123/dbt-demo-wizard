# ADR-0005: Aggregate Each Fact to the Target Grain Before Joining

## Status

Accepted

## Date

2026-09-22

## Context

`CURATED` holds two facts at line grain: `fct_store_sales` (one row per item per sales ticket) and
`fct_store_returns` (one row per item per return ticket). Several `DATA_VIZ` models need both —
`rpt_daily_store_sales` reports sales and returns per store per day, `rpt_category_performance` reports
both per category per month.

The natural-reading SQL joins the two facts and then aggregates:

```sql
-- WRONG
select store_key, sold_date_key, sum(net_paid_amount), sum(return_amount)
from fct_store_sales
left join fct_store_returns using (ticket_number, item_key)
group by 1, 2
```

This is a fan-out. The two facts share a ticket-and-item key but neither is unique on it at the join's
grain, so every sales row matches every matching return row and the sales measures are multiplied by
the return count before the `sum` ever runs. The result is not slightly wrong, it is wrong by a factor
that varies per row, and it looks completely plausible: totals are too high, no test fires, no error
appears.

This is the single most expensive mistake available in this codebase, and it is the one a
pattern-matching agent makes most readily, because "join then group by" is the shape of almost every
SQL tutorial ever written.

## Decision

When a model reads from more than one fact, **each fact is aggregated to the target grain in its own
CTE first, and only the aggregates are joined.**

```sql
-- RIGHT
with sales as (
    select sold_date_key, store_key, sum(net_paid_amount) as net_sales_amount
    from {{ ref('fct_store_sales') }}
    group by 1, 2
),
returns as (
    select returned_date_key, store_key, sum(return_amount) as return_amount
    from {{ ref('fct_store_returns') }}
    group by 1, 2
)
select ...
from sales
left join returns
    on sales.sold_date_key = returns.returned_date_key
    and sales.store_key = returns.store_key
```

Two rules follow from it:

- **The join is a left join from the primary fact.** A store with sales and no returns must survive.
  Combine with `coalesce(..., 0)` so the row reports zero rather than null.
- **Dimensions are joined after aggregation too,** for the same reason plus a cheaper one: joining a
  dimension to an aggregate touches thousands of rows instead of hundreds of millions.

`rpt_daily_store_sales`, `rpt_category_performance` and `rpt_customer_segment_sales` all follow this
shape. Read any of them as the worked example.

## Consequences

### Positive

- Measures are correct, and correct for a structural reason rather than because someone checked.
- Faster. Aggregation happens before the join, so the join operates on the small side.
- The CTE names document the grain. `sales` and `returns` each state what one row means.

### Negative

- More verbose than the one-statement version, and the verbosity is the point, which makes it hard to
  argue against a "simplification" in review without this document to point at.
- Attribution asymmetry becomes visible and has to be handled deliberately: returns are dated when
  they happened, not when the original sale happened, so a return rate can exceed 100% in a period
  where an earlier period's sales came back. That is a property of the data, documented on the
  `return_rate_pct` columns, and it only shows up because the aggregation is honest.
- `dbt_utils.unique_combination_of_columns` on the output grain is the test that would catch a
  regression here, so every model following this pattern carries one. That is a test to maintain.

## See also

- [Grain and fan-out](../explanation/grain-and-fan-out.md)
- [How to add a mart model](../how-to/add-a-mart-model.md)
