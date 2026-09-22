# ADR-0004: Every Rate and Percentage Goes Through `safe_divide`

## Status

Accepted

## Date

2026-09-22

## Context

The `DATA_VIZ` layer is mostly ratios: gross margin percentage, return rate, average transaction
amount, sales per customer, average unit price. Every one of them divides by a count or an amount that
can legitimately be zero.

Zero denominators here are not data quality problems. A store that traded on a day but had no returns
has a zero return count. A category with no net sales in a month has zero net sales. These rows are
correct and should appear in the report.

Snowflake raises `Division by zero` rather than returning null, so a single such row fails the entire
model build. The three obvious responses:

1. **`nullif(denominator, 0)`** — idiomatic SQL, returns null on the zero case. Compact, but it always
   yields null, and a dashboard showing a null return rate for a store that simply had no returns is
   worse than showing zero.
2. **A hand-written `case` per calculation.** Correct, and there are seventeen of them. The seventeenth
   will be the one that gets it wrong.
3. **One macro.** The behavior is written once and the default is a choice at the call site.

## Decision

All division in this project goes through `{{ safe_divide(numerator, denominator, default_value) }}`
from `macros/safe_divide.sql`. Raw `/` between two columns does not appear in a model.

The macro returns `default_value` when the denominator is zero **or null**, defaulting to `null` when
the caller does not say. Every current call site passes `0` explicitly, because in each case a zero
denominator means "this did not happen", and zero is the honest answer.

Choosing the default is the caller's job and the caller should think about it. Pass `0` when a missing
denominator means the quantity is genuinely zero; leave it as `null` when the ratio is genuinely
undefined and the report should show a gap rather than a floor.

## Consequences

### Positive

- No model in this project can fail on a division by zero.
- The default is visible at the call site, so a reader can see that a zero return rate is a deliberate
  choice and not an accident.
- A new rate is one macro call. There is no per-calculation `case` block to get subtly wrong.

### Negative

- Compiled SQL is more verbose — each call expands to a `case` expression. Reading a compiled model in
  Snowflake's query history takes slightly more scrolling.
- The macro evaluates the denominator twice in the compiled output, once in the guard and once in the
  division. Harmless for column references; worth noticing if anyone ever passes an expensive scalar
  subquery.
- It is a project-local convention. An agent will reach for `nullif` unless told otherwise, which is
  what this ADR is for.

## See also

- [Macro reference](../reference/macros.md)
- [How to add a mart model](../how-to/add-a-mart-model.md)
