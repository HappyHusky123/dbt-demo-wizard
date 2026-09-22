# ADR-0002: Three Fixed Schemas, Routed by `generate_schema_name`

## Status

Accepted

## Date

2026-09-22

## Context

`DEMO_DB` is provisioned with three schemas — `STAGE`, `CURATED`, `DATA_VIZ` — each granted separately
to `DBT_DEMO_ROLE` by `snowflake/01_setup_demo_environment.sql`. The layers are the point: a consumer
can be granted `CURATED` without being granted `STAGE`.

dbt's built-in schema resolution does not produce those names. Given a target schema of `CURATED` and a
folder-level `+schema: STAGE`, dbt's default concatenates them into `CURATED_STAGE`, a schema nobody
provisioned and nobody granted. Every model would land somewhere the setup script never touched.

Developers also need somewhere to build that is not production. Two obvious options:

1. **A separate development database.** Clean isolation, but doubles the provisioning and means the
   sample-data share grant has to be repeated.
2. **Developer-prefixed schemas inside `DEMO_DB`.** One database, one grant, and a developer's output
   sits next to production where it can be diffed against it.

## Decision

`macros/generate_schema_name.sql` overrides dbt's default resolution:

- When the model declares no custom schema, use the target schema unchanged.
- When `target.name == 'prod'`, use the custom schema **verbatim** — `STAGE`, `CURATED`, `DATA_VIZ`.
- Everywhere else, prefix it with the target schema — `dbt_jacob_STAGE`, `dbt_jacob_CURATED`,
  `dbt_jacob_DATA_VIZ`.

Production is identified by **target name**, not by target schema. The production environment must
have its target name set to `prod`.

`GRANT CREATE SCHEMA ON DATABASE DEMO_DB` is what makes the development half work without anyone
pre-provisioning a developer's schemas.

## Consequences

### Positive

- One database, one sample-data share grant, three production schemas that match what the setup script
  provisioned.
- A developer's build lands in a schema named after them, next to production, and can be diffed
  against it in one query.
- Beat 3 of the demo has something concrete to point at: the schema name on screen is the harness
  doing its job, not the agent being careful.

### Negative

- **Silent failure mode.** If the production environment's target name is left at the default, prod
  writes into the developer-prefixed schemas and nothing errors. The symptom is empty production
  tables, and the cause is one field in an environment config.
- Developer schemas accumulate. Nothing drops `dbt_<name>_STAGE` when someone leaves.
- The override means dbt's documented schema behavior does not describe this project. Anyone debugging
  a schema question has to read the macro first.

## See also

- [Snowflake environment reference](../reference/snowflake-env.md)
- [Macro reference](../reference/macros.md)
- [ADR-0003: model naming and placement](./0003-conformed-dim-and-fct-models-in-models-intermediate.md)
