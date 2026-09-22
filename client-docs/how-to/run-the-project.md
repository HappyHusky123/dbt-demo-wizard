# Run the project

Goal: build and test the project, and control what the build costs.

## First run

```bash
dbt deps                        # install dbt_utils
dbt parse                       # no warehouse cost
dbt build                       # everything: seeds, models, tests
```

At the default one-week window this is **47 seconds and 92 nodes on a MEDIUM warehouse** (observed
2026-09-22). If it takes materially longer, check the date-key window before anything else.

## The everyday loop

```bash
dbt compile --select <model>          # catches ref, macro and column errors, no warehouse cost
dbt build   --select <model>          # the model and its own tests
dbt build   --select <model>+         # plus everything downstream
dbt build   --select +<model>         # plus everything upstream
dbt test    --select <model>          # tests only, model already built
dbt build   --select staging          # all views and seeds, seconds
```

`dbt compile` costs nothing and catches most mistakes. Use it before every build.

## Where your output lands

Development builds land in developer-prefixed schemas: `dbt_jacob_STAGE`, `dbt_jacob_CURATED`,
`dbt_jacob_DATA_VIZ`. Production uses the bare names, and production is identified by **target name**,
not target schema — see [ADR-0002](../adr/0002-three-schema-layering-and-name-routing.md).

Check the schema in the build output. If it says `DATA_VIZ` rather than `dbt_<you>_DATA_VIZ`, you are
building into production.

## Controlling the cost

Every fact staging model filters on a date-key window declared in `dbt_project.yml`
([ADR-0007](../adr/0007-date-key-window-on-fact-staging-models.md)). This is the only lever that
matters — the warehouse size is almost irrelevant next to it.

| Window | `tpcds_end_date_sk` | Use when |
|---|---|---|
| One week (default) | `2452282` | Iterating. The default for a reason |
| January 2002 | `2452306` | You need a month of seasonality |
| All of 2002 | `2452640` | The point is the size of the number |

```yaml
vars:
  tpcds_start_date_sk: 2452276     # 2002-01-01
  tpcds_end_date_sk:   2452282     # 2002-01-07
```

Or override for one command without editing the file:

```bash
dbt build --vars '{tpcds_end_date_sk: 2452306}'
```

Changing the window invalidates every downstream table — nothing downstream knows the window moved, so
rebuild the whole project rather than one model.

`dbt_project.yml` also carries `tpcds_schema`, which selects the scale factor. `TPCDS_SF10TCL` is the
10 TB set; `TPCDS_SF100TCL` is structurally identical at 100 TB. Do not switch to the latter casually.

## Keeping an agent's index fresh

dbt Wizard builds its index from `target/`. A stale manifest is a stale agent — it will answer lineage
questions about models that no longer exist and miss ones you just added.

```bash
dbt parse       # after any change to models, YAML, sources or macros
```

Re-run it after every structural change, and before starting a session where an agent will be asked
about the project. `dbt compile` and `dbt build` also refresh it.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `Database SNOWFLAKE_SAMPLE_DATA does not exist` | The share was not provisioned. See the recovery block at the end of `snowflake/01_setup_demo_environment.sql` |
| A staging build takes minutes | Missing date-key filter. Check the compiled SQL, not the model |
| Model landed in `DATA_VIZ` not `dbt_<you>_DATA_VIZ` | Target name is `prod` |
| Contract failure with a type mismatch | Aggregate's natural type differs from the declared one. See [ADR-0006](../adr/0006-enforced-contracts-on-dashboard-facing-models.md) |
| Agent answers about a model you deleted | `dbt parse` |

## See also

- [Snowflake environment](../reference/snowflake-env.md)
- [Source inventory](../reference/source-inventory.md)
