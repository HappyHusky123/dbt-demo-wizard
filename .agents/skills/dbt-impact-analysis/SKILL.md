---
name: dbt-impact-analysis
description: "Trace what depends on a dbt model or column before anything changes, and report the full blast radius including exposures and their owners. Use this skill whenever the user asks what depends on something, what breaks if a column is renamed or dropped, who owns a dashboard, which models feed a report, whether a change is safe, what the downstream of a model is, or where a measure is defined. Also trigger when the user mentions \"impact\", \"blast radius\", \"what breaks\", \"downstream\", \"upstream\", \"lineage\", \"what depends on\", \"safe to change\", \"who owns\", or \"can I drop\"."
---

# dbt-impact-analysis

Answers "what happens if I change this" before the change happens. The bounded outcome: a report
naming every affected node, every affected exposure and its owner, and every guardrail the change
would hit.

This skill is **read-only**. It does not edit models. If the answer is "the change is fine", hand off
to `dbt-model-author`.

## Executor

This skill needs a way to inspect the project's compiled metadata. Two implementations, in order of
preference:

- **A native dbt metadata index** — dbt Wizard's index, built from `target/`, answers column-level
  lineage, test coverage, contract status and run health directly. Prefer it when available.
- **`target/manifest.json` plus the repository** — `dbt ls --select <node>+ --output json`,
  `dbt ls --select +<node>`, and reading the YAML files. Slower and column-level lineage has to be
  inferred by reading SQL, but always available.

Either way, **`target/` must be current.** Run `dbt parse` first if there is any doubt; a stale
manifest produces a confidently wrong answer. Grep alone is not an acceptable executor for this skill
— it cannot see exposures, contracts or test coverage, which is most of what makes the answer useful.

## Do the work

### 1. Resolve what was asked about

A model, a column, or a source table. If it is a column, identify the model it is defined in first —
`client-docs/reference/metric-definitions.md` names where each measure is born. A column that appears
in five models is usually defined in one and aggregated in four, and that distinction changes the
answer.

### 2. Walk downstream

Every node that reads it, transitively. For a column specifically, a model counts as affected only if
it actually selects or derives from that column, not merely because it reads the model — say which.

### 3. Find the exposures

**This is the part that matters and the part grep cannot do.** Check `models/marts/_exposures.yml`.
An exposure names a real consumer outside the repository and carries an owner with a name and an
email. Report both.

A change that touches an exposure is a change that needs a conversation, not just a passing build.

### 4. Find the guardrails

Anything that will reject the change on its own:

- **Enforced contracts.** A model with `contract: enforced` rejects an added, dropped or retyped
  column at build time. `rpt_daily_store_sales` carries one. See
  `client-docs/adr/0006-enforced-contracts-on-dashboard-facing-models.md`.
- **Tests** on the column or the model's grain: `not_null`, `unique`, `accepted_values`,
  `relationships`, `dbt_utils.unique_combination_of_columns`.
- **Model `access`.** A `protected` or `public` model has a wider contract with its consumers than a
  private one.
- **Groups.** `models/_groups.yml` names an owner for the model itself.

### 5. Report

```
<thing> — impact

Defined in:   <model> (<layer>)
Downstream:   <node> → <node> → <node>
              <n> models, <n> tests

Exposures:    <name> (<type>), owner <owner name> <email>

Guardrails:   <contract | test | access> on <node> — <what it would do>

Verdict:      <safe | needs a YAML change | breaks an exposure — talk to <owner>>
```

Lead with the exposure if there is one. "Three models and a dashboard that Retail Analytics looks at
every morning" is the answer; the model list alone is trivia.

## Report honestly

**Name what you could not determine.** If the executor gives model-level lineage but not column-level,
say the downstream list is model-level and may overstate the impact. If a consumer exists outside the
repo that no exposure declares, you cannot see it — say so.

An impact analysis that finds most of the blast radius and is clear about its edges is useful. One
that implies completeness it does not have is worse than none, because it will be trusted.

## Common questions and where the answer comes from

| Question | Source |
|---|---|
| What depends on this column? | Downstream walk + column-level lineage |
| What breaks if I drop it? | Contracts first, then exposures, then tests |
| Who owns the dashboard? | `models/marts/_exposures.yml` |
| Which models feed the dashboard? | The exposure's `depends_on` |
| Where is this measure defined? | `client-docs/reference/metric-definitions.md` |
| Which models have no test on their grain? | Model YAML across all three layers |
| Is this model safe to change? | All of the above, then say which of them decided it |

## Reference files

| File | When to read |
|---|---|
| `models/marts/_exposures.yml` | Always — this is the hop that makes the answer worth having |
| `client-docs/reference/metric-definitions.md` | Resolving where a measure is defined |
| `client-docs/adr/0006-enforced-contracts-on-dashboard-facing-models.md` | A contract is in the path |
| `client-docs/explanation/layering-model.md` | Explaining why a layer boundary matters |
| `models/_groups.yml` | Model ownership |
