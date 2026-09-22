# client-docs

The standards, context and decisions for this dbt project, written to be read by an agent as much as
by a person. dbt Wizard in the terminal, Cortex Code in VS Code and any harness you point at this repo
are all consumers of the same folder.

New here? Two entry points, depending on what you need:

- [Project context](./explanation/project-context.md) — what this repo is, what the data means, and
  how the three layers relate. Start here before writing a model.
- [Architecture decisions](./adr/) — the settled decisions. Where this project and dbt's own defaults
  disagree, the ADR is why.

## Layout

This folder follows [Diátaxis](https://diataxis.fr/), four buckets chosen by what the reader is
trying to do. See [ADR-0001](./adr/0001-diataxis-documentation-framework.md) for the rationale and
[How to write documentation](./how-to/write-documentation.md) for the authoring conventions.

| Folder | Reader's mindset | Holds |
|---|---|---|
| [`tutorials/`](./tutorials/) | "I'm new, show me" | A guided path that teaches by doing |
| [`how-to/`](./how-to/) | "I know what I need, how?" | Recipes for a goal the reader already has |
| [`reference/`](./reference/) | "I need to look up X" | Environment values, macro signatures, source inventory, metric definitions |
| [`explanation/`](./explanation/) | "Why is it like this?" | The reasoning behind the shape of the project |
| [`adr/`](./adr/) | "What did we decide, and why?" | One file per decision: Context / Decision / Consequences |

`adr/` is not a Diátaxis bucket. It is the decision log, and it is the authority: where an
explanation and an ADR disagree, the ADR wins and the explanation is stale.

## One fact, one home

A fact lives in exactly one file and everything else links to it. Before adding anything, grep for it.
Documentation that repeats itself drifts, and a drifted standard is worse than no standard, because an
agent will confidently follow the wrong copy.

This is why there is no naming-convention cheat sheet in `reference/`. The model naming and placement
rule lives in [ADR-0003](./adr/0003-conformed-dim-and-fct-models-in-models-intermediate.md) and
nowhere else. Every skill and how-to links to it rather than restating it.
