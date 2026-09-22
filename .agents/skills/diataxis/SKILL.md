---
name: diataxis
description: "Decide which Diátaxis bucket a document belongs in, author a new doc in the right one, or review whether an existing doc fits where it sits. Use this skill whenever the user wants to add documentation, asks where a document should go, wonders if something is a tutorial or a how-to, wants to split a document that is doing too much, or asks about Diátaxis distinctions. Also trigger when the user mentions \"tutorial\", \"how-to\", \"reference doc\", \"explanation\", \"which bucket\", \"where does this doc go\", \"Diátaxis\", or edits any file under `client-docs/`."
---

# Diátaxis, as this project applies it

An opinionated reading of the four-bucket Diátaxis framework. Standard Diátaxis is fuzzy at its
boundaries; this skill resolves those boundaries for `client-docs/`.

The rationale for using it at all is
[ADR-0001](../../../client-docs/adr/0001-diataxis-documentation-framework.md). The authoring
conventions — one fact one home, dated observations, index updates — are in
[write-documentation.md](../../../client-docs/how-to/write-documentation.md). This skill covers only
the bucket decision.

## At a glance

| Bucket | Reader's mindset | What they want |
|---|---|---|
| **Tutorial** | "I'm new, show me." | A guided experience that teaches by doing |
| **How-to** | "I know what I need, how?" | A recipe for an already-defined goal |
| **Reference** | "I need to look up X." | A precise, scannable lookup |
| **Explanation** | "Why is it like this?" | The reasoning, the alternatives, the tradeoffs |

## The decisive question

Pick the bucket by asking: **what is the reader's state of mind right now?**

1. Curious, does not yet know the territory → **Tutorial**
2. Has a clear goal, needs the steps → **How-to**
3. Knows what they want, needs a value or a definition → **Reference**
4. Wants to understand *why* something is the way it is → **Explanation**

When two answers compete, this question almost always decides it.

## Tutorial — learning-oriented

A runnable lesson for a reader who knows little about the project. They follow it top to bottom, every
step works, and at the end they have internalized the basics.

**Hallmarks**
- Reader starts with low knowledge of the domain
- One coherent path, not a menu
- *The tutorial chose the goal*, not the reader
- Concrete: real commands, real output, real artifacts
- Promises something will be **learned**, not something will be **done**

**Anti-hallmarks**
- "Pick which steps apply to your situation" → that is a how-to
- "Every flag this command supports" → that is reference
- "Why we built it this way" → that is explanation
- Multiple entry points or branching paths

**Litmus**: a near-beginner should be able to run it top to bottom and learn. If the doc assumes the
reader already knows what they want to accomplish, it is a how-to.

## How-to — task-oriented

A recipe. The reader already has a goal; they need the steps.

**Hallmarks**
- Title is a goal: "Add a mart model", "Run the project"
- Reader brings the goal; the doc supplies the steps
- Assumes domain knowledge — uses the vocabulary, does not define it
- Links to reference and explanation rather than explaining inline
- Multiple how-tos coexist; the reader picks the one matching their goal

**Anti-hallmarks**
- "Let us first understand what X is" → tutorial or explanation
- "Here are all the options" with no chosen goal → reference

**Litmus**: if the reader already knows what they want and the doc just gives them the steps, it is a
how-to.

## Reference — information-oriented

For lookup. Scannable, precise, dense.

**Hallmarks**
- Tables, lists, schemas, signatures, configuration matrices
- Reader scans, jumps, searches — does not read top to bottom
- Titles are nouns: "Macros", "Snowflake environment", "Source inventory"
- No narrative. Facts, types, defaults, constraints
- Each section is independent of the others

**Anti-hallmarks**
- Long prose paragraphs → explanation
- Step sequences → tutorial or how-to
- Rationale or opinion → explanation

**Litmus**: if a reader has to read the whole page to understand any one part of it, it is not
reference.

## Explanation — understanding-oriented

The *why*: design choices, tradeoffs, conceptual maps.

**Hallmarks**
- Discusses, does not instruct
- Frames decisions and alternatives: "we chose X because Y, even though Z"
- Conceptual: *what is X really*, not *how to use X*
- May be opinionated
- Answers "why" questions

**Anti-hallmarks**
- Step-by-step instructions → how-to or tutorial
- Lookup tables → reference

**Litmus**: if removing the prose narrative leaves the reader still able to do what they came to do,
the prose was explanation.

## Boundary cases

**Tutorial vs how-to.** Both are step-shaped. The decisive question: *who chose the goal?* If the doc
chose it (because it is teaching something specific), it is a tutorial. If the reader brought it, it
is a how-to.

**Reference vs explanation.** Both describe the system. The decisive question: *if I delete the prose,
is the document still useful?* Yes → reference. No → explanation.

**How-to vs reference.** A how-to assembles facts toward a goal. Reference catalogs facts with no
goal. If the title has a goal in it, it is a how-to.

**Anything vs ADR.** An ADR records a dated choice between real options and gets superseded rather
than edited. Explanation is revisable prose about how things are. If you can name the rejected option
and the date it was rejected, it is an ADR — see the `adr-author` skill.

## This project's opinions

- **`adr/` is not a Diátaxis bucket** and does not need to fit one. It is the decision log, and it
  outranks the buckets: where an explanation and an ADR disagree, the ADR wins and the explanation is
  stale.
- **The naming standard is not in `reference/` and must not move there.** It lives in
  [ADR-0003](../../../client-docs/adr/0003-conformed-dim-and-fct-models-in-models-intermediate.md)
  alone. A scannable copy of a rule that already has an authoritative home is the "one fact, one home"
  violation this project cares most about.
- Each bucket has a `README.md` index. It is not a Diátaxis doc either — it is the table of contents.
- A bucket with nothing in it is a question worth asking, not an error. Tutorials in particular are
  optional.
- `explanation/project-context.md` is the orientation doc and the entry point. It routes; it does not
  hold facts that belong elsewhere.

## Common mistakes

- **The "guide" trap.** A doc titled "X Guide" is usually all four buckets at once. Split it.
- **The "overview" trap.** An overview is explanation pretending to be reference. Move it to
  `explanation/` or fold it into the bucket README.
- **Reference creep into how-to.** A how-to listing every option for every step is becoming reference.
  Trim to the options the goal needs and link out.
- **Restating an ADR.** Link to it. A decision documented twice diverges.
- **Branching tutorials.** "If X do this, otherwise that" stops being a learning experience. Pick one
  path.
- **Explanation as preface.** "Before we begin, some philosophy" inside a how-to is explanation that
  should move to `explanation/` and be linked.

## When you cannot decide

If two buckets fit equally and the reader-state-of-mind question does not break the tie, the document
is trying to do two jobs. **Split it**: one short doc per bucket, cross-linked. Multi-bucket documents
are the most common authoring failure.
