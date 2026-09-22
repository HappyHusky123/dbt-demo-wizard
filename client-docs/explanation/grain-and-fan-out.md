# Grain and fan-out

Why this project never joins two facts at line grain, and why the resulting SQL is more verbose than
it looks like it needs to be.

The rule itself is [ADR-0005](../adr/0005-aggregate-before-joining-facts.md). This document is the
reasoning behind it.

## Grain, stated once per model

Every model in this project declares what one row means, in `meta.grain` in its YAML:

| Model | One row is |
|---|---|
| `fct_store_sales` | one item on one sales ticket |
| `fct_store_returns` | one item on one return ticket |
| `dim_customer` | one customer |
| `rpt_daily_store_sales` | one store on one trading day |
| `rpt_category_performance` | one product category in one month |

If you cannot write that sentence for a model you are adding, the model does not have a grain yet and
the SQL will not be right regardless of how it reads.

## The failure

`fct_store_sales` and `fct_store_returns` share a key pair: `ticket_number` and `item_key`. It is
tempting to treat that as a join key and aggregate afterwards.

It is not a join key. Neither fact is unique on that pair *for the purpose the join is being used
for* — a ticket-and-item combination can appear multiple times across the two facts, and the join
produces a row per matched pair. Aggregating after the join therefore sums each sales row once per
matching return row.

The result is wrong by a multiplier that varies per row. Which means:

- Totals are too high, but plausibly so. Nothing looks obviously broken.
- No error is raised. The SQL is valid.
- No `not_null` or `unique` test fires, because the output rows are all distinct at the output grain.
- The only test that catches it is a uniqueness test on the *output* grain, which is why every model
  following this pattern carries a `dbt_utils.unique_combination_of_columns`.

This is the most expensive available mistake in the codebase precisely because it is silent. A model
that fails to build costs you twenty minutes. A model that quietly overstates revenue costs you the
next quarter's credibility.

## Why an agent reaches for it

"Join the tables, then group by" is the shape of nearly every SQL tutorial. It is the correct shape
when one side is a dimension — joining `dim_store` to a sales fact does not fan out, because
`dim_store` is unique on `store_key`.

The shape is only wrong when **both** sides are facts. The distinction is not syntactic; nothing in
the SQL tells you which is which. It comes from knowing the grain of both inputs, which is why grain
is declared in the YAML rather than left to be inferred.

## The shape that works

Each fact aggregates to the target grain in its own CTE. Only the aggregates are joined. Dimensions
join last, against the small side.

```sql
with sales as (
    -- one row per store per day
    select sold_date_key, store_key, sum(net_paid_amount) as net_sales_amount
    from {{ ref('fct_store_sales') }}
    group by 1, 2
),

returns as (
    -- one row per store per day
    select returned_date_key, store_key, sum(return_amount) as return_amount
    from {{ ref('fct_store_returns') }}
    group by 1, 2
)

select
    sales.sold_date_key,
    sales.store_key,
    sales.net_sales_amount,
    coalesce(returns.return_amount, 0) as return_amount
from sales
left join returns
    on sales.sold_date_key = returns.returned_date_key
    and sales.store_key = returns.store_key
```

Three things are load-bearing here, and each one is a decision rather than a style choice:

1. **Both CTEs are already at the output grain** before the join. The join is now
   one-to-at-most-one, and cannot fan out.
2. **The join is a left join from the primary fact.** A store that traded and had no returns has to
   survive into the output. An inner join would silently delete it.
3. **`coalesce(..., 0)` on the non-primary side.** Without it, the store with no returns reports a
   null return amount, and every rate computed from it is null too.

A side benefit: the join now operates on thousands of rows instead of hundreds of millions.

## What the honest version exposes

Aggregating each fact on its own terms makes an attribution asymmetry visible that the fan-out version
hides: **returns are dated when they happened, not when the original sale happened.**

So a store's return rate can exceed 100% on a day when an earlier week's sales came back. That is a
true statement about the data, not a bug, and it is documented on every `return_rate_pct` column.

It only becomes visible because the aggregation is honest about grain. A pipeline that quietly
multiplied its sales rows would have buried it.
