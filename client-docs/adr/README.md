# Architecture Decision Records

One file per decision, in the format `Context / Decision / Consequences`. An ADR records a choice that
was actually made, the situation that forced it, and what it costs. It is not a style guide and not a
tutorial.

## The index

| # | Decision | Status |
|---|---|---|
| [0001](./0001-diataxis-documentation-framework.md) | Use Diátaxis to organize `client-docs/` | Accepted |
| [0002](./0002-three-schema-layering-and-name-routing.md) | Three fixed schemas, routed by `generate_schema_name` | Accepted |
| [0003](./0003-conformed-dim-and-fct-models-in-models-intermediate.md) | Conformed `dim_` and `fct_` models live in `models/intermediate` | Accepted |
| [0004](./0004-safe-divide-for-all-rate-calculations.md) | Every rate and percentage goes through `safe_divide` | Accepted |
| [0005](./0005-aggregate-before-joining-facts.md) | Aggregate each fact to the target grain before joining | Accepted |
| [0006](./0006-enforced-contracts-on-dashboard-facing-models.md) | Enforce a contract on the primary dashboard feed | Accepted |
| [0007](./0007-date-key-window-on-fact-staging-models.md) | Every fact staging model filters on the date-key window vars | Accepted |

## Writing one

Number sequentially from the highest existing file. Status is `Proposed`, `Accepted`, `Superseded by
ADR-NNNN` or `Deprecated`. Date the decision, not the file's last edit.

Keep the **Context** section honest about what the alternative was. An ADR whose Context does not
name the option that was rejected has not recorded a decision, it has recorded a preference.

The `adr-author` skill in `.agents/skills/` automates the numbering and index update.

## When an agent gets something wrong

Write the ADR first, then update whatever doc in `explanation/` or `reference/` pointed the wrong way.
An ADR is the durable artifact; a better prompt is not.
