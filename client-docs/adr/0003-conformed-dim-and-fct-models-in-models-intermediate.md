# ADR-0003: Conformed `dim_` and `fct_` Models Live in `models/intermediate`

## Status

Accepted

## Date

2026-09-22

## Context

dbt's own project structure guidance describes three model folders with a specific meaning attached
to each:

| dbt's convention | Folder | Prefix | Role |
|---|---|---|---|
| Staging | `models/staging` | `stg_` | One model per source table, renamed and typed |
| Intermediate | `models/intermediate` | `int_` | Purpose-built stepping stones between staging and marts |
| Marts | `models/marts` | `dim_` / `fct_` | The business-facing dimensional models |

Under that convention, `models/intermediate` holds disposable `int_` models, and the conformed
dimensions and facts land in `models/marts` alongside everything else a consumer reads.

This project's Snowflake layout does not have three folders, it has **three schemas**, provisioned by
`snowflake/01_setup_demo_environment.sql` and granted separately:

| Schema | Layer | What it is |
|---|---|---|
| `STAGE` | Bronze | 1:1 with source, no business logic |
| `CURATED` | Silver | Conformed dimensions and facts, business logic lives here |
| `DATA_VIZ` | Gold | Presentation models shaped for a specific BI consumer |

`CURATED` is a **destination**, not a waypoint. It is the layer another team would point a notebook or
a semantic model at, and it is the layer whose grain and keys we promise not to churn. `DATA_VIZ` is
the opposite: it is deliberately shaped for the
[retail performance dashboard](../../models/marts/_exposures.yml) and is expected to change when that
dashboard changes.

Mapping those three schemas onto dbt's three folders makes `models/intermediate` the home of `CURATED`
and `models/marts` the home of `DATA_VIZ`. That is a good fit for the *schemas*. It is a direct
collision with dbt's guidance about the *prefixes*, because the models in `models/intermediate` are
conformed dimensions and facts, and the models in `models/marts` are reporting models.

The alternative was to rename the folders — `models/curated` and `models/data_viz` — so folder, schema
and prefix all agree. That was rejected because dbt tooling, examples, and every agent trained on dbt's
documentation assume the three canonical folder names, and renaming them trades one small surprise for
a much larger one.

## Decision

Model prefix follows **the layer's purpose**, not the folder's name.

| Folder | Schema | Prefix | Materialization | Grain |
|---|---|---|---|---|
| `models/staging` | `STAGE` | `stg_<source>__<entity>` | view | One row per source row |
| `models/intermediate` | `CURATED` | `dim_<entity>` / `fct_<process>` | table | Conformed dimension or business-process fact |
| `models/marts` | `DATA_VIZ` | `rpt_<subject>` | table | Whatever the consuming report needs |

Specifically:

- **There are no `int_` models in this project.** If a transformation needs a stepping stone, it is a
  CTE inside the model that needs it, not a separate node. A model in `models/intermediate` is a
  conformed dimension or fact that something else is entitled to read.
- **A new reporting model goes in `models/marts` with an `rpt_` prefix** and lands in `DATA_VIZ`. This
  is the case that conflicts with dbt's default most often, because "add a model that aggregates a
  fact" reads like intermediate work and is not.
- **A new conformed dimension or fact goes in `models/intermediate`** with a `dim_` or `fct_` prefix
  and lands in `CURATED`.

Schema routing is not configured per model. `macros/generate_schema_name.sql` maps the folder-level
`+schema` in `dbt_project.yml` onto the right schema per environment — see
[ADR-0002](./0002-three-schema-layering-and-name-routing.md).

## Consequences

### Positive

- The schema name and the model prefix always agree. Reading `CURATED.dim_store` or
  `DATA_VIZ.rpt_daily_store_sales` in a Snowflake query history tells you which layer you are in
  without opening the repo.
- `CURATED` can be granted to a consumer independently of `DATA_VIZ`, because it is a stable layer
  with a promise attached rather than a pile of intermediate steps.
- No `int_` models means no debate about whether a stepping stone deserves to be a node. It does not.

### Negative

- **An agent trained on dbt's documentation will get this wrong by default.** Asked for a new
  aggregate model, the pattern-matched answer is `int_<something>` in `models/intermediate`, which is
  wrong twice over: wrong prefix and wrong layer. This ADR exists so the correct answer is available
  in the repo rather than depending on whoever is prompting remembering to say it.
- A developer arriving from another dbt project has to unlearn the folder-to-prefix mapping. The
  folder names are dbt's; the meanings are ours.
- dbt's own docs and blog examples read as contradicting this repo. They are not wrong, they are
  describing a two-schema layout this project does not use.

## See also

- [Why CURATED is a layer, not a waypoint](../explanation/layering-model.md)
- [How to add a mart model](../how-to/add-a-mart-model.md)
- [ADR-0002: three fixed schemas and name routing](./0002-three-schema-layering-and-name-routing.md)
