# ADR-0007: Every Fact Staging Model Filters on the Date-Key Window Vars

## Status

Accepted

## Date

2026-09-22

## Context

The source is the `SNOWFLAKE_SAMPLE_DATA` share at scale factor `TPCDS_SF10TCL`. `STORE_SALES` is
roughly 28.8 billion rows. `CATALOG_SALES` and `WEB_SALES` are the same order of magnitude.

A staging model that selects the whole table is not slow, it is a warehouse bill. And it is entirely
avoidable: the fact tables are clustered on their date surrogate key, so a predicate on that key
prunes micro-partitions hard. Reading one week instead of five years is a difference of roughly three
orders of magnitude in bytes scanned, for a single `where` clause.

The window has to be a variable rather than a literal, because the right window is different for
different purposes: a few days for a fast iteration loop, a month for something that needs seasonality,
a year when the point is the size of the number.

## Decision

**Every staging model over a TPC-DS fact table filters on the date-key window vars.** No exceptions,
including for a model added in a hurry.

Declared in `dbt_project.yml`:

```yaml
vars:
  tpcds_schema: TPCDS_SF10TCL
  tpcds_start_date_sk: 2452276     # 2002-01-01
  tpcds_end_date_sk:   2452282     # 2002-01-07
```

Applied in the staging model, against that fact's own date-key column:

```sql
where ss_sold_date_sk between {{ var('tpcds_start_date_sk') }}
                         and {{ var('tpcds_end_date_sk') }}
```

The column differs per table and the filter must use the table's own: `ss_sold_date_sk` on
`store_sales`, `sr_returned_date_sk` on `store_returns`, `cs_sold_date_sk` on `catalog_sales`,
`ws_sold_date_sk` on `web_sales`.

`d_date_sk` is the Julian day number, which is why these are readable as plain integers. Useful values:

| Window | `tpcds_end_date_sk` |
|---|---|
| One week (default) | `2452282` |
| January 2002 | `2452306` |
| All of 2002 | `2452640` |

Dimension staging models are **not** filtered. `customer` is 65 million rows and `item`, `store`,
`promotion` and `date_dim` are small; filtering a dimension by a fact's date window would silently
drop conformed members and break the relationship tests.

## Consequences

### Positive

- A full `dbt build` finishes in under a minute on a MEDIUM warehouse at the default window (47
  seconds, observed 2026-09-22), which makes the iteration loop fast enough to actually use.
- Widening the window is one edit in one file, and it applies consistently to every fact.
- The demo stays inside the 5-minute command timeout dbt Wizard enforces without anyone thinking about
  it.

### Negative

- **Omitting the filter is invisible until the bill arrives.** The model compiles, builds, and returns
  correct — just very expensive — results. Nothing in dbt warns about it. This is the single most
  expensive mistake an agent can make in this repo, which is why it is written down rather than left
  to be inferred from the neighbouring models.
- Changing the window invalidates every downstream table and needs a full rebuild. Downstream models
  have no idea the window moved.
- Row counts in this project are a function of a config value, not of the data. Any documented count
  needs the window stated alongside it.

## See also

- [Source inventory](../reference/source-inventory.md)
- [How to add a staging model](../how-to/add-a-staging-model.md)
