# Project context

The orientation document. Read this before writing a model; it routes to everything else.

## What this repo is

A dbt project that transforms TPC-DS retail benchmark data through three layers in the Snowflake
database `DEMO_DB`. The business domain is store retail: sales tickets, returns, products, stores,
customers, promotions.

It exists to be **read by an agent as much as to be run**. dbt Wizard in the terminal, Cortex Code in
VS Code and any other harness pointed at this directory are all consumers of the same repository. The
standards live here, in `client-docs/` and `.agents/skills/`, not in any one tool's configuration. That
is the whole design intent: swap the surface, keep the harness.

## What the data means

TPC-DS is a synthetic benchmark, not a real business, and two of its properties will surprise anyone
who reads the numbers as if they were real:

- **Margins are negative.** The generator sets wholesale costs above what customers pay, so
  `gross_margin_amount` is negative on essentially every line and the daily average sits near -828
  (observed 2026-09-22, seven-day window). The margin formula is correct; the benchmark is simply not
  a profitable retailer. Tests over margin are written as guardrails against the *formula* changing,
  not as assertions that the business is healthy.
- **Row counts are a config value.** Every fact staging model filters on a date-key window declared in
  `dbt_project.yml` ([ADR-0007](../adr/0007-date-key-window-on-fact-staging-models.md)). Change the
  window and every count in this repo changes. Any documented count states its window.

One thing in the project is genuinely local rather than generated: `seeds/store_sales_regions.csv`
maps US state codes to sales regions and a named manager per region. TPC-DS has no region concept, so
region is the one business rule this project owns outright. It is a seed rather than a source because
it is small, hand-maintained, and reviewed in a pull request like any other change.

## How the layers relate

Three schemas, three folders, three jobs. The mapping between folder and schema is set by
`dbt_project.yml`; the routing that makes it work per environment is in
[ADR-0002](../adr/0002-three-schema-layering-and-name-routing.md), and what belongs in each layer is
[ADR-0003](../adr/0003-conformed-dim-and-fct-models-in-models-intermediate.md).

```
SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL   (read-only inbound share)
        │
        ▼
STAGE       models/staging        stg_tpcds__*     views, renamed and typed, no business logic
        │
        ▼
CURATED     models/intermediate   dim_* / fct_*    conformed dimensions and facts, business logic
        │
        ▼
DATA_VIZ    models/marts          rpt_*            presentation models for one named consumer
        │
        ▼
retail_performance_dashboard      (exposure, owner: Retail Analytics)
```

The detail is in [the layering model](./layering-model.md). The short version: `STAGE` is a rename,
`CURATED` is where a business question gets answered once, and `DATA_VIZ` is shaped for whoever is
asking.

## Who reads the output

One exposure, declared in `models/marts/_exposures.yml`: the **retail performance dashboard**, owned
by Retail Analytics, fed by all three `rpt_` models. It is the reason the `DATA_VIZ` layer exists, and
it is why a column change in `models/marts` is a conversation rather than an edit.

`rpt_daily_store_sales` additionally carries an enforced contract
([ADR-0006](../adr/0006-enforced-contracts-on-dashboard-facing-models.md)), so a breaking change to it
fails the build rather than the dashboard.

## Open items

- The margin guardrail floor on `fct_store_sales.gross_margin_amount` is set from a seven-day
  observation. Widening the date window is likely to need it re-measured.
- No incremental materialization anywhere. `fct_store_sales` would be a delete+insert on
  `sold_date_key` in production; a full refresh is deliberate here because it is one less thing to
  explain.
- Only `store_sales` and `store_returns` are modeled. `catalog_sales` and `web_sales` are in the share
  and unused.

## Where to go next

| You want | Read |
|---|---|
| To add a model | [How to add a mart model](../how-to/add-a-mart-model.md) or [a staging model](../how-to/add-a-staging-model.md) |
| To run the project | [How to run the project](../how-to/run-the-project.md) |
| Warehouse, database, role, schema names | [Snowflake environment](../reference/snowflake-env.md) |
| What a measure means | [Metric definitions](../reference/metric-definitions.md) |
| What is in the source | [Source inventory](../reference/source-inventory.md) |
| Why something is the way it is | [The decision log](../adr/) |
