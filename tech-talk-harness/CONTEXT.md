# CONTEXT: "Harness Engineering with dbt Cloud" (Tech Talk Tuesday)

Handoff brief for a fresh Claude Code session. Read this first.

**Owner:** Jacob Rankin, 7Rivers Inc.
**Event:** Tech Talk Tuesday, 30 minutes (25 content + 5 Q&A), week of 2026-09-22
**Audience:** 7Rivers delivery team (data / analytics engineers and consultants)
**Built:** 2026-09-19 in a Claude Cowork session. This file exists because Cowork sessions do not
transfer to Claude Code; the artifacts and this brief are the handoff.

---

## Files in this folder

| File | What it is |
|---|---|
| `build.js` | pptxgenjs generator. **Source of truth for the deck.** Edit this, not the .pptx. |
| `Harness-Engineering-with-dbt-Cloud.pptx` | Generated output, 11 slides, speaker notes embedded |
| `dbt-Cloud-Harness-talking-points.md` | Same speaker notes as a rehearsal doc with a timing table |
| `CONTEXT.md` | This file |

### Rebuilding the deck

```bash
npm install pptxgenjs          # only dependency
node build.js                  # writes Harness-Engineering-with-dbt-Cloud.pptx
```

Optional QA loop (needs LibreOffice and poppler):

```bash
soffice --headless --convert-to pdf Harness-Engineering-with-dbt-Cloud.pptx
pdftoppm -jpeg -r 130 Harness-Engineering-with-dbt-Cloud.pdf slide
```

Then look at the images. Every layout defect found so far was text overflowing a card.

---

## The thesis

**The harness is the repo. The surface is swappable.**

Context framework, ADRs, skills and conventions live in the dbt repo and travel. Cortex Code in
VS Code and dbt Wizard in Studio IDE are two consumers of that repo. dbt Cloud (Fusion, deferral,
environments, jobs, CI) sits underneath both.

Every slide is evidence for that one sentence. If a change does not serve it, cut the change.

The original agenda was a feature tour of two development approaches. It was restructured into a
single argument because a tour does not survive a 30-minute slot and gives the audience nothing
portable.

---

## Slide map and timings

| # | Slide | Leave by |
|---|---|---|
| 1 | Title / hook | 1:00 |
| 2 | The setup: the platform decision is not an AI decision | 3:00 |
| 3 | The thesis: one harness, two surfaces (diagram) | 6:00 |
| 4 | dbt Wizard 1/2: the native metadata engine | 8:30 |
| 5 | dbt Wizard 2/2: surfaces and governance dials | 10:30 |
| 6 | Studio IDE: making the platform surface a real harness | 14:30 |
| 7 | The honest comparison: what transfers, what does not | 16:30 |
| 8 | Local: VS Code connected to the platform | 18:00 |
| 9 | Demo | 26:00 |
| 10 | The decision: which surface, for which engagement | 28:00 |
| 11 | Close: three things to take with you | 30:00 |

Slide 8 is the designated cut. Drop it to 30 seconds if anything earlier runs long.

---

## Decisions made, and why

- **Billing and pricing detail was cut to one card.** It is an account-admin concern, not a delivery-team
  one, and the model changed 2026-09-01 so detail dates fast.
- **The provider matrix was cut to one line,** with one exception kept: the Wizard **CLI** supports
  **Snowflake Cortex** as a BYOK provider. That lands with a Snowflake-centric room.
- **Local setup detail was cut to a pointer.** The runbook (`set-up-local-dbt-environment.md`) is
  excellent reference material and poor presentation material.
- **The MCP gap was promoted, not buried.** Custom MCP servers are not supported in the dbt platform
  today. Naming it out loud is what makes the rest of the recommendation credible.
- **The project-subdirectory gotcha was promoted to the "aha" of slide 6.** See below.
- **The demo is the centerpiece at 8 minutes,** rehearsed to 6. The money shot is Wizard citing one of
  our ADRs while it builds.

---

## Verified dbt facts used in the deck

All verified 2026-09-19 against docs.getdbt.com. **dbt ships fast: re-verify before presenting.**

**Native metadata engine** ([docs](https://docs.getdbt.com/docs/dbt-ai/wizard-how-it-works?version=2#native-metadata-engine))
- A structured index of the project built from dbt artifacts *before* the first prompt, not
  file-grepping. Docs' own analogy: a map of the whole city vs walking every street.
- Indexes: column-level lineage, test coverage, contract status, run health, data profiles
  (row counts, distributions, null rates), metrics and exposures.
- Enables: impact analysis, health checks, data profiling without materializing, validation planning.
- Source: platform = connected development environment; local = `dbt parse` / `compile` / `build`.
  **A stale manifest means a stale agent.**

**Surfaces** ([overview](https://docs.getdbt.com/docs/platform/wizard-overview))
- Studio IDE (public preview), Wizard home tab (public preview), Wizard CLI (public beta),
  Wizard Desktop (private beta).
- The Wizard **CLI** and **Studio IDE Wizard are different products.** The original agenda conflated
  them. Do not repeat that.

**Governance dials** ([Studio IDE](https://docs.getdbt.com/docs/dbt-ai/developer-agent))
- Agent mode: Explore only / Ask for approval (default) / Edit files automatically.
- Validation depth: Light / Medium (default) / Heavy.
- Diffs shown before persist; destructive commands need approval.
- Explore-only lets a read-only client analyst use the agent safely. That is the client-comfort answer.

**Skills** ([platform skills](https://docs.getdbt.com/docs/dbt-ai/wizard-platform-skills))
- Custom skills live at `.agents/skills/<skill-name>/SKILL.md` relative to **the dbt project root**.
- Agent Skills format: YAML frontmatter with `name` and `description`, then markdown body.
- Auto-discovered at session start. **Edit a skill and you need a new chat before it takes effect.**
- A custom skill with the same name as a built-in one takes precedence.
- No cross-project sharing; copy files manually.
- Built-ins inherited free: `troubleshooting-dbt-job-errors`, `migrating-dbt-core-to-fusion`.

**THE GOTCHA (slide 6, most useful 30 seconds in the talk)**
If the dbt Cloud project subdirectory is set to `dbt/`, Wizard resolves `.agents/` as
`dbt/.agents/skills/`. Skills or ADRs parked at the repo root are **silently invisible**. No error,
just an agent that does not know your standards. This is the real reason a harness "did not load."

**Limits** ([platform MCP](https://docs.getdbt.com/docs/dbt-ai/wizard-platform-mcp))
- Custom MCP servers: **not supported in the platform**; built-in dbt context and docs tooling only.
  CLI supports `wizard mcp add`.
- No plan mode. dbt commands stopped after 5 minutes. Chat history 90 days. Not on single-tenant.
- Requires a Developer seat on Starter / Enterprise / Enterprise+. Legacy Team plans not supported.

**Billing** ([pricing](https://docs.getdbt.com/docs/dbt-ai/pricing-billing/overview))
- Metered per token against account credits. Credits are **per account, not per user**. Spend limits
  available. Enterprise includes monthly credits.

---

## 7Rivers brand tokens

From `7Rivers_2026_PPT.pptx` via the `7rivers-company` skill, which is **not available in Claude Code**.
These values are recorded here so the deck stays on brand.

```js
const C = {
  navy:     "060054",  // headings on light slides
  darkNavy: "040028",  // hero and divider backgrounds
  teal:     "00D6FF",  // accents only, never behind white text (fails WCAG AA)
  tealBg:   "0099CC",  // contrast-safe cyan when white text sits on it
  blue:     "0052D8",
  pink:     "EB1F78",
  orange:   "FF5400",
  gray400:  "8791AF",  // muted / captions
};
// Font: Nunito throughout.
```

Conventions this deck follows:
- Dark slides for title, demo divider and close; light for content (the "sandwich").
- **No em dashes** anywhere in 7Rivers copy. Commas or standard hyphens.
- No decorative accent bars or stripes. Category color is carried by the small dot on each card.
- Format matched to prior TTT decks (dense structured cards, slide counter, principles close),
  referenced from `agentic-workspace-condensed.pptx` in
  SharePoint > DeliveryLT > Tech Talk Tuesdays > 2026_04.

---

## Open items

1. **PowerPoint spacing pass.** Previews were rendered with LibreOffice, which substitutes Nunito.
   Roughly 10% slack was left in every text container, but open the deck in real PowerPoint and check
   for overflow before Tuesday.
2. **Re-verify the dbt facts,** especially the MCP limitation and the preview / beta statuses.
3. **Optional: Windows PATH backup slide.** The BCP laptop story (extension installs Fusion but does
   not add it to PATH; execution policy blocks a PowerShell profile fix; a `.cmd` wrapper in
   `%LOCALAPPDATA%\Microsoft\WindowsApps` solves it). Currently one card on slide 8.
4. **Optional: billing rate-table appendix.**
5. **Demo pre-flight** is in slide 9's speaker notes. Warm the session, confirm skills loaded, confirm
   the project subdirectory, have a recording open in a second tab.

---

## Working agreement for the agent

- Edit `build.js` and regenerate. Never hand-edit the .pptx.
- Keep the thesis on slide 3 intact. It is the spine.
- Do not add content without cutting content. The deck is already at 30 minutes.
- Cite a dbt docs URL for any new factual claim about dbt Wizard.
- Keep 7Rivers voice: consultative, business-first, precise, no em dashes.
