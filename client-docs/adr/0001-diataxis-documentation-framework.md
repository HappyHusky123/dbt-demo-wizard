# ADR-0001: Use Diátaxis to Organize `client-docs/`

## Status

Accepted

## Date

2026-09-22

## Context

This repo is read by agents as much as by people. An agent asked to add a model needs to find the
naming standard, the macro it is supposed to use, and the environment it is building into — and it
needs to find each of them in one place, quickly, without loading the whole folder into context.

Undifferentiated documentation fails that badly. A single `GUIDE.md` mixing rationale, steps, and
lookup values means an agent either reads all of it or reads none of it, and a person looking for one
value reads three paragraphs of philosophy first.

[Diátaxis](https://diataxis.fr/) splits documentation by what the reader is trying to do, which maps
unusually well onto what an agent is trying to do at a given moment in a task.

## Decision

`client-docs/` is organized into four Diátaxis buckets plus a decision log.

| Bucket | Reader's mindset | Holds |
|---|---|---|
| `tutorials/` | "I'm new, show me" | A guided path that teaches by doing |
| `how-to/` | "I know what I need, how?" | Recipes for a goal the reader already has |
| `reference/` | "I need to look up X" | Environment values, macro signatures, source inventory, metric definitions |
| `explanation/` | "Why is it like this?" | Reasoning, alternatives, tradeoffs |
| `adr/` | "What did we decide?" | One file per decision, Context / Decision / Consequences |

`adr/` is deliberately outside the four buckets. It is closest to explanation, but explanation is
discursive and revisable while an ADR is a dated record that gets superseded rather than edited.

Bucket selection is decided by the reader's state of mind, not by the content's topic. The `diataxis`
skill in `.agents/skills/` resolves the boundary cases, particularly tutorial vs how-to.

## Consequences

### Positive

- An agent can load exactly the bucket it needs. "What is the warehouse called" hits one reference
  file; it does not require reading the layering rationale.
- Gaps become visible. A bucket with nothing in it is a question worth asking.
- Multi-purpose documents, the most common authoring failure, are caught at review because they do not
  fit a bucket.

### Negative

- Requires discipline. Content that could go in two buckets usually means the document is doing two
  jobs and needs splitting, which is more work than writing one long page.
- Cross-linking becomes load-bearing. A how-to that does not link to its reference is harder to use
  than the long page it replaced.
- Four buckets for a project this size can feel like overhead. It is, until the moment an agent has to
  find one fact under time pressure.

## See also

- [How to write documentation](../how-to/write-documentation.md)
- [Diátaxis](https://diataxis.fr/)
