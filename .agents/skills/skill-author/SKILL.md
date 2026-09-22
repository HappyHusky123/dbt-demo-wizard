---
name: skill-author
description: "Create, refine or audit a skill in this project's .agents/skills/ directory, applying this repo's conventions for well-scoped, portable, trigger-accurate skills. Use this skill whenever the user wants to add a skill, improve an existing one, review the skills, asks why a skill is not triggering, or wants to know what makes a good skill here. Also trigger when the user mentions \"add a skill\", \"new skill\", \"SKILL.md\", \"the skill did not fire\", \"audit our skills\", \"make this skill better\", or edits any file under `.agents/skills/`."
---

# skill-author

Operations on the skills in this project. Reach for it any time you are authoring or editing a
`SKILL.md`.

This skill is **thin and orchestration-shaped**. It layers this repo's local opinions on top of
general skill-writing craft: the discipline that keeps a skill well-scoped, trigger-accurate, and
deferring to `client-docs/` rather than duplicating it.

## Where skills live

`.agents/skills/<skill-name>/SKILL.md`, relative to **the dbt project root** — the directory holding
`dbt_project.yml`. One directory per skill, kebab-case name.

Two things about discovery are worth knowing before debugging a skill that "did not load":

- **Skills are read at session start.** Edit a skill and you need a **new session** before the change
  takes effect. This is the most common reason a fix appears not to work.
- **The project root is the dbt project root, not the git root.** If a tool is configured with a
  project subdirectory, `.agents/` resolves relative to that subdirectory. A skill parked at the
  repository root is then silently invisible — no error, just an agent that does not know your
  standards.

## Pick the operation

| Intent | Operation |
|---|---|
| Scaffold a new skill | [Add](#add) |
| Improve an existing skill | [Refine](#refine) |
| Sweep every skill for gaps | [Audit](#audit) |

---

## Add

1. **Create the directory.** `.agents/skills/<skill-name>/SKILL.md`.
2. **Apply the [template](#skillmd-template).**
3. **Declare the seam,** if the skill depends on a runtime capability — SQL execution, shell access,
   a metadata index, an MCP server. Say what operations are needed and name a couple of
   implementations. Do not bake one in. See [Executor sections](#executor-sections).
4. **Write the body.** Imperative, terse, operation-shaped. Reference out to `client-docs/` rather
   than restating it — see [reference-out](#reference-out).
5. **Validate** against the [checklist](#checklist).
6. **Start a new session** to test it. The old session will not see it.

---

## Refine

### Common gaps and their fixes

| Gap | Symptom | Fix |
|---|---|---|
| **Weak description** | Generic phrasing, no trigger keywords, skill does not fire when it should | Rewrite per [pushy descriptions](#pushy-descriptions) |
| **Restated standards** | The skill body contains a rule that also lives in an ADR or a how-to | Replace with a link. Two copies diverge and an agent follows whichever it read first |
| **Baked executor** | Body says "use the X tool to do Y" as if X were the only option | Add an `## Executor` section; rewrite steps as "do Y; with X that is `...`" |
| **No definition of done** | Skill describes activity, not completion | Add a numbered, checkable list |
| **Scope creep** | Skill covers three unrelated intents | Split, or add a "Pick the operation" table and keep each branch short |
| **In-skill reference docs** | Skill ships its own `references/` directory | Move the content to the right `client-docs/` bucket and link to it. Docs are the source of truth |
| **Silent failure** | Skill does not say what to do when a step cannot be completed | Say it. "Report what you could not determine" beats a confident partial answer |

### Steps

1. Read the skill.
2. Go gap by gap through the table. For each: present, absent, or partial.
3. Apply fixes. The goal is quality, not feature expansion — do not add new capability while refining.
4. Re-check against the [checklist](#checklist).

---

## Audit

1. Enumerate `.agents/skills/*/SKILL.md`.
2. Run the [Refine](#refine) diagnostic on each. Compile a report; do not edit inline.
3. Report shape:

```
# Skill audit — .agents/skills/
<N> skills checked.

## <skill-name>
- Description: <ok | weak — why>
- Executor section: <present | missing | n/a>
- Steps operation-shaped: <yes | partial | no>
- Defers to client-docs/: <ok | restates <what>>
- Definition of done: <present | missing>
- Verdict: <good | needs refine | needs rework>

## Summary
- Good: <N>   Needs refine: <N>
- Suggested first refine: <name> — reason
```

4. Hand off to [Refine](#refine). Do not auto-fix from an audit.

---

## Checklist

Every skill in this project satisfies all five.

1. **Pushy description** that names the trigger phrases.
2. **`## Executor` section** when the skill depends on a runtime capability.
3. **Operation-shaped steps** — what to do, with one concrete invocation as an example.
4. **Reference-out to `client-docs/`** for the substance.
5. **A definition of done** that can be checked.

### Pushy descriptions

The frontmatter `description` is the trigger mechanism and the only thing loaded before the skill
fires. Skills under-trigger by default; the description has to actively recruit.

- **Lead with what, then when.** "Do X. Use this skill whenever the user wants to A, B, or C."
- **Name the phrases a real operator would type**, including the sloppy ones. Not "impact analysis" —
  also "what breaks if", "can I drop this", "who owns that dashboard".
- **Name the file paths** that should trigger it: "or edits any file under `models/`".
- **Quote the `description` value.** Leave `name` unquoted.

Describe the *situations*, not the skill.

### Executor sections

When a skill needs a runtime capability, say what operations it needs and name two or more
implementations, in preference order, with what changes between them. The step bodies then read "do Y;
with X that is `<command>`" rather than "run `<command>`".

The point is portability: the skill should still work when the same capability arrives through a
different tool. `dbt-impact-analysis` has a worked example — a native metadata index preferred, with
`target/manifest.json` as the always-available fallback.

Skills that only read and write repository files have no seam and should not invent one.

### Reference-out

The skill body is the **orchestration layer**. `client-docs/` carries the substance.

A skill should say "read `client-docs/adr/000N-...` and apply it", not restate what the ADR says.
This is not just tidiness — in this repo the standards are deliberately written so an agent finds and
cites the authoritative document, and a skill that paraphrases the rule short-circuits that.

End every skill with a Reference files table: which document, and when to read it.

---

## SKILL.md template

```markdown
---
name: skill-name
description: "What it does. Use this skill whenever the user wants to <A>, <B>, or <C>. Also trigger when the user mentions \"<phrase>\", \"<phrase>\", or edits any file under `<path>`."
---

# skill-name

One or two sentences: what this skill does and what the bounded outcome is.

This skill is thin. The substance lives in <paths>; read them rather than
relying on what is summarized here.

## Executor
<!-- Only when the skill needs a runtime capability. Operations needed,
     two or more implementations, what differs. Delete if there is no seam. -->

## Pick the operation
<!-- Only when there is more than one. Table: intent -> operation. -->

## Do the work

### 1. <step>
### 2. <step>

## Definition of done

1. <checkable>
2. <checkable>

## Reference files

| File | When to read |
|---|---|
| `client-docs/...` | ... |
```

## House style

- No em dashes.
- Imperative mood. "Read the ADR", not "you should read the ADR".
- Tables for mappings, prose for judgment calls.
- Say what to do when a step fails, not only when it succeeds.

## Reference files

| File | When to read |
|---|---|
| `client-docs/how-to/write-documentation.md` | Where non-skill content belongs |
| `.agents/skills/dbt-impact-analysis/SKILL.md` | Worked example of an `## Executor` section |
| `.agents/skills/dbt-model-author/SKILL.md` | Worked example of reference-out and operation branching |
