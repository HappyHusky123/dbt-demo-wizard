# Skills

Agent skills for this dbt project, in the Agent Skills format: `<skill-name>/SKILL.md` with YAML
frontmatter (`name`, `description`) and a markdown body.

`.agents/skills/` resolves relative to **the dbt project root** — the directory holding
`dbt_project.yml`. Skills here are discovered at session start, ahead of user-level skills and ahead
of any tool's built-ins. **Editing a skill requires a new session before the change takes effect.**

| Skill | Use it for |
|---|---|
| [`dbt-model-author`](./dbt-model-author/SKILL.md) | Adding or changing a model, to this project's standards rather than dbt's defaults |
| [`dbt-impact-analysis`](./dbt-impact-analysis/SKILL.md) | Working out what breaks before changing a model or a column |
| [`adr-author`](./adr-author/SKILL.md) | Recording a decision in `client-docs/adr/` |
| [`diataxis`](./diataxis/SKILL.md) | Deciding which documentation bucket something belongs in |
| [`skill-author`](./skill-author/SKILL.md) | Adding, refining or auditing a skill here |

## The design rule

Every skill here is **thin**. The body orchestrates; `client-docs/` carries the substance. A skill
says "read `client-docs/adr/000N-...` and apply it" rather than paraphrasing the rule.

That is deliberate beyond tidiness. The standards in this repo are written to be found and cited by
whatever agent is pointed at the directory. A skill that restates a rule creates a second copy that
will eventually disagree with the first, and an agent will follow whichever it happened to read.

Conventions for authoring or refining a skill are in the `skill-author` skill, not in this file.
