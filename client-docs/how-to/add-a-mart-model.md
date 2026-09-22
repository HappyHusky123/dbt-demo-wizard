# Add a mart model

Goal: a new reporting model, built and tested, landing in `DATA_VIZ`.

## Before you start

**Read [ADR-0003](../adr/0003-conformed-dim-and-fct-models-in-models-intermediate.md) and decide which
layer your model belongs in.** This project's folder-to-prefix mapping differs from dbt's own
convention, and the difference matters most for exactly this kind of model. Do not choose a folder or a
prefix from memory — the ADR states the rule and why it diverges.

The rest of this guide assumes the ADR sent you to `models/marts`. If it sent you to
`models/intermediate` instead, the steps are the same; only the folder, prefix and schema change.

Skim two more things first:

- [Grain and fan-out](../explanation/grain-and-fan-out.md) if your model reads more than one fact.
- An existing model of similar shape. `rpt_daily_store_sales.sql` is the worked example for two facts
  plus dimensions; `rpt_category_performance.sql` for a fact joined to one dimension.

## 1. State the grain

Write the sentence "one row is ______" before writing any SQL. It determines the `group by`, the
uniqueness test, and whether you have a fan-out problem. It goes in `meta.grain` in the YAML.

If you cannot write the sentence, you do not have a model yet.

## 2. Write the SQL

Create `models/marts/<name>.sql`. Open with a `{# ... #}` block comment that says what the model is,
what its grain is, and anything non-obvious about the business logic — every model in this project has
one, and it is the first thing a reader (human or agent) sees.

Follow the house shape:

- **One CTE per input**, named for what it is, ending in a `final` CTE and `select * from final`.
- **Aggregate each fact to the grain in its own CTE before joining anything**
  ([ADR-0005](../adr/0005-aggregate-before-joining-facts.md)). Join dimensions last, against the
  aggregated side.
- **Left join from the primary fact**, with `coalesce(..., 0)` on measures from the secondary side, so
  a row with no matching activity still reports zero rather than null.
- **Every rate goes through `{{ safe_divide(numerator, denominator, 0) }}`**
  ([ADR-0004](../adr/0004-safe-divide-for-all-rate-calculations.md)). Raw `/` between columns does not
  appear in a model in this project.
- **Reference upstream models with `{{ ref(...) }}`**, never a schema-qualified name. Schema routing
  is the macro's job ([ADR-0002](../adr/0002-three-schema-layering-and-name-routing.md)).
- **Group the select list with comments** — `-- grain`, `-- volume`, `-- value`, `-- returns` — in the
  order the existing models use.

Do not add a `+schema` or `+materialized` config. The folder-level config in `dbt_project.yml` already
puts `models/marts` in `DATA_VIZ` as a table.

## 3. Add the YAML entry

In `models/marts/_marts__models.yml`, add a `models:` entry with:

```yaml
  - name: rpt_<subject>
    description: >
      What it is and what one row means.
    config:
      group: retail_analytics
      access: public
      tags: [reporting, <daily|weekly|monthly>]
      meta:
        grain: One row per <...>
    columns:
      - name: <grain column>
        description: ...
        data_tests:
          - not_null
      # ... every column in the select list gets a description
    data_tests:
      - dbt_utils.unique_combination_of_columns:
          arguments:
            combination_of_columns:
              - <the grain columns>
```

Non-negotiable:

- **Every column in the SQL has a description.** Column descriptions are what make the lineage index
  useful — an agent asked "what depends on this column" answers from them.
- **A `not_null` test on every grain column.**
- **A `unique_combination_of_columns` test on the grain.** This is the test that catches a fan-out
  regression; nothing else will.

Do **not** add `contract: enforced` unless the model's column list has stopped moving and something
depends on it — see [ADR-0006](../adr/0006-enforced-contracts-on-dashboard-facing-models.md). A
contract also requires an explicit `cast(...)` on every column and a `data_type` on every YAML entry.

## 4. Compile, build, test

```bash
dbt compile --select <model>          # no warehouse cost, catches ref and macro errors
dbt build   --select <model>          # builds into your dev schema and runs its tests
dbt build   --select <model>+         # add downstream if anything reads from it
```

Check the schema name in the output. It should be developer-prefixed —
`dbt_jacob_DATA_VIZ`, not `DATA_VIZ`. If it says `DATA_VIZ`, your target name is `prod` and you are
building into production.

## 5. Update the exposure if a dashboard will read it

If the [retail performance dashboard](../../models/marts/_exposures.yml) is going to consume the
model, add it to the exposure's `depends_on`. An exposure that does not list its real inputs makes
impact analysis lie.

## Definition of done

1. `dbt build --select <model>+` passes.
2. Every column has a description and the grain has a uniqueness test.
3. The model landed in a developer-prefixed schema.
4. `dbt parse` has been re-run, so the agent index reflects the new model.

## See also

- [Metric definitions](../reference/metric-definitions.md) — reuse an existing definition before
  inventing one
- [Macro reference](../reference/macros.md)
- [How to run the project](./run-the-project.md)
