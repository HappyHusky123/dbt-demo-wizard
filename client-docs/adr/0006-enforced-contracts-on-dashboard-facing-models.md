# ADR-0006: Enforce a Contract on the Primary Dashboard Feed

## Status

Accepted

## Date

2026-09-22

## Context

`rpt_daily_store_sales` is the main feed for the
[retail performance dashboard](../../models/marts/_exposures.yml), which store operations looks at
every morning. Dropping a column, renaming one, or changing a type silently breaks a tile in that
dashboard, and the failure surfaces to a business user rather than to the person who caused it.

dbt offers `contract: enforced`, which declares every column and its type in YAML and fails the build
if the model does not deliver exactly that. The costs are real: every column has to be declared, and
every column in the SQL has to be cast explicitly, because a contract compares declared types against
delivered types and an aggregate's natural type is rarely what you would write by hand.
`count(distinct ...)` returns `number(18,0)` in Snowflake; declare it as `number(38,0)` and the build
fails for a reason that has nothing to do with correctness.

Applying that to all three `rpt_` models was considered and rejected. `rpt_category_performance` and
`rpt_customer_segment_sales` are exploratory: their column lists are still moving, and a contract on a
model that is supposed to change turns every iteration into a two-file edit.

## Decision

`contract: enforced` is applied to **`rpt_daily_store_sales` only** — the model with the most
downstream dependency and the most stable shape.

Consequences of the contract, all visible in the model:

- Every column in `rpt_daily_store_sales.sql` carries an explicit `cast(... as <type>)`.
- Every column has a `data_type` in `models/marts/_marts__models.yml`.
- Grain columns carry `constraints: [{type: not_null}]` in addition to a `not_null` data test. The
  constraint is enforced by the warehouse at build time; the test is checked after. Both are wanted.

The other two `rpt_` models carry `access: public` and a `dbt_utils.unique_combination_of_columns`
test on their grain, but no contract. The bar for adding one is that the model's column list has
stopped moving and something depends on it.

## Consequences

### Positive

- Breaking the dashboard's feed requires editing the YAML too. That edit is the review conversation,
  and it happens before the change ships rather than after a tile goes blank.
- The failure is loud, immediate, and points at the exact column.
- It gives the demo something honest to show: an agent proposing a column drop hits a guardrail that
  the agent did not author and cannot talk its way past.

### Negative

- Verbose. Twenty-two columns, each cast and each declared, and the two lists have to agree.
- The type-mismatch failure mode is unintuitive the first time. A `number(18,0)` vs `number(38,0)`
  mismatch reads like a bug in dbt until you have seen it once.
- Inconsistency across the three `rpt_` models is a standing question in review. It is deliberate, and
  this ADR is the answer.
- A contract constrains shape, not meaning. `gross_margin_amount` could start being computed from the
  wrong column and the contract would pass. Tests cover that, not this.

## See also

- [How to add a mart model](../how-to/add-a-mart-model.md)
- [Metric definitions](../reference/metric-definitions.md)
