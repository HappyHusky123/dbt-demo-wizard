# Write documentation

Goal: add to `client-docs/` without creating a second copy of a fact.

## 1. Pick the bucket

Ask what the reader is trying to do, not what the content is about.

| Reader's state of mind | Bucket |
|---|---|
| Curious, does not know the territory | `tutorials/` |
| Has a clear goal, needs the steps | `how-to/` |
| Knows what they want, needs a value or a definition | `reference/` |
| Wants to understand why something is the way it is | `explanation/` |
| Needs to know what was decided and what it cost | `adr/` |

The reader-state-of-mind question settles nearly every case. For the ones it does not — tutorial vs
how-to especially — use the `diataxis` skill in `.agents/skills/`.

**If two buckets fit equally, the document is doing two jobs. Split it.** Multi-bucket documents are
the most common authoring failure here.

## 2. Check whether the fact already has a home

Grep the destination tree before writing anything.

```bash
grep -rn "<the fact>" client-docs/
```

A fact lives in exactly one file and everything else links to it. Documentation that repeats itself
drifts, and an agent will confidently follow whichever copy it found first.

The most common violation is restating an ADR. **Link to it.** A decision documented twice diverges,
and the divergence is invisible until someone acts on the stale copy.

This is why there is no naming-convention cheat sheet in `reference/`: the model placement rule lives
in [ADR-0003](../adr/0003-conformed-dim-and-fct-models-in-models-intermediate.md) and nowhere else.

## 3. Write it

**Tutorials** teach by doing. One path, no branches, the document chose the goal. A tutorial with "if
you want X do this, otherwise do that" has become a how-to.

**How-tos** are recipes. The title is a goal. Assume the vocabulary and link to `reference/` rather
than defining terms inline. Do not open with "first, let us understand what X is" — that is
explanation, and it belongs in `explanation/` with a link.

**Reference** is for scanning, not reading. Tables, lists, signatures, defaults. If a reader has to
read the whole page to understand one part of it, it is not reference. No narrative, no rationale.

**Explanation** discusses. It names the alternative that was rejected and says why. If removing the
prose leaves the reader still able to do what they came to do, the prose was explanation and belongs
here rather than wherever it was.

**ADRs** are dated records in `Context / Decision / Consequences` form. They get superseded, not
edited. An ADR whose Context does not name the rejected option has recorded a preference, not a
decision.

## 4. Date every data observation

Row counts, distributions, null rates, timings and thresholds all change. Every one of them carries the
date it was observed.

> "47 seconds on a MEDIUM warehouse (observed 2026-09-22)"

> "daily average ran between -829.92 and -827.44 (observed 2026-09-22, seven-day window)"

In this project counts are also a function of `tpcds_end_date_sk`
([ADR-0007](../adr/0007-date-key-window-on-fact-staging-models.md)), so **state the window alongside
the date** or the number is not reproducible.

An undated number cannot be validated, so it cannot be refreshed, so it rots in place and eventually
misleads someone.

## 5. Update the index

Every bucket has a `README.md` listing what is in it, and `adr/README.md` carries the ADR index table.
A document nothing links to is a document nobody finds.

If the new content changes the orientation of the project, update
[project context](../explanation/project-context.md) — it is the entry point that routes to everything
else.

## 6. Verify

- Relative links resolve. Documents move; links do not follow.
- Any YAML you touched still parses.
- The fact you added appears exactly once: `grep -rn "<the fact>" client-docs/ | wc -l`.

## Anti-patterns

- **The "guide" trap.** A document titled "X Guide" is usually all four buckets in a trench coat.
- **The "overview" trap.** An overview is explanation pretending to be reference. Fold it into the
  bucket README or move it to `explanation/`.
- **Reference creep into how-to.** A how-to listing every option for every step is becoming reference.
  Trim to the options the goal needs and link out.
- **Restating an ADR.** Link to it.
- **Documenting the transient.** Which branch you are on, what you are about to try, what broke this
  morning. That is a commit message.
