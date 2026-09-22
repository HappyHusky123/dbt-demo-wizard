# Trace a column end to end

You are new to this project. By the end of this tutorial you will have followed one measure —
`gross_margin_amount` — from the raw share all the way to the dashboard that consumes it, and you will
understand what each of the three layers contributes along the way.

About fifteen minutes. You need a working connection and `dbt deps` already run.

## Setup

```bash
dbt parse
```

No warehouse cost. It reads the project and writes `target/`, which is also what any agent pointed at
this repo builds its index from.

## Step 1: find where the measure is born

`gross_margin_amount` does not exist in the source. Confirm that:

```bash
grep -rn "gross_margin_amount" models/staging/
```

Nothing. The `STAGE` layer is a rename and nothing else — it carries no calculation, no join and no
banding. Now look one layer down:

```bash
grep -rn "gross_margin_amount" models/intermediate/
```

One definition, in `models/intermediate/fct_store_sales.sql`:

```sql
sales.net_paid_amount - sales.extended_wholesale_cost_amount
                                                        as gross_margin_amount,
```

That is the whole idea of `CURATED`: a business question gets answered once, in one place. Read the
comment block at the top of that file — it explains why the project keeps TPC-DS's own
`net_profit_amount` alongside its own margin rather than picking one.

## Step 2: see what the raw inputs look like

```bash
dbt show --inline "select ss_net_paid, ss_ext_wholesale_cost from {{ source('tpcds','store_sales') }}" --limit 5
```

Note that wholesale cost exceeds what the customer paid. This is not a data error — TPC-DS generates
it that way, so margin in this project is negative almost everywhere. Now the same two columns after
staging renamed them:

```bash
dbt show --select stg_tpcds__store_sales --limit 5
```

`ss_net_paid` has become `net_paid_amount`. That is all `STAGE` did.

## Step 3: build the fact and read the measure

```bash
dbt build --select fct_store_sales
```

Watch the schema name in the output. It is developer-prefixed — `dbt_<you>_CURATED`, not `CURATED` —
because you are not running with the target name `prod`. That routing is
`macros/generate_schema_name.sql`, and it is the reason you can build freely without going near
production.

```bash
dbt show --inline "select round(avg(gross_margin_amount), 2) as avg_margin from {{ ref('fct_store_sales') }}" --limit 1
```

You should get something near **-828**. Remember that number.

## Step 4: find everything that reads it

```bash
grep -rln "gross_margin_amount" models/marts/
```

Three models: `rpt_daily_store_sales`, `rpt_category_performance`, `rpt_customer_segment_sales`. Each
aggregates the same measure along a different axis — by store and day, by category and month, by
customer segment and month.

None of them redefines it. Open any one and check: they `sum(gross_margin_amount)` from the fact. The
definition stayed in `CURATED`.

Now go one hop further:

```bash
cat models/marts/_exposures.yml
```

All three feed `retail_performance_dashboard`, owned by Retail Analytics. That is the fourth hop, and
it is the one grep could never have found for you — the dashboard is not a file in this repo. It is
declared metadata, which is exactly what makes a change to any of these three models a conversation
rather than an edit.

## Step 5: build the rest and confirm the number survives

```bash
dbt build --select fct_store_sales+
```

Then compare the fact against one of its consumers:

```bash
dbt show --inline "select round(sum(gross_margin_amount), 2) as total from {{ ref('fct_store_sales') }}" --limit 1
dbt show --inline "select round(sum(gross_margin_amount), 2) as total from {{ ref('rpt_daily_store_sales') }}" --limit 1
```

The two do not match — roughly **-89.88 billion** at the fact and **-89.33 billion** at the report
(observed 2026-09-22, default seven-day window). That is not a bug, and working out why is the last
thing this tutorial will teach you:

```bash
dbt show --inline "select count(*) as null_store_key from {{ ref('fct_store_sales') }} where store_key is null" --limit 1
```

About 2.6 million sales lines carry no store key at all. `rpt_daily_store_sales` inner-joins to
`dim_store`, so those lines drop out. It is not that their keys fail to match — the `relationships`
test on `store_key` passes — it is that a relationships test ignores nulls, and an inner join does
not.

The fact keeps every line. The report keeps every line it can attribute to a store, because a report
grained by store cannot represent a sale with no store. Both are correct at their own grain, and
knowing which one to quote is the difference between a total and a total *of something*.

## Step 6: see what a rate looks like

```bash
grep -n "safe_divide" models/marts/rpt_daily_store_sales.sql
```

Every rate in this project goes through that macro rather than a raw `/`, because the denominators are
counts and amounts that can legitimately be zero and Snowflake errors rather than returning null.

## What you now know

You followed one measure through four hops:

```
SNOWFLAKE_SAMPLE_DATA.store_sales.ss_net_paid       the share
  → stg_tpcds__store_sales.net_paid_amount          STAGE: renamed, nothing else
  → fct_store_sales.gross_margin_amount             CURATED: defined once
  → rpt_*.gross_margin_amount                       DATA_VIZ: aggregated three ways
  → retail_performance_dashboard                    the consumer, with an owner
```

Three things follow from that shape, and each one has a document behind it:

- A measure is defined in exactly one place — [the layering model](../explanation/layering-model.md).
- The folder a model lives in and the prefix it carries are decided by the *layer's* job, not the
  folder's name — [ADR-0003](../adr/0003-conformed-dim-and-fct-models-in-models-intermediate.md).
- Something downstream has an owner, and the repo knows who — `models/marts/_exposures.yml`.

## Next

- [Add a mart model](../how-to/add-a-mart-model.md)
- [Project context](../explanation/project-context.md)
