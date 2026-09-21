# dbt-demo-wizard

A dbt project built for the "Harness Engineering with dbt Cloud" Tech Talk Tuesday demo.

It reads TPC-DS retail benchmark data from the Snowflake sample data share and transforms it through
three layers in `DEMO_DB`. The project exists to be read by an agent as much as to be run: dbt Wizard
in the Studio IDE and Cortex Code in VS Code are two consumers of the same repo.

## Layers

| Folder | Schema | Purpose | Materialization |
|---|---|---|---|
| `models/staging` | `STAGE` | Bronze. 1:1 with source, renamed and typed, no business logic | view |
| `models/intermediate` | `CURATED` | Silver. Conformed dimensions and facts, business logic lives here | table |
| `models/marts` | `DATA_VIZ` | Gold. Presentation models shaped for BI consumption | table |

Model prefixes follow the layer's purpose rather than its folder name:

- `stg_<source>__<entity>` in STAGE
- `dim_<entity>` and `fct_<process>` in CURATED
- `rpt_<subject>` in DATA_VIZ

`models/intermediate` holds `dim_` and `fct_` models rather than `int_` models because the CURATED
schema is defined as the conformed dimension and fact layer, not a staging-to-mart waypoint.

## Source data

Everything comes from `SNOWFLAKE_SAMPLE_DATA`, a read-only inbound share. The scale factor is a
project variable:

```yaml
vars:
  tpcds_schema: TPCDS_SF10TCL      # the 10 TB set; TPCDS_SF100TCL is identical in structure
  tpcds_start_date_sk: 2452276     # 2002-01-01
  tpcds_end_date_sk:   2452282     # 2002-01-07
```

`STORE_SALES` is roughly 28.8 billion rows even at `SF10TCL`, so both fact staging models filter on
the date surrogate key. The fact tables are partitioned on that key, so the predicate prunes
micro-partitions hard. Widen the window for a bigger number on stage, narrow it if a build drags:

| Window | `tpcds_end_date_sk` |
|---|---|
| One week (default) | `2452282` |
| January 2002 | `2452306` |
| All of 2002 | `2452640` |

dbt Wizard stops a command after 5 minutes regardless of the warehouse statement timeout, so keep
`dbt build` comfortably under that.

## Environments

Schema routing is handled by `macros/generate_schema_name.sql`. Production uses the custom schema
name verbatim; everything else prefixes it with the developer schema.

| | Production (target name `prod`) | Development |
|---|---|---|
| `models/staging` | `DEMO_DB.STAGE` | `DEMO_DB.dbt_jacob_STAGE` |
| `models/intermediate` | `DEMO_DB.CURATED` | `DEMO_DB.dbt_jacob_CURATED` |
| `models/marts` | `DEMO_DB.DATA_VIZ` | `DEMO_DB.dbt_jacob_DATA_VIZ` |

The production environment in dbt Cloud must have its **target name** set to `prod`, not just its
schema. If it is left at the default, production writes to the prefixed development schemas.

## Snowflake setup

`snowflake/01_setup_demo_environment.sql` provisions everything this project needs: `DEMO_WH`,
`DEMO_DB` with its three schemas, `DBT_DEMO_ROLE`, and the `IMPORTED PRIVILEGES` grant that unlocks
the sample data share. Run it top to bottom as `ACCOUNTADMIN`. It is idempotent.

## Running it

```bash
dbt deps
dbt parse                       # no warehouse cost
dbt compile                     # no warehouse cost
dbt build --select staging      # views and seeds, seconds
dbt build                       # the whole project
```
