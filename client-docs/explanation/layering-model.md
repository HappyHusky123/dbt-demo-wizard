# The layering model

Why this project has three layers, what each one promises, and why `CURATED` is a destination rather
than a waypoint.

## Three schemas, not three folders

The layering is a **Snowflake** structure before it is a dbt structure. `DEMO_DB` is provisioned with
three schemas, each granted separately to `DBT_DEMO_ROLE`:

| Schema | Layer | Promise | Materialization |
|---|---|---|---|
| `STAGE` | Bronze | Mirrors the source, renamed and typed. No business logic. | view |
| `CURATED` | Silver | Conformed dimensions and facts. Grain and keys are stable. | table |
| `DATA_VIZ` | Gold | Shaped for a named consumer. Expected to change with it. | table |

The dbt folders — `models/staging`, `models/intermediate`, `models/marts` — map onto those schemas
one-to-one. That mapping is what creates the naming collision with dbt's own conventions, and
resolving it is [ADR-0003](../adr/0003-conformed-dim-and-fct-models-in-models-intermediate.md).

## What each layer is actually for

**`STAGE` is a rename, and nothing else.** `stg_tpcds__store_sales` takes `ss_sold_date_sk` and calls
it `sold_date_key`. It does not compute margin, it does not join, it does not band anything. The one
thing it is allowed to do beyond renaming is filter on the date-key window
([ADR-0007](../adr/0007-date-key-window-on-fact-staging-models.md)), because that is a cost control
rather than a transformation. Materialized as views, so a change costs nothing to deploy.

Keeping business logic out of `STAGE` is what makes it cheap to answer "what does the source actually
say?" — you read one model and it is a column list.

**`CURATED` is where a business question gets answered once.** Margin is defined here, in
`fct_store_sales`, as `net_paid_amount - extended_wholesale_cost_amount`. The customer spend bands are
defined here, in `dim_customer`. The generation bands, the promotion channel list, the region rollup —
all here, each in exactly one place.

The defining property is that **`CURATED` is a layer someone else is entitled to read.** It is granted
separately. A notebook or a semantic model could point at `CURATED.fct_store_sales` and be a legitimate
consumer. That is what makes it a destination.

**`DATA_VIZ` is shaped for whoever is asking.** `rpt_daily_store_sales` exists because the retail
performance dashboard wants one row per store per day with sales and returns side by side. It is
denormalized, pre-aggregated, and it carries no definition of its own — every measure in it traces
back to a definition in `CURATED`.

## Why there are no `int_` models

dbt's convention reserves `models/intermediate` for purpose-built stepping stones: a model that exists
only to be consumed by one mart, with no independent meaning.

This project has none, on purpose. If a transformation needs a stepping stone, it is a CTE inside the
model that needs it. A separate node buys you a materialization you did not want, a name that has to
mean something, and a place for a second consumer to attach to something that was never meant to be
stable.

The test is ownership: **if you cannot say who is entitled to read a model and what its grain
promises, it should not be a node.** Every model in `models/intermediate` passes that test —
`dim_customer` promises one row per customer, `fct_store_sales` promises one row per item per ticket,
and both are readable by anyone granted `CURATED`.

## Why a fact denormalizes its dates

`fct_store_sales` carries `sold_date`, `sold_year`, `sold_month_of_year` and `sold_year_month`
alongside `sold_date_key`, duplicating columns that already exist in `dim_date`.

This is a deliberate exception to "one fact, one home", and the reasoning is consumer count. Every
model downstream of the fact wants the calendar date, and without the denormalization every one of
them joins 73,000 rows of `dim_date` to get it. The duplication is four columns; the alternative is a
join in every consumer forever.

The same reasoning does not extend to attributes with real cardinality. `dim_store`'s region is not
denormalized onto the fact, because only some consumers want it and the join is cheap once the fact
has been aggregated.

## How environments route

The schema a model lands in is not configured per model. `dbt_project.yml` sets `+schema` at the folder
level and `macros/generate_schema_name.sql` resolves it per environment: verbatim in production,
developer-prefixed everywhere else. The full behavior and its one silent failure mode are in
[ADR-0002](../adr/0002-three-schema-layering-and-name-routing.md).

| | Production (target name `prod`) | Development |
|---|---|---|
| `models/staging` | `DEMO_DB.STAGE` | `DEMO_DB.dbt_jacob_STAGE` |
| `models/intermediate` | `DEMO_DB.CURATED` | `DEMO_DB.dbt_jacob_CURATED` |
| `models/marts` | `DEMO_DB.DATA_VIZ` | `DEMO_DB.dbt_jacob_DATA_VIZ` |
