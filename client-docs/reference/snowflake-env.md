# Snowflake environment

Literal values. Provisioned by `snowflake/01_setup_demo_environment.sql`, which is idempotent and run
top to bottom as `ACCOUNTADMIN`.

## Objects

| Object | Name | Notes |
|---|---|---|
| Warehouse | `DEMO_WH` | `MEDIUM`, `STANDARD`, `AUTO_SUSPEND = 60` |
| Database | `DEMO_DB` | The default `PUBLIC` schema is dropped by the setup script |
| Role | `DBT_DEMO_ROLE` | Granted to `SYSADMIN` |
| Source database | `SNOWFLAKE_SAMPLE_DATA` | Read-only inbound share from `SFC_SAMPLES.SAMPLE_DATA` |

`AUTO_SUSPEND = 60` is deliberate. Between working sessions the warehouse should be off.

## Schemas

| Schema | Layer | dbt folder | Materialization |
|---|---|---|---|
| `DEMO_DB.STAGE` | Bronze | `models/staging` | view |
| `DEMO_DB.CURATED` | Silver | `models/intermediate` | table |
| `DEMO_DB.DATA_VIZ` | Gold | `models/marts` | table |

Seeds land in `STAGE`.

## Schema routing by environment

Resolved by `macros/generate_schema_name.sql`. See
[ADR-0002](../adr/0002-three-schema-layering-and-name-routing.md).

| dbt folder | Production (target name `prod`) | Development |
|---|---|---|
| `models/staging` | `DEMO_DB.STAGE` | `DEMO_DB.<target_schema>_STAGE` |
| `models/intermediate` | `DEMO_DB.CURATED` | `DEMO_DB.<target_schema>_CURATED` |
| `models/marts` | `DEMO_DB.DATA_VIZ` | `DEMO_DB.<target_schema>_DATA_VIZ` |

Production is identified by **target name**, not target schema. A production environment left at the
default target name writes into the developer-prefixed schemas and raises no error.

## Grants held by `DBT_DEMO_ROLE`

| Grant | On |
|---|---|
| `USAGE`, `OPERATE`, `MONITOR` | `WAREHOUSE DEMO_WH` |
| `USAGE`, `CREATE SCHEMA` | `DATABASE DEMO_DB` |
| `ALL PRIVILEGES` | `SCHEMA DEMO_DB.STAGE`, `.CURATED`, `.DATA_VIZ` |
| `SELECT` on all + future tables and views | `DATABASE DEMO_DB` |
| `USAGE` on future schemas | `DATABASE DEMO_DB` |
| `IMPORTED PRIVILEGES` | `DATABASE SNOWFLAKE_SAMPLE_DATA` |

`CREATE SCHEMA ON DATABASE DEMO_DB` is what lets a development environment build into
`DEMO_DB.dbt_<name>_*` without anyone provisioning those schemas first.

`IMPORTED PRIVILEGES` is the only lever a shared database exposes. `GRANT SELECT ON ALL TABLES IN
SCHEMA` does not work against `SNOWFLAKE_SAMPLE_DATA`, and neither does any schema-level grant. One
statement covers every schema in the share.

## Project variables

Declared in `dbt_project.yml`.

| Variable | Default | Meaning |
|---|---|---|
| `tpcds_schema` | `TPCDS_SF10TCL` | Scale factor. `TPCDS_SF100TCL` is structurally identical at 100 TB |
| `tpcds_start_date_sk` | `2452276` | 2002-01-01. Start of the fact window |
| `tpcds_end_date_sk` | `2452282` | 2002-01-07. End of the fact window |

`d_date_sk` is the Julian day number, which is why these read as plain integers. Window values:
`2452282` = one week, `2452306` = January 2002, `2452640` = all of 2002. See
[ADR-0007](../adr/0007-date-key-window-on-fact-staging-models.md).

## Connection

Profile `dbt_demo_wizard`, target `dev`, in `~/.dbt/profiles.yml`. Key-pair authentication; the
private key lives in `creds/`, which is gitignored and must stay that way.

| Field | Value |
|---|---|
| `type` | `snowflake` |
| `database` | `DEMO_DB` |
| `warehouse` | `DEMO_WH` |
| `role` | `DBT_DEMO_ROLE` |
| `schema` | `STAGE` |
| `threads` | `16` |

Engine is dbt Fusion (`dbt-fusion 2.0.0-preview.218`, observed 2026-09-22). Note that Fusion rejects
the `+required_tests` config as an unrecognised custom config, which is why marts tests are declared
per model rather than enforced by a project-level rule.

## Recovery

If `GRANT IMPORTED PRIVILEGES` fails with "Database SNOWFLAKE_SAMPLE_DATA does not exist", the account
did not provision the share:

```sql
SHOW SHARES LIKE '%SAMPLE_DATA%';
CREATE DATABASE SNOWFLAKE_SAMPLE_DATA FROM SHARE SFC_SAMPLES.SAMPLE_DATA;
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_SAMPLE_DATA TO ROLE DBT_DEMO_ROLE;
```
