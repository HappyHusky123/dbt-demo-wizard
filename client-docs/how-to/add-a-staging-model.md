# Add a staging model

Goal: bring a new table from the TPC-DS share into `STAGE` as a renamed, typed view.

## Before you start

**Read [ADR-0003](../adr/0003-conformed-dim-and-fct-models-in-models-intermediate.md)** to confirm the
work belongs in `models/staging` and not a layer further down. Staging is a rename and nothing else —
if what you actually need is a calculation, a join, or a banding, that belongs in `CURATED` and the
guide you want is [add a mart model](./add-a-mart-model.md).

**If the table is a fact, read [ADR-0007](../adr/0007-date-key-window-on-fact-staging-models.md)
before writing any SQL.** The TPC-DS fact tables run to tens of billions of rows. Omitting the
date-key filter produces a model that compiles, builds, and returns correct results at a cost nobody
authorized. Nothing in dbt warns about it.

## 1. Declare the source table

In `models/staging/_tpcds__sources.yml`, add an entry under `tables:`. The `sources:` block itself
already exists — database, schema, loader and tags are set there and do not need repeating.

```yaml
      - name: catalog_sales
        description: >
          What this table is, its approximate size at the 10 TB scale factor, and
          which column it is partitioned on if that matters downstream.
        config:
          meta:
            grain: One row per <...>
```

## 2. Write the model

Create `models/staging/stg_tpcds__<table>.sql`. Name it `stg_<source>__<entity>` — the double
underscore separates source system from entity.

Open with a `{# ... #}` comment saying what the table is and calling out anything a reader would trip
over. The body is two CTEs and nothing else:

```sql
with source as (

    select * from {{ source('tpcds', 'catalog_sales') }}
    where cs_sold_date_sk between {{ var('tpcds_start_date_sk') }}
                              and {{ var('tpcds_end_date_sk') }}

),

renamed as (

    select
        -- keys
        cs_order_number         as order_number,
        cs_item_sk              as item_key,
        cs_sold_date_sk         as sold_date_key,

        -- measures
        cs_quantity             as quantity_sold,
        cs_net_paid             as net_paid_amount

    from source

)

select * from renamed
```

Rules:

- **Facts filter on the date-key window; dimensions do not.** Use the table's own date-key column:
  `ss_sold_date_sk`, `sr_returned_date_sk`, `cs_sold_date_sk`, `ws_sold_date_sk`. Filtering a
  dimension would silently drop conformed members and break relationship tests downstream.
- **Rename every column.** `_sk` becomes `_key`, `_amt`/`_paid` becomes `_amount`, flags become
  `_flag`, dates become `_date`. Drop the source's table-prefix letters.
- **Group the select list with comments** — `-- keys`, `-- attributes`, `-- measures`.
- **No business logic.** No `case`, no derived measure, no join. If you want to reach for one, it
  belongs in `CURATED`.
- **No config block.** `dbt_project.yml` already materializes `models/staging` as a view in `STAGE`.

## 3. Add the YAML entry

In `models/staging/_staging__models.yml`:

```yaml
  - name: stg_tpcds__catalog_sales
    description: One line on what it is and its size at the current scale factor.
    columns:
      - name: order_number
        description: ...
        data_tests:
          - not_null
      - name: item_key
        description: ...
        data_tests:
          - not_null
```

Document the keys and anything whose meaning is not obvious from the name. Staging does not need every
column documented the way `DATA_VIZ` does — the source YAML carries the table-level description and
the renames are self-explanatory. Keys get tests: `unique` + `not_null` on a dimension's key,
`not_null` on a fact's foreign keys, and a `dbt_utils.unique_combination_of_columns` if the fact's
grain is a key pair.

## 4. Build and check

```bash
dbt compile --select stg_tpcds__<table>
dbt build   --select stg_tpcds__<table>
```

Then **check the compiled SQL for the date filter** if it is a fact:

```bash
grep -n "between" target/compiled/dbt_demo_wizard/models/staging/stg_tpcds__<table>.sql
```

A view builds in under a second either way, so a fast build is not evidence the filter is there. The
compiled SQL is.

## Definition of done

1. `dbt build --select stg_tpcds__<table>` passes.
2. The source table is declared in `_tpcds__sources.yml` with a grain.
3. The model is in `_staging__models.yml` with key tests.
4. If it is a fact, the compiled SQL contains the date-key predicate.
5. `dbt parse` has been re-run.

## See also

- [Source inventory](../reference/source-inventory.md) — what is already in the share
- [ADR-0007: the date-key window](../adr/0007-date-key-window-on-fact-staging-models.md)
