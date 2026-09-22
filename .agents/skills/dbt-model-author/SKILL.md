---
name: dbt-model-author
description: "Author, extend or review a dbt model in this project, following the project's own standards rather than dbt's defaults. Use this skill whenever the user wants to add a model, create a new report or mart, build a staging model, bring in a new source table, aggregate a fact, add a dimension, refactor a model, or asks where a model should live and what it should be called. Also trigger when the user mentions \"add a model\", \"new model\", \"weekly sales\", \"by region\", \"rpt_\", \"stg_\", \"dim_\", \"fct_\", \"which folder\", \"what should I call it\", or edits any file under `models/`."
---

# dbt-model-author

Adds or changes a model in this dbt project so it matches the standards recorded in `client-docs/`.

This skill is **thin and orchestration-shaped**. It does not carry the standards; it makes sure you
read them before you write SQL. The substance lives in `client-docs/adr/` and `client-docs/how-to/`,
and those are the source of truth.

## Read this before writing any SQL

**`client-docs/adr/0003-conformed-dim-and-fct-models-in-models-intermediate.md`**

This project's mapping of folder to model prefix **differs from dbt's own documented convention**.
Choosing a folder or a prefix from memory, or from what dbt's docs say, will be wrong. Read the ADR
and apply what it says.

The most common case this matters for: a request to "add a model that aggregates a fact" reads like
intermediate work and is not. Read the ADR before deciding.

## Pick the operation

| Intent | Operation |
|---|---|
| A new reporting or presentation model | [Add a mart model](#add-a-mart-model) |
| A new source table brought into the project | [Add a staging model](#add-a-staging-model) |
| A new conformed dimension or fact | [Add a curated model](#add-a-curated-model) |
| Change an existing model | [Change a model](#change-a-model) |

---

## Add a mart model

1. Read `client-docs/adr/0003-...` and confirm the model belongs in `models/marts`. If it belongs in
   `models/intermediate` instead, switch to [Add a curated model](#add-a-curated-model).
2. Follow `client-docs/how-to/add-a-mart-model.md` step by step. It carries the file layout, the
   required YAML shape and the definition of done.
3. Before inventing a measure, check `client-docs/reference/metric-definitions.md`. A measure computed
   two ways in two models is a defect, not a convenience.
4. If the model reads more than one fact, read
   `client-docs/adr/0005-aggregate-before-joining-facts.md` first. Getting this wrong produces
   plausible, silently inflated numbers that no test in the project will catch except the one the
   how-to tells you to add.
5. Validate: `dbt compile --select <model>`, then `dbt build --select <model>+`.

## Add a staging model

1. Read `client-docs/adr/0007-date-key-window-on-fact-staging-models.md`. **If the source is a fact
   table, the date-key filter is mandatory.** Omitting it produces a model that builds correctly and
   scans tens of billions of rows. Nothing in dbt warns about it.
2. Follow `client-docs/how-to/add-a-staging-model.md`.
3. Declare the source table in `models/staging/_tpcds__sources.yml` as well as writing the model. A
   staging model without a source entry is invisible to lineage.
4. Validate, then confirm the filter survived compilation:
   `grep -n "between" target/compiled/dbt_demo_wizard/models/staging/<model>.sql`. A view builds in
   under a second either way, so a fast build proves nothing.

## Add a curated model

A conformed dimension or fact in `models/intermediate`, landing in `CURATED`.

1. Read `client-docs/adr/0003-...` and `client-docs/explanation/layering-model.md`. The test for
   whether something belongs here: **you can say who is entitled to read it and what its grain
   promises.** If you cannot, it is a CTE inside the model that needs it, not a node.
2. Otherwise follow `client-docs/how-to/add-a-mart-model.md` — the steps are the same; only the
   folder, prefix and schema differ. Use `access: protected` rather than `public` for a fact.
3. Business logic belongs here and only here. If you are tempted to put a calculation in `STAGE` or
   redefine one in `DATA_VIZ`, that is the signal that this is the layer you actually wanted.

## Change a model

1. **Run impact analysis first.** Use the `dbt-impact-analysis` skill, or at minimum establish what
   reads the column you are about to touch and whether any consumer is an exposure.
2. If the model carries `contract: enforced`, a column change is a breaking change by construction.
   Read `client-docs/adr/0006-enforced-contracts-on-dashboard-facing-models.md` and change the YAML
   and the SQL together.
3. Keep the YAML in step with the SQL. A column added to the select list without a description is an
   incomplete change — column descriptions are what make lineage answers useful.
4. Validate with `dbt build --select <model>+`, not `--select <model>`. The point is the downstream.

---

## Always

These hold for every operation above and are the things most often missed.

- **Every rate goes through `{{ safe_divide(...) }}`.** Raw `/` between two columns does not appear in
  a model in this project. `client-docs/adr/0004-safe-divide-for-all-rate-calculations.md`.
- **Every model gets a YAML entry** with a description, `meta.grain`, a description on every column,
  a `not_null` on the grain columns, and a uniqueness test on the grain.
- **Reference upstream models with `{{ ref(...) }}`**, never a schema-qualified name. Schema routing
  is `macros/generate_schema_name.sql`'s job.
- **No per-model `+schema` or `+materialized`.** The folder-level config in `dbt_project.yml` already
  handles both.
- **Open every model with a `{# ... #}` comment block** saying what it is, what its grain is, and
  anything non-obvious. Every existing model has one.
- **Check the schema in the build output.** Development builds land in `dbt_<name>_<SCHEMA>`. A bare
  `STAGE`/`CURATED`/`DATA_VIZ` means you are building into production.
- **Re-run `dbt parse` when you are done**, so the agent index reflects what you changed.

## Definition of done

1. `dbt build --select <model>+` passes.
2. Every column has a description; the grain has a `not_null` and a uniqueness test.
3. The build landed in a developer-prefixed schema.
4. If a dashboard will read it, `models/marts/_exposures.yml` lists it.
5. `dbt parse` has been re-run.

## Reference files

| File | When to read |
|---|---|
| `client-docs/adr/0003-conformed-dim-and-fct-models-in-models-intermediate.md` | **Always, first.** Folder and prefix |
| `client-docs/how-to/add-a-mart-model.md` | Adding to `models/marts` or `models/intermediate` |
| `client-docs/how-to/add-a-staging-model.md` | Adding to `models/staging` |
| `client-docs/adr/0004-safe-divide-for-all-rate-calculations.md` | Any rate or percentage |
| `client-docs/adr/0005-aggregate-before-joining-facts.md` | Any model reading two facts |
| `client-docs/adr/0007-date-key-window-on-fact-staging-models.md` | Any staging model over a fact |
| `client-docs/reference/metric-definitions.md` | Before defining a measure |
| `client-docs/reference/macros.md` | Macro signatures |
| `client-docs/explanation/layering-model.md` | Deciding which layer something belongs in |
