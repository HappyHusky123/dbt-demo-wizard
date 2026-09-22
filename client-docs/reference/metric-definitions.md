# Metric definitions

What every measure means and where it is defined. **Reuse a definition before inventing one** — a
measure computed two ways in two models is the same failure as a fact documented twice.

Definitions live in `CURATED`. `DATA_VIZ` aggregates them and derives rates from them; it introduces
no new definitions of its own.

## Base measures — `fct_store_sales`

One row per item per sales ticket.

| Measure | Definition |
|---|---|
| `quantity_sold` | Units on the line, as sold |
| `extended_sales_amount` | Extended sales price, before discounts and tax |
| `extended_wholesale_cost_amount` | Extended wholesale cost of the line |
| `extended_discount_amount` | Extended discount on the line |
| `coupon_amount` | Coupon value applied to the line |
| `net_paid_amount` | What the customer paid, **excluding tax** |
| `net_paid_inc_tax_amount` | What the customer paid, including tax |
| `gross_margin_amount` | `net_paid_amount - extended_wholesale_cost_amount`. **Our** margin definition |
| `benchmark_net_profit_amount` | TPC-DS's own profit figure, retained for comparison |
| `total_discount_amount` | `extended_discount_amount + coupon_amount` |

Two things to know about `gross_margin_amount`:

- **It is negative on essentially every line.** TPC-DS generates wholesale costs above what customers
  pay. The daily average ran between **-829.92 and -827.44** (observed 2026-09-22, default seven-day
  window). The formula is correct; the benchmark is not a profitable retailer.
- **It is deliberately distinct from `benchmark_net_profit_amount`.** Both are carried so the two can
  be compared rather than silently disagreeing. Do not substitute one for the other.

The `expect_average_greater_than` test on this column uses `min_value: -1000` as a guardrail against
the *formula* changing, not as an assertion about profitability. Widening the date window may require
re-measuring it.

## Base measures — `fct_store_returns`

One row per item per return ticket.

| Measure | Definition |
|---|---|
| `quantity_returned` | Units returned on the line |
| `return_amount` | Value of the returned goods, excluding tax |
| `total_refunded_amount` | Cash, reversed charges and store credit combined |
| `net_loss_amount` | Loss on the return, as calculated by the benchmark |

**Returns are dated when the return happened, not when the original sale happened.** Every rate that
puts returns over sales inherits this, which is why a return rate can exceed 1.0 in a period where an
earlier period's sales came back. That is a property of the data.

## Derived measures in `DATA_VIZ`

All aggregates of the above. All rates go through `safe_divide` with a default of `0`
([ADR-0004](../adr/0004-safe-divide-for-all-rate-calculations.md)).

| Measure | Definition | Appears in |
|---|---|---|
| `transaction_count` | `count(distinct ticket_number)` | all three `rpt_` models |
| `line_item_count` | `count(*)` over sales lines | `rpt_daily_store_sales` |
| `units_sold` | `sum(quantity_sold)` | all three |
| `gross_sales_amount` | `sum(extended_sales_amount)` | `rpt_daily_store_sales`, `rpt_category_performance` |
| `discount_amount` | `sum(total_discount_amount)` | all three |
| `net_sales_amount` | `sum(net_paid_amount)` | all three |
| `gross_margin_amount` | `sum(gross_margin_amount)` | all three |
| `gross_margin_pct` | `gross_margin_amount / net_sales_amount` | all three |
| `units_returned` | `sum(quantity_returned)` | `rpt_daily_store_sales`, `rpt_category_performance` |
| `return_amount` | `sum(return_amount)`, zero-filled | `rpt_daily_store_sales`, `rpt_category_performance` |
| `return_rate_pct` | `return_amount / gross_sales_amount` | `rpt_daily_store_sales`, `rpt_category_performance` |
| `average_transaction_amount` | `net_sales_amount / transaction_count` | `rpt_daily_store_sales`, `rpt_customer_segment_sales` |
| `average_unit_price` | `net_sales_amount / units_sold` | `rpt_category_performance` |
| `active_customer_count` | `count(distinct customer_key)` | `rpt_customer_segment_sales` |
| `sales_per_customer` | `net_sales_amount / active_customer_count` | `rpt_customer_segment_sales` |
| `distinct_products_sold` | `count(distinct item_key)` | `rpt_category_performance` |
| `promotional_sales_amount` | `sum(net_paid_amount)` where the line is promotional | `rpt_category_performance` |
| `promotional_sales_pct` | `promotional_sales_amount / net_sales_amount` | `rpt_category_performance` |

Note that `gross_margin_pct` uses **net** sales as its denominator while `return_rate_pct` uses
**gross** sales. Deliberate: margin is measured against what was actually collected, returns against
what was originally rung up.

## Derived attributes — `dim_customer`

| Attribute | Definition |
|---|---|
| `customer_segment` | Spend band on `annual_purchase_estimate`: `>= 7500` High Value, `>= 4000` Mid Value, `>= 1500` Low Value, else Minimal. Null estimate gives Unknown |
| `generation_band` | Birth-year band: `>= 1977` Gen X or later, `>= 1946` Baby Boomer, `>= 1928` Silent Generation, else Greatest Generation. Null year gives Unknown |
| `gender` | Decoded from `gender_code`: `M` Male, `F` Female, anything else Unknown |
| `marital_status` | Decoded from `marital_status_code`: `M` Married, `S` Single, `D` Divorced, `W` Widowed, else Unknown |
| `birth_date` | Assembled from three integer columns with `try_to_date`, so invalid combinations become null |
| `full_name` | `first_name` and `last_name` trimmed and concatenated |

Bands are computed from birth **year**, not against `current_date`, deliberately. A model whose output
changes overnight is a model whose tests fail for no reason, and TPC-DS is fixed in the early 2000s.

`customer_segment` reflects the customer's **current** demographics, not their demographics at the
time of sale. `fct_store_sales` carries a `customer_demographics_key` that would give the as-at
version, but using it would mean duplicating the banding logic. One definition in one place is worth
more than point-in-time accuracy on a benchmark dataset.

## Derived attributes — `dim_store`

| Attribute | Definition |
|---|---|
| `sales_region` | From `seeds/store_sales_regions.csv`, joined on `state_code`. Unlisted states fall back to `Unassigned` |
