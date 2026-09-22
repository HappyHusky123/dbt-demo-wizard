# dbt_demo_wizard

## What this repo is

A dbt project on Snowflake that transforms TPC-DS retail benchmark data through three layers in
`DEMO_DB`. Engine is dbt Fusion; the source is the read-only `SNOWFLAKE_SAMPLE_DATA` share.

| Folder | Schema | Layer |
|---|---|---|
| `models/staging` | `STAGE` | Mirrors the source, renamed and typed. No business logic |
| `models/intermediate` | `CURATED` | Conformed dimensions and facts. Business logic lives here |
| `models/marts` | `DATA_VIZ` | Presentation models for a named consumer |

It is written to be read by an agent as much as to be run. The standards live in `client-docs/` and
`.agents/skills/`, in the repository, not in any one tool's configuration.

## Before you write any model, read

- **`client-docs/adr/`** — the decision log, and the authority. **Read the index first.** This project
  diverges from dbt's own documented conventions in more than one place, and each divergence is
  recorded there with its reasoning. Do not infer a convention from dbt's docs or from what a
  neighbouring file appears to do; the ADR states it.
- `client-docs/explanation/project-context.md` — what the data means and how the layers relate. It
  routes to everything else.
- `client-docs/how-to/add-a-mart-model.md` or `client-docs/how-to/add-a-staging-model.md` — the recipe
  for the thing you are about to do.
- `client-docs/reference/metric-definitions.md` — before defining any measure. Check whether it
  already has a definition.
- `client-docs/reference/snowflake-env.md` — literal database, warehouse, role and schema values.

## Rules

- **Consult `client-docs/adr/` before choosing a model's folder, prefix or layer.** This is the one
  that gets missed, and the failure is silent: the model builds fine and sits in the wrong place.
- Every model needs a YAML entry with a description, `meta.grain`, a description on every column, a
  `not_null` on its grain columns, and a uniqueness test on its grain.
- Every rate or percentage goes through `{{ safe_divide(...) }}`. Raw `/` between two columns does not
  appear in a model here.
- Every staging model over a **fact** table filters on the `tpcds_start_date_sk` /
  `tpcds_end_date_sk` vars. Dimensions do not. Omitting the filter on a fact scans tens of billions of
  rows and raises no warning.
- Models reference each other with `{{ ref(...) }}`, never a schema-qualified name.
- No per-model `+schema` or `+materialized`. The folder-level config in `dbt_project.yml` handles it.
- Secrets never enter the repo. `creds/` is gitignored and stays that way.

## Definition of done

1. `dbt build --select <model>+` passes.
2. Every column has a description; the grain has a `not_null` and a uniqueness test.
3. The build landed in a developer-prefixed schema (`dbt_<name>_DATA_VIZ`, not `DATA_VIZ`).
4. `dbt parse` has been re-run, so the agent index reflects the change.

## When you get something wrong

Write an ADR in `client-docs/adr/` using Context / Decision / Consequences, then update whatever
document pointed the wrong way. The `adr-author` skill handles the numbering and the index.

A better prompt helps one person once. A document in the repository is read by everything that comes
after.

## Commands

```bash
dbt deps
dbt parse                        # no warehouse cost; rebuilds the agent index
dbt compile --select <model>     # no warehouse cost; catches ref and macro errors
dbt build   --select <model>+    # the model and everything downstream
dbt build                        # everything: 92 nodes, ~47s at the default window
```

Cost is controlled by `tpcds_end_date_sk` in `dbt_project.yml`, not by warehouse size. See
`client-docs/how-to/run-the-project.md`.

## Skills

In `.agents/skills/`, discovered at session start. Editing one requires a new session.

- `dbt-model-author` — add or change a model to this project's standards
- `dbt-impact-analysis` — what breaks if this changes, including exposures and their owners
- `adr-author` — record a decision in `client-docs/adr/`
- `diataxis` — which documentation bucket something belongs in
- `skill-author` — add, refine or audit a skill

See `.agents/skills/README.md`.
