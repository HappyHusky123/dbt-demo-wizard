---
name: adr-author
description: "Write, number and index an Architecture Decision Record in client-docs/adr/. Use this skill whenever the user wants to record a decision, write an ADR, document why something was done a certain way, capture a standard, supersede an existing decision, or says an agent got something wrong and the fix should be written down. Also trigger when the user mentions \"ADR\", \"architecture decision\", \"record this decision\", \"write it down so it does not happen again\", \"document the standard\", or edits any file under `client-docs/adr/`."
---

# adr-author

Turns a decision into a dated, numbered record in `client-docs/adr/`, indexed so it can be found.

An ADR is the durable artifact in this repo. A better prompt is not: it lives in one session and helps
one person once. A document in the repository is read by every agent and every developer that comes
after. When something gets built wrong, **write the ADR first**, then fix whatever doc pointed the
wrong way.

## Pick the operation

| Intent | Operation |
|---|---|
| Record a new decision | [Add](#add) |
| Replace a decision that no longer holds | [Supersede](#supersede) |
| Check the log is coherent | [Audit](#audit) |

---

## Add

### 1. Confirm it is a decision

An ADR records a choice between real options. If there was no alternative, it is not a decision, it is
a fact — and facts belong in `client-docs/reference/`. If it is guidance on how to do something, it is
a how-to.

The test: **can you name the option that was rejected, and why?** If not, do not write an ADR yet.

### 2. Check it is not already recorded

Read `client-docs/adr/README.md`. A decision documented twice diverges, and the divergence is
invisible until someone acts on the stale copy. If an existing ADR covers it, extend that one or
[supersede](#supersede) it.

### 3. Take the next number

Sequential from the highest file in `client-docs/adr/`. Filename is
`NNNN-kebab-case-title.md`, zero-padded to four digits.

### 4. Write it

```markdown
# ADR-NNNN: Title in Title Case

## Status

Accepted

## Date

YYYY-MM-DD

## Context

What situation forced a choice. **Name the alternative that was rejected and why.**
State the constraint that made the obvious option wrong.

## Decision

What we do, stated so someone can follow it without reading the Context.
Tables where the decision is a mapping. Code where it is a pattern.

## Consequences

### Positive

What this buys, concretely.

### Negative

What it costs. Be honest. An ADR with no negative section has not
been thought about. If the decision makes a mistake easy to make,
say which mistake and how it shows up.

## See also

Links to the explanation, how-to and reference docs this touches.
```

Status is `Proposed`, `Accepted`, `Superseded by ADR-NNNN` or `Deprecated`. The date is when the
decision was made, not when the file was edited.

### 5. Update the index

Add a row to the table in `client-docs/adr/README.md`. An ADR nothing links to is an ADR nobody finds,
which defeats the purpose.

### 6. Repoint whatever was wrong

If this ADR exists because something was built or documented incorrectly, fix that doc now and link it
to the ADR. The ADR is the authority; the other document should defer to it rather than restate it.

---

## Supersede

1. Write the new ADR with the next number. Its Context explains what changed since the original.
2. Set the old ADR's Status to `Superseded by ADR-NNNN` with a link. **Do not edit its Context,
   Decision or Consequences** — it is a dated record of what was true then, and rewriting history
   makes the log useless.
3. Update the index table for both.
4. Update anything that linked to the old ADR.

---

## Audit

Read every file in `client-docs/adr/` and report:

- **Index drift** — files missing from `README.md`, or rows pointing at files that do not exist.
- **Numbering** — gaps or duplicates.
- **Missing Consequences.** Specifically a missing or empty `### Negative`. This is the most common
  defect and the most revealing one.
- **Context with no rejected alternative** — recorded a preference, not a decision.
- **Contradictions** between ADRs, and between an ADR and the code it describes.
- **Restatement** — an ADR's rule copied into a how-to or reference doc instead of linked. Report the
  duplicate location.

Report; do not auto-fix. Hand findings back for a decision.

---

## House style

- Prose over bullets for Context. Tables for mappings. Code for patterns.
- No em dashes.
- Date every measurement, and in this project state the `tpcds_end_date_sk` window alongside it, since
  counts are a function of it.
- Link to the model or macro the decision governs by relative path, so the ADR stays checkable.
- Keep it short. The demo-critical ADRs in this repo are one screen of Context and one of Decision.

## Reference files

| File | When to read |
|---|---|
| `client-docs/adr/README.md` | Always — the index and the numbering rule |
| `client-docs/adr/0003-conformed-dim-and-fct-models-in-models-intermediate.md` | The house example. Copy its shape |
| `client-docs/how-to/write-documentation.md` | Where non-decision content belongs instead |
