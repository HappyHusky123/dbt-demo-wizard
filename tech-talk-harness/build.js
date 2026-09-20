const pptxgen = require("pptxgenjs");

const C = {
  navy: "060054",
  darkNavy: "040028",
  teal: "00D6FF",
  tealBg: "0099CC",
  blue: "0052D8",
  pink: "EB1F78",
  orange: "FF5400",
  gray400: "8791AF",
  gray600: "D8D8D8",
  cardBg: "F3F5FB",
  cardBgDark: "12103F",
  white: "FFFFFF",
};
const F = "Nunito";

const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE"; // 13.333 x 7.5
pres.author = "Jacob Rankin";
pres.company = "7Rivers Inc.";
pres.title = "Harness Engineering with dbt Cloud";

const W = 13.333, H = 7.5, M = 0.55;
const TOTAL = 11;

// ---------- helpers ----------

function chrome(slide, n, dark) {
  slide.addText("7RIVERS  //  TECH TALK TUESDAY", {
    x: M, y: H - 0.48, w: 4.5, h: 0.28, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 9, bold: true, charSpacing: 1.2,
    color: dark ? C.gray400 : C.gray400, align: "left", valign: "middle",
  });
  slide.addText(`${n} / ${TOTAL}`, {
    x: W - M - 1.2, y: H - 0.48, w: 1.2, h: 0.28, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 9, bold: true, color: dark ? C.teal : C.gray400,
    align: "right", valign: "middle",
  });
}

function head(slide, eyebrow, title, sub) {
  slide.addText(eyebrow, {
    x: M, y: 0.36, w: 11, h: 0.25, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 10.5, bold: true, charSpacing: 1.6, color: C.blue, valign: "middle",
  });
  slide.addText(title, {
    x: M, y: 0.63, w: 12.2, h: 0.62, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 32, bold: true, color: C.navy, valign: "middle",
  });
  if (sub) {
    slide.addText(sub, {
      x: M, y: 1.25, w: 12.2, h: 0.32, isTextBox: true, margin: 0,
      fontFace: F, fontSize: 13, italic: true, color: C.gray400, valign: "middle",
    });
  }
}

// A tinted card with a colored dot, a heading, and body lines.
function card(slide, o) {
  slide.addShape(pres.ShapeType.roundRect, {
    x: o.x, y: o.y, w: o.w, h: o.h, rectRadius: 0.06,
    fill: { color: o.bg || C.cardBg }, line: { color: o.bg || C.cardBg, width: 0 },
  });
  let ty = o.y + 0.2;
  if (o.dot) {
    slide.addShape(pres.ShapeType.ellipse, {
      x: o.x + 0.24, y: ty + 0.045, w: 0.16, h: 0.16,
      fill: { color: o.dot }, line: { color: o.dot, width: 0 },
    });
  }
  slide.addText(o.title, {
    x: o.x + (o.dot ? 0.5 : 0.24), y: ty, w: o.w - (o.dot ? 0.74 : 0.48), h: 0.28,
    isTextBox: true, margin: 0, fontFace: F, fontSize: o.titleSize || 13.5, bold: true,
    color: o.titleColor || C.navy, valign: "top",
  });
  ty += (o.titleH || 0.28) + 0.08;
  if (o.lead) {
    slide.addText(o.lead, {
      x: o.x + 0.24, y: ty, w: o.w - 0.48, h: o.leadH || 0.5, isTextBox: true, margin: 0,
      fontFace: F, fontSize: 11, color: o.leadColor || C.blue, bold: true, valign: "top",
      lineSpacingMultiple: 1.08,
    });
    ty += (o.leadH || 0.5) + 0.04;
  }
  if (o.lines && o.lines.length) {
    slide.addText(
      o.lines.map((t, i) => ({
        text: t, options: { bullet: { indent: 12 }, breakLine: i !== o.lines.length - 1 },
      })),
      {
        x: o.x + 0.26, y: ty, w: o.w - 0.5, h: o.y + o.h - ty - 0.16, isTextBox: true, margin: 0,
        fontFace: F, fontSize: o.size || 10.5, color: o.color || C.navy,
        valign: "top", paraSpaceAfter: o.gap === undefined ? 4 : o.gap, lineSpacingMultiple: 1.02,
      }
    );
  }
  if (o.body) {
    slide.addText(o.body, {
      x: o.x + 0.24, y: ty, w: o.w - 0.48, h: o.y + o.h - ty - 0.16, isTextBox: true, margin: 0,
      fontFace: F, fontSize: o.size || 10.5, color: o.color || C.navy, valign: "top",
      lineSpacingMultiple: 1.1,
    });
  }
}

function statChip(slide, o) {
  slide.addShape(pres.ShapeType.roundRect, {
    x: o.x, y: o.y, w: o.w, h: o.h, rectRadius: 0.06,
    fill: { color: o.bg }, line: { color: o.bg, width: 0 },
  });
  slide.addText(o.big, {
    x: o.x + 0.16, y: o.y + 0.12, w: o.w - 0.32, h: 0.42, isTextBox: true, margin: 0,
    fontFace: F, fontSize: o.bigSize || 20, bold: true, color: o.fg || C.white,
    align: "center", valign: "middle",
  });
  slide.addText(o.small, {
    x: o.x + 0.14, y: o.y + 0.54, w: o.w - 0.28, h: o.h - 0.66, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 9.5, color: o.smallFg || C.white, align: "center", valign: "top",
    lineSpacingMultiple: 1.05,
  });
}

function darkSlide() {
  const s = pres.addSlide();
  s.background = { color: C.darkNavy };
  return s;
}

// ============================================================
// 1. TITLE
// ============================================================
{
  const s = darkSlide();

  // cyan wave motif: three offset rounded marks, no full-width stripe
  [0, 1, 2].forEach((i) => {
    s.addShape(pres.ShapeType.roundRect, {
      x: M + i * 0.42, y: 1.62, w: 0.3, h: 0.1, rectRadius: 0.05,
      fill: { color: [C.teal, C.blue, C.pink][i] },
      line: { color: [C.teal, C.blue, C.pink][i], width: 0 },
    });
  });

  s.addText("TECH TALK TUESDAY  //  SEPTEMBER 2026", {
    x: M, y: 1.05, w: 9, h: 0.3, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 12, bold: true, charSpacing: 2, color: C.teal, valign: "middle",
  });

  s.addText("Harness Engineering\nwith dbt Cloud", {
    x: M, y: 2.0, w: 9.6, h: 1.85, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 52, bold: true, color: C.white, valign: "top", lineSpacingMultiple: 0.95,
  });

  s.addText("One harness, two surfaces. The context framework, ADRs and skills live in the repo, so the agent surface becomes a choice, not a constraint.", {
    x: M, y: 3.95, w: 8.6, h: 0.8, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 15, color: C.gray400, valign: "top", lineSpacingMultiple: 1.12,
  });

  s.addText("Jacob Rankin  •  7Rivers Inc.  •  Delivery Team", {
    x: M, y: 5.0, w: 8, h: 0.35, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 13, bold: true, color: C.white, valign: "middle",
  });

  // right rail: the two surfaces
  statChip(s, { x: 10.15, y: 2.0, w: 2.6, h: 1.25, bg: "1A1760", big: "VS Code", small: "Cortex Code as the harness,\nlocal, Fusion, deferral", bigSize: 18 });
  statChip(s, { x: 10.15, y: 3.4, w: 2.6, h: 1.25, bg: "1A1760", big: "Studio IDE", small: "dbt Wizard in platform,\nbrowser, zero setup", bigSize: 18 });

  chrome(s, 1, true);
  s.addNotes(
`OPEN (60 seconds). Do not start with dbt Wizard. Start with the problem.

"Most of us have built an AI harness on a local setup. Context framework, ADRs, skills, Cortex Code. It works, and it is a real differentiator on engagements. Then a client tells you they are standardizing on dbt Cloud, and the quiet assumption in the room is that the harness was a local thing and now we lose it."

"That assumption is wrong, and this talk is about why."

Set the frame immediately: the harness is the repo, not the tool. The surface is swappable. Everything else today is evidence for that one sentence.

Name the two surfaces on the right so people know where we are going. Note that BrightStar Capital Partners is the live engagement behind this, so this is not theory.

TIMING: be off this slide by 1:00.`);
}

// ============================================================
// 2. WHY THIS MATTERS
// ============================================================
{
  const s = pres.addSlide();
  head(s, "THE SETUP", "The platform decision is not an AI decision",
    "And that is exactly why the harness question gets skipped until it is expensive to answer.");

  const y = 1.85, h = 2.42, w = 3.92;
  card(s, {
    x: M, y, w, h, dot: C.blue, title: "Why they pick the platform",
    lines: [
      "Governed orchestration, scheduling and CI in one place",
      "Fusion engine, deferral and state-aware runs",
      "Environments, RBAC and audit the client can point at",
      "A browser surface that analysts can actually use",
    ],
  });
  card(s, {
    x: M + w + 0.3, y, w, h, dot: C.orange, title: "The assumption to kill",
    lines: [
      "\"dbt Cloud is a managed IDE, so we give up our tooling\"",
      "\"The harness only works where we control the machine\"",
      "\"Analysts on the client side cannot use any of this\"",
      "Result: the harness quietly gets dropped at kickoff",
    ],
  });
  card(s, {
    x: M + 2 * (w + 0.3), y, w, h, dot: C.teal, title: "What is actually true now",
    lines: [
      "dbt Wizard ships an agent inside the platform",
      "Custom skills load straight from the repo",
      "Our context framework and ADRs travel with the project",
      "The gaps are real, knowable, and worth naming out loud",
    ],
  });

  card(s, {
    x: M, y: 4.52, w: W - 2 * M, h: 1.12, bg: "EFF2FA", dot: C.pink,
    title: "The consulting angle",
    body: "A harness the client can run without us is worth more than one only we can run. Studio IDE is the first surface where the client's own analysts inherit our standards, our ADRs and our guardrails without installing anything.",
    size: 12,
  });

  chrome(s, 2);
  s.addNotes(
`WHY THIS MATTERS (2 minutes).

Left card: do not oversell. These are good reasons. Governance, scheduling, CI, and an environment story the client's audit team can point at. We should not be talking clients out of dbt Cloud.

Middle card: this is the moment to be honest that we have all thought at least one of these. Say it plainly, it earns credibility for the rest of the talk.

Right card: three facts that flip it. Wizard is in the platform, custom skills load from the repo, our framework travels. Do not explain them yet, just plant them.

Bottom card is the one that matters to a partner or a client sponsor. Read it close to verbatim. A harness the client can run without us is a retention story, not a threat. If someone pushes on "does this commoditize us," the answer is that the value was never the tool, it was the ADRs and the standards we put in the repo.

TIMING: leave at 3:00.`);
}

// ============================================================
// 3. THESIS DIAGRAM
// ============================================================
{
  const s = pres.addSlide();
  head(s, "THE THESIS", "One harness, two surfaces");

  const surfY = 1.5, surfH = 1.35, surfW = 5.0;
  // Surface A
  card(s, {
    x: 1.05, y: surfY, w: surfW, h: surfH, bg: "EAF0FD", dot: C.blue,
    title: "Local: VS Code + Cortex Code",
    lines: [
      "Snowflake Cortex Code as harness and inference",
      "Full MCP, shell, multi-repo context",
    ], size: 10.5,
  });
  // Surface B
  card(s, {
    x: 7.28, y: surfY, w: surfW, h: surfH, bg: "E6FAFF", dot: C.tealBg,
    title: "Platform: Studio IDE + dbt Wizard",
    lines: [
      "Wizard agent with native metadata engine",
      "Browser only, no local install, client-usable",
    ], size: 10.5,
  });

  // arrows down into the repo
  [3.55, 9.78].forEach((x) => {
    s.addShape(pres.ShapeType.line, {
      x, y: surfY + surfH, w: 0, h: 0.42,
      line: { color: C.gray400, width: 1.5, endArrowType: "triangle" },
    });
  });

  // The repo, center of gravity
  const rY = 3.32, rH = 1.72;
  s.addShape(pres.ShapeType.roundRect, {
    x: 1.05, y: rY, w: 11.23, h: rH, rectRadius: 0.05,
    fill: { color: C.navy }, line: { color: C.navy, width: 0 },
  });
  s.addText("THE HARNESS LIVES HERE: YOUR dbt REPO", {
    x: 1.3, y: rY + 0.16, w: 10.7, h: 0.3, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 11.5, bold: true, charSpacing: 1.6, color: C.teal, valign: "middle",
  });
  const items = [
    ["Context framework", "river-guidebook structure the agent reads first"],
    ["ADRs", "decisions the agent has to honor, not rediscover"],
    [".agents/skills/", "our workflows, loaded by both surfaces"],
    ["Conventions + tests", "naming, contracts, the definition of done"],
  ];
  items.forEach((it, i) => {
    const x = 1.3 + i * 2.72;
    s.addText(it[0], {
      x, y: rY + 0.58, w: 2.55, h: 0.3, isTextBox: true, margin: 0,
      fontFace: F, fontSize: 13, bold: true, color: C.white, valign: "middle",
    });
    s.addText(it[1], {
      x, y: rY + 0.88, w: 2.55, h: 0.62, isTextBox: true, margin: 0,
      fontFace: F, fontSize: 10, color: C.gray400, valign: "top", lineSpacingMultiple: 1.05,
    });
  });

  // platform base
  card(s, {
    x: 1.05, y: rY + rH + 0.22, w: 11.23, h: 0.82, bg: "EFF2FA", dot: C.pink,
    title: "dbt Cloud underneath both: Fusion engine, deferral, environments, jobs, CI",
    titleSize: 12.5,
  });

  chrome(s, 3);
  s.addNotes(
`THE THESIS (3 minutes). This is the slide people should photograph.

Walk it from the middle out, not top down. Point at the navy block first.

"Everything that makes our agent good at this work is in the repo. The context framework from river-guidebook. The ADRs. The skills. The conventions and contracts. None of that is tied to an editor."

Then the two surfaces. "These are consumers of that repo. Cortex Code reads it locally. dbt Wizard reads it in the browser. Same source of truth."

Then the base. "And underneath both, dbt Cloud is still doing the thing the client bought it for: Fusion, deferral, environments, jobs, CI."

The line to land: "If you change the surface, you do not rebuild the harness. You point a different agent at the same repo."

Callback for the room: this is the same principle Chris showed in the agentic workspace talk, thin skills over rich docs. We are testing whether it survives a platform move. It does.

TIMING: leave at 6:00.`);
}

// ============================================================
// 4. METADATA ENGINE
// ============================================================
{
  const s = pres.addSlide();
  head(s, "dbt WIZARD  //  1 OF 2", "Why it is not just another coding agent",
    "The native metadata engine is the actual differentiator. Everything else follows from it.");

  // analogy panel
  s.addShape(pres.ShapeType.roundRect, {
    x: M, y: 1.82, w: 4.35, h: 2.72, rectRadius: 0.06,
    fill: { color: C.navy }, line: { color: C.navy, width: 0 },
  });
  s.addText("THE ANALOGY", {
    x: M + 0.24, y: 1.98, w: 3.9, h: 0.26, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 10, bold: true, charSpacing: 1.6, color: C.teal, valign: "middle",
  });
  s.addText("“A map of the whole city.”", {
    x: M + 0.24, y: 2.3, w: 3.9, h: 0.7, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 19, bold: true, italic: true, color: C.white, valign: "top",
    lineSpacingMultiple: 1.0,
  });
  s.addText("Wizard indexes the project before your first prompt, so it knows how everything connects. A generic agent greps files, which is walking every street to work out the layout.", {
    x: M + 0.24, y: 3.02, w: 3.9, h: 1.1, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 11, color: C.gray400, valign: "top", lineSpacingMultiple: 1.1,
  });

  card(s, {
    x: M + 4.65, y: 1.82, w: 3.85, h: 2.72, dot: C.blue, title: "What the index holds",
    lines: [
      "Column-level lineage, not just model-to-model refs",
      "Test coverage: which models have tests, which do not",
      "Contract status, including failing contracts",
      "Run health: recent failures and stale data",
      "Data profiles: row counts, distributions, null rates",
      "Metrics and exposures, so it knows semantic context",
    ], size: 10.5, gap: 5,
  });

  card(s, {
    x: M + 8.8, y: 1.82, w: 3.68, h: 2.72, bg: "EFF2FA", dot: C.orange,
    title: "Where the index comes from", titleH: 0.5,
    body: "Built from dbt artifacts. In the platform, from your connected development environment. Locally, from dbt parse, compile or build.\n\nPractical consequence: a stale manifest means a stale agent. Recompile before you trust it.",
    size: 11,
  });

  const cw = 2.97, cy = 4.78;
  [
    ["Impact analysis", "“What breaks if I change this column?” answered from the index, instantly and precisely", C.blue],
    ["Health checks", "Which models lack tests or have failing contracts, without running anything", C.tealBg],
    ["Data profiling", "Profiles data without materializing models or firing expensive queries", C.pink],
    ["Validation planning", "Picks the relevant checks for the resources you actually touched", C.orange],
  ].forEach((it, i) => {
    card(s, {
      x: M + i * (cw + 0.19), y: cy, w: cw, h: 1.45, dot: it[2],
      title: it[0], titleSize: 12, body: it[1], size: 10,
    });
  });

  chrome(s, 4);
  s.addNotes(
`dbt WIZARD, PART 1 (2.5 minutes). This is the slide that earns the audience's respect, because it is the part most people have not read.

Lead with the analogy, it does the work. "Wizard builds a structured index of the project before your first prompt. A generic coding agent greps files. The docs put it well: Wizard has a map of the whole city, a grep agent walks every street to figure out the layout."

Middle card, do not read all six. Pick two that land with this room: column-level lineage and contract status. Say "this is metadata we already generate, it is just indexed and handed to the agent up front."

Right card is the practical one and it is the most common failure mode. Stale manifest, stale agent. Locally you recompile. In the platform it comes from your connected dev environment.

Bottom row, the payoff. If you only say one: impact analysis. "What breaks if I change this column" is the question every analytics engineer asks ten times a day, and it is answered from an index rather than guessed.

Honest caveat if asked: this does not make it smarter than Cortex Code at writing SQL. It makes it better grounded in this specific project.

TIMING: leave at 8:30.`);
}

// ============================================================
// 5. WHERE IT RUNS / GOVERNANCE
// ============================================================
{
  const s = pres.addSlide();
  head(s, "dbt WIZARD  //  2 OF 2", "Where it runs, and how you keep it on a leash");

  // surfaces
  card(s, {
    x: M, y: 1.68, w: 6.0, h: 2.62, dot: C.blue, title: "Four surfaces, four maturity levels",
    lines: [
      "Studio IDE, public preview: the one we care about today",
      "Wizard home tab, public preview: chat-first development",
      "Wizard CLI, public beta: local terminal agent, full MCP",
      "Wizard Desktop, private beta: native app, visual diffs",
    ], size: 11, gap: 6,
  });
  s.addText("Worth knowing: the Wizard CLI is a separate product from Studio IDE Wizard. Do not conflate them. The CLI also supports Snowflake Cortex as a BYOK provider.", {
    x: M + 0.26, y: 3.42, w: 5.5, h: 0.55, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 10, italic: true, color: C.blue, valign: "top", lineSpacingMultiple: 1.08,
  });

  card(s, {
    x: M + 6.3, y: 1.68, w: 6.18, h: 2.62, bg: "EFF2FA", dot: C.orange,
    title: "Two dials that are really governance controls",
    lines: [
      "Agent mode: Explore only  /  Ask for approval (default)  /  Edit files automatically",
      "Validation depth: Light  /  Medium (default)  /  Heavy",
      "Light is lint and tests. Medium materializes in dev and checks downstream. Heavy adds dev-to-prod comparison.",
      "Diffs are shown before anything persists. Destructive commands need approval.",
    ], size: 10.5, gap: 5,
  });

  // bottom facts row
  const bw = 3.03, by = 4.62;
  [
    ["Access", "Developer seat. Starter, Enterprise or Enterprise+. Legacy Team plans are not supported.", C.blue],
    ["Providers", "OpenAI (default), Anthropic and open-weight models managed by dbt. Azure is BYOK only.", C.tealBg],
    ["Billing", "Metered per token against account credits. Credits are per account, not per user. Spend limits available.", C.pink],
    ["Retention", "Chat history kept 90 days. Not supported on single-tenant deployments.", C.orange],
  ].forEach((it, i) => {
    card(s, {
      x: M + i * (bw + 0.18), y: by, w: bw, h: 1.62, dot: it[2],
      title: it[0], titleSize: 12, body: it[1], size: 10,
    });
  });

  chrome(s, 5);
  s.addNotes(
`dbt WIZARD, PART 2 (2 minutes). Move fast here. This is orientation, not a deep dive.

Left card: name the four surfaces once so nobody is confused later, then flag the correction. A lot of people, including my first draft of this agenda, say "Studio IDE with the Wizard CLI." Those are two different things. The CLI is a local terminal agent. Studio IDE Wizard is in the browser.

Throwaway that this room will like: the CLI supports Snowflake Cortex as a BYOK provider. So on a Snowflake engagement you can keep inference inside the account.

Right card is the one to slow down on for thirty seconds, because it is the client conversation. Agent mode and validation depth are not developer preferences, they are governance controls. Explore only means a read-only analyst can use the agent and cannot touch a model. That is how you get a client comfortable.

Bottom row: do not read it. Say "these four are the questions your engagement lead will ask, the slide is here so you can screenshot it." Flag that billing changed on September 1st and is per account, not per user, which matters for how we scope a pilot.

TIMING: leave at 10:30.`);
}

// ============================================================
// 6. MAKING STUDIO IDE A REAL HARNESS
// ============================================================
{
  const s = pres.addSlide();
  head(s, "STUDIO IDE", "Making the platform surface a real harness",
    "Four moves. The fourth one is where people lose an afternoon.");

  const w1 = 6.0, w2 = 6.18, y1 = 1.85, hh = 1.63;
  card(s, {
    x: M, y: y1, w: w1, h: hh, dot: C.blue, title: "1.  Put your skills where Wizard looks",
    lead: ".agents/skills/<skill-name>/SKILL.md",
    lines: [
      "Discovered automatically at the start of each session",
      "Agent Skills format: YAML frontmatter, name plus description",
      "A custom skill outranks a built-in one with the same name",
    ], size: 10.5, gap: 4, leadH: 0.26,
  });
  card(s, {
    x: M + w1 + 0.3, y: y1, w: w2, h: hh, dot: C.tealBg, title: "2.  Bring the guidebook framework in",
    lines: [
      "Context framework and ADRs go in the repo, referenced from skills",
      "Keep skills thin, let them point at the docs as source of truth",
      "Memories hold project-specific context across sessions",
      "Built-ins you inherit free: job-error troubleshooting, Core to Fusion migration",
    ], size: 10.5, gap: 4,
  });
  card(s, {
    x: M, y: y1 + hh + 0.24, w: w1, h: hh, dot: C.pink, title: "3.  Know what you cannot bring",
    lines: [
      "Custom MCP servers are not supported in the platform today",
      "You get built-in dbt context and docs tooling instead",
      "No plan mode, and dbt commands are stopped after 5 minutes",
    ], size: 10.5, gap: 4,
  });

  // The gotcha, given weight
  s.addShape(pres.ShapeType.roundRect, {
    x: M + w1 + 0.3, y: y1 + hh + 0.24, w: w2, h: hh, rectRadius: 0.06,
    fill: { color: C.navy }, line: { color: C.navy, width: 0 },
  });
  s.addShape(pres.ShapeType.ellipse, {
    x: M + w1 + 0.54, y: y1 + hh + 0.49, w: 0.16, h: 0.16,
    fill: { color: C.orange }, line: { color: C.orange, width: 0 },
  });
  s.addText("4.  The gotcha: project subdirectory", {
    x: M + w1 + 0.8, y: y1 + hh + 0.44, w: w2 - 1.0, h: 0.28, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 13.5, bold: true, color: C.white, valign: "middle",
  });
  s.addText("If dbt Cloud points at a subdirectory, that is your project root.", {
    x: M + w1 + 0.54, y: y1 + hh + 0.76, w: w2 - 0.54, h: 0.26, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 11, bold: true, color: C.teal, valign: "middle",
  });
  s.addText("Set it to dbt/ and Wizard reads dbt/.agents/skills/. Skills or ADRs parked at the repo root are invisible. This is the real reason a harness “did not load,” and it costs an afternoon to find.", {
    x: M + w1 + 0.54, y: y1 + hh + 1.02, w: w2 - 0.78, h: 0.62, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 10.5, color: C.gray400, valign: "top", lineSpacingMultiple: 1.08,
  });

  card(s, {
    x: M, y: y1 + 2 * (hh + 0.24), w: W - 2 * M, h: 0.72, bg: "EFF2FA", dot: C.orange,
    title: "One more: skills are read at session start, so edit a skill and you need a new chat before it takes effect.",
    titleSize: 11.5,
  });

  chrome(s, 6);
  s.addNotes(
`STUDIO IDE SETUP (4 minutes). This is the how-to section. Be concrete, this is what they will copy.

1. Say the path out loud twice: dot agents, slash skills, slash skill name, slash SKILL dot md. Same Agent Skills format we already use, so our existing skills mostly move as-is. Note the precedence rule, a custom skill with the same name beats the dbt built-in, which is how you override their opinion with ours.

2. Connect to river-guidebook explicitly. The framework does not change, only where it sits. Reinforce thin skills over rich docs. Mention memories, they are underused.

3. Be honest about the gaps before anyone finds them in the demo. No custom MCP in the platform today, that is CLI only. No plan mode. Five minute command timeout. Say "if you need custom MCP, that is a reason to choose local, and that is a legitimate answer."

4. SLOW DOWN. This is the most useful thirty seconds in the talk. On BrightStar the dbt project sits in a subdirectory. Studio IDE resolves dot agents relative to the project root you configured, not the repo root. Put your skills at the repo root and the agent silently sees nothing. No error, just an agent that does not know your standards.

Bottom bar: edit a skill, start a new chat. People will hit this in the first hour.

TIMING: leave at 14:30.`);
}

// ============================================================
// 7. WHAT TRANSFERS
// ============================================================
{
  const s = pres.addSlide();
  head(s, "THE HONEST COMPARISON", "What transfers, and what does not");

  const y = 1.7, h = 3.42, w = 6.09;

  // left: travels
  s.addShape(pres.ShapeType.roundRect, {
    x: M, y, w, h, rectRadius: 0.06, fill: { color: "EAF7EF" }, line: { color: "EAF7EF", width: 0 },
  });
  s.addText("TRAVELS TO BOTH SURFACES", {
    x: M + 0.28, y: y + 0.22, w: w - 0.56, h: 0.28, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 11.5, bold: true, charSpacing: 1.4, color: "1B7A47", valign: "middle",
  });
  s.addText([
    ["Skills", "Agent Skills format, loaded from .agents/skills/"],
    ["Context framework", "The guidebook structure, read from the repo"],
    ["ADRs", "Decisions the agent honors instead of relitigating"],
    ["Conventions and contracts", "Naming, tests, the definition of done"],
    ["Project metadata", "Lineage, tests, run health, profiles, via the index"],
    ["Approval discipline", "Diff review before anything persists"],
  ].flatMap((r, i, arr) => ([
    { text: r[0] + "  ", options: { bold: true, color: C.navy, fontSize: 11.5 } },
    { text: r[1], options: { color: "4A5570", fontSize: 10.5, breakLine: i !== arr.length - 1 } },
  ])), {
    x: M + 0.3, y: y + 0.62, w: w - 0.6, h: h - 0.9, isTextBox: true, margin: 0,
    fontFace: F, valign: "top", paraSpaceAfter: 9, lineSpacingMultiple: 1.05,
  });

  // right: stays local
  s.addShape(pres.ShapeType.roundRect, {
    x: M + w + 0.3, y, w: w + 0.09, h, rectRadius: 0.06,
    fill: { color: "FDEFEA" }, line: { color: "FDEFEA", width: 0 },
  });
  s.addText("STAYS LOCAL, FOR NOW", {
    x: M + w + 0.58, y: y + 0.22, w: w - 0.5, h: 0.28, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 11.5, bold: true, charSpacing: 1.4, color: "B03A10", valign: "middle",
  });
  s.addText([
    ["Custom MCP servers", "Platform gives built-in dbt tooling only, CLI adds your own"],
    ["Shell access", "Bash is a CLI and Desktop tool, not a platform one"],
    ["Multi-repo context", "The agent sees the dbt project, not your whole workspace"],
    ["Plan mode", "No separate plan step before edits are applied"],
    ["Long-running commands", "Platform stops a dbt command after 5 minutes"],
    ["Your choice of editor", "Extensions, keybindings, the terminal you actually like"],
  ].flatMap((r, i, arr) => ([
    { text: r[0] + "  ", options: { bold: true, color: C.navy, fontSize: 11.5 } },
    { text: r[1], options: { color: "4A5570", fontSize: 10.5, breakLine: i !== arr.length - 1 } },
  ])), {
    x: M + w + 0.6, y: y + 0.62, w: w - 0.52, h: h - 0.9, isTextBox: true, margin: 0,
    fontFace: F, valign: "top", paraSpaceAfter: 9, lineSpacingMultiple: 1.05,
  });

  s.addText("The left column is the harness. The right column is tooling preference. Only one of them is a reason to walk away from the platform surface.", {
    x: 1.35, y: 5.38, w: W - 2.7, h: 0.75, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 14, bold: true, italic: true, color: C.navy, valign: "middle", align: "center",
    lineSpacingMultiple: 1.1,
  });

  chrome(s, 7);
  s.addNotes(
`WHAT TRANSFERS (2 minutes). Do not read either column. Let people scan, then make the point.

Give them ten seconds of silence to read. Then say the bottom line, which is the whole slide:

"The left column is the harness. The right column is tooling preference. Only one of those is a reason to walk away from the platform surface."

If you want one example from each side: skills travel, because it is the same open Agent Skills format. Custom MCP does not, because the platform only ships built-in dbt tooling today.

Expect pushback on MCP. This is the strongest objection and you should welcome it. Answer: "correct, and if your engagement depends on custom MCP, use the local surface. Notice that is a surface decision, not a harness decision. The repo did not change."

Also expect a question on the 5 minute timeout. It is real and it bites on large builds. It is an argument for running heavy builds as jobs, which is what dbt Cloud is for anyway.

TIMING: leave at 16:30.`);
}

// ============================================================
// 8. LOCAL
// ============================================================
{
  const s = pres.addSlide();
  head(s, "LOCAL DEVELOPMENT", "VS Code, connected to the platform",
    "This is what we run on BrightStar. The full runbook is written up, so this slide is a pointer, not a tutorial.");

  card(s, {
    x: M, y: 1.95, w: 6.0, h: 2.32, dot: C.blue,
    title: "Two credentials, one common problem",
    lead: "dbt_cloud.yml  authenticates you to dbt Cloud",
    lines: [
      "Lives in ~/.dbt/, holds a Personal Access Token, never committed",
      "Downloaded from Account settings, Your profile, VS Code Extension",
      "This is what unlocks Fusion and deferral against the platform",
    ], size: 10.5, gap: 4, leadH: 0.26,
  });
  card(s, {
    x: M + 6.3, y: 1.95, w: 6.18, h: 2.32, bg: "EFF2FA", dot: C.orange,
    title: "The second is your warehouse",
    lead: "profiles.yml  authenticates you to Snowflake",
    lines: [
      "authenticator: externalbrowser, so you develop as yourself over SSO",
      "No password and no key pair stored on the laptop",
      "Personal sandbox schema so builds do not collide",
      "Neither file substitutes for the other, this is the common setup failure",
    ], size: 10.5, gap: 4, leadH: 0.26,
  });

  card(s, {
    x: M, y: 4.55, w: 3.92, h: 1.62, bg: "EAF0FD", dot: C.tealBg,
    title: "What you get locally", titleSize: 12,
    body: "dbt extension plus the Fusion engine, LSP autocomplete, deferral against the dbt Cloud environment, and Cortex Code as the harness.", size: 10,
  });
  card(s, {
    x: M + 4.22, y: 4.55, w: 3.92, h: 1.62, bg: "EAF0FD", dot: C.pink,
    title: "The one that will bite you", titleSize: 12,
    body: "On a client-issued Windows laptop the extension installs Fusion but does not add it to PATH, and execution policy blocks a PowerShell profile fix. A .cmd wrapper in WindowsApps solves it without an IT ticket.", size: 10,
  });
  card(s, {
    x: M + 8.44, y: 4.55, w: 3.79, h: 1.62, bg: "EAF0FD", dot: C.orange,
    title: "Take the runbook", titleSize: 12,
    body: "The full setup, including environment-variable database routing and the ADRs behind it, is documented. Do not rediscover this on your next engagement.", size: 10,
  });

  chrome(s, 8);
  s.addNotes(
`LOCAL SETUP (90 seconds, hard stop). Resist the urge to teach this. It is a runbook, not a talk.

The only conceptual point worth making, and it is the one that costs people an hour: there are two independent credentials and they do different jobs. dbt_cloud.yml gets you into dbt Cloud, which is what turns on Fusion and deferral. profiles.yml gets you into Snowflake. Neither substitutes for the other, and almost every setup ticket is someone assuming one covers both.

Call out externalbrowser. Local development authenticates as you over SSO, no service account, no key pair on a laptop. That is a security answer you can give a client directly.

Windows card: twenty seconds, tell it as a war story, not a procedure. It builds credibility that we have actually run this on a client-issued machine.

Then point at the runbook and move on. If people want the detail, it is written down and I will share the link.

TIMING: leave at 18:00. If you are running long anywhere in this deck, this is the slide to cut to thirty seconds.`);
}

// ============================================================
// 9. DEMO DIVIDER
// ============================================================
{
  const s = darkSlide();

  s.addText("DEMO", {
    x: M, y: 1.15, w: 6, h: 0.9, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 64, bold: true, color: C.white, valign: "middle",
  });
  s.addText("dbt Wizard in the Studio IDE, reading our project documentation and building a model", {
    x: M, y: 2.1, w: 7.2, h: 0.85, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 16, color: C.gray400, valign: "top", lineSpacingMultiple: 1.12,
  });

  const beats = [
    ["01", "It knows the project", "Ask an impact question before touching anything. The answer comes from the index, not from grepping."],
    ["02", "It knows our standards", "Wizard cites one of our ADRs and follows the convention it sets. This is the moment that proves the thesis."],
    ["03", "It validates before I trust it", "Diff review, then compile and build against the dev environment. Nothing persists unapproved."],
  ];
  beats.forEach((b, i) => {
    const y = 3.35 + i * 1.05;
    s.addShape(pres.ShapeType.roundRect, {
      x: M, y, w: 11.9, h: 0.9, rectRadius: 0.05,
      fill: { color: C.cardBgDark }, line: { color: C.cardBgDark, width: 0 },
    });
    s.addText(b[0], {
      x: M + 0.26, y: y + 0.2, w: 0.55, h: 0.5, isTextBox: true, margin: 0,
      fontFace: F, fontSize: 20, bold: true, color: [C.teal, C.blue, C.pink][i], valign: "middle",
    });
    s.addText(b[1], {
      x: M + 0.95, y: y + 0.13, w: 3.4, h: 0.32, isTextBox: true, margin: 0,
      fontFace: F, fontSize: 14, bold: true, color: C.white, valign: "middle",
    });
    s.addText(b[2], {
      x: M + 0.95, y: y + 0.44, w: 10.6, h: 0.36, isTextBox: true, margin: 0,
      fontFace: F, fontSize: 10.5, color: C.gray400, valign: "top",
    });
  });

  chrome(s, 9, true);
  s.addNotes(
`DEMO (8 minutes, rehearsed to 6).

Say the three beats out loud before you share the screen, so the room knows what to watch for. An unnarrated agent demo looks like magic or looks like nothing, and neither is useful.

Beat 1, impact question. Ask something like "what breaks if I change this column." Point out that the answer is instant and precise because it came from the index.

Beat 2, THE MONEY SHOT. This is the whole talk in one screen. Prompt Wizard to build a model and let it pull in our documentation. When it cites the ADR, stop and say it out loud: "that is our decision record, in our repo, being honored by dbt's agent in a browser. That is the thesis."

Beat 3, validation. Show the diff. Show it compile and build against dev. Emphasize that nothing was written without approval. This is the governance answer for the client.

PRE-FLIGHT, do all of this before the meeting:
- Warm the session, first-load is slow and it reads as the product being slow.
- Confirm skills loaded, ask "what skills do you have" as the first prompt.
- Confirm the project subdirectory is set, or slide 6 embarrasses you live.
- Have the recording open in a second tab. If anything stalls for more than 20 seconds, switch to it and keep talking. Do not debug live.
- Close anything with client-identifying data you do not want on a recording.

If the demo dies entirely: go to the recording, and if that fails too, go straight to slide 10. Do not troubleshoot in front of thirty people.

TIMING: leave at 26:00.`);
}

// ============================================================
// 10. DECISION GUIDE
// ============================================================
{
  const s = pres.addSlide();
  head(s, "THE DECISION", "Which surface, for which engagement");

  const y = 1.7, h = 2.95, w = 6.09;
  card(s, {
    x: M, y, w, h, bg: "EAF0FD", dot: C.blue,
    title: "Choose local: VS Code and Cortex Code", titleSize: 15,
    lines: [
      "The work is heavy refactoring across many models",
      "You need custom MCP servers in the loop",
      "Context spans more than the dbt project itself",
      "The team is engineers who already live in an editor",
      "You want inference inside the Snowflake account",
    ], size: 11, gap: 6,
  });
  card(s, {
    x: M + w + 0.3, y, w: w + 0.09, h, bg: "E6FAFF", dot: C.tealBg,
    title: "Choose Studio IDE and dbt Wizard", titleSize: 15,
    lines: [
      "Client analysts need to contribute without a local setup",
      "Laptops are locked down and installs need a ticket",
      "Onboarding speed matters more than editor power",
      "You want read-only users in Explore mode safely",
      "The client should still have this after we leave",
    ], size: 11, gap: 6,
  });

  s.addShape(pres.ShapeType.roundRect, {
    x: M, y: 4.88, w: W - 2 * M, h: 1.15, rectRadius: 0.06,
    fill: { color: C.navy }, line: { color: C.navy, width: 0 },
  });
  s.addShape(pres.ShapeType.ellipse, {
    x: M + 0.28, y: 5.13, w: 0.16, h: 0.16,
    fill: { color: C.teal }, line: { color: C.teal, width: 0 },
  });
  s.addText("Most engagements are not either-or", {
    x: M + 0.54, y: 5.08, w: 6, h: 0.28, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 14, bold: true, color: C.white, valign: "middle",
  });
  s.addText("BrightStar runs local for build-heavy work and keeps the platform surface available for lighter changes and for client-side contributors. One repo, one set of ADRs, one set of skills. Pick the surface per person and per task, not per project.", {
    x: M + 0.54, y: 5.4, w: 11.6, h: 0.5, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 11, color: C.gray400, valign: "top", lineSpacingMultiple: 1.08,
  });

  chrome(s, 10);
  s.addNotes(
`THE DECISION (2 minutes). Coming out of the demo, people want to know what to do with it. Give them a rule, not a feeling.

Left column is when local wins. The honest headline: heavy refactoring, custom MCP, context beyond the dbt project. Add the Snowflake point, if a client wants inference inside their account, that is the local CLI path with Cortex as a BYOK provider.

Right column is when the platform wins, and note that most of these are people problems, not technical ones. Locked-down laptops. Analysts who will never install a toolchain. A client who should still be able to run this after we roll off.

Bottom bar is the real answer and it is what we actually do. It is not either-or. Same repo, same ADRs, same skills, different surface depending on the person and the task. That is only possible because the harness is in the repo, which is where we started.

TIMING: leave at 28:00.`);
}

// ============================================================
// 11. CLOSE
// ============================================================
{
  const s = darkSlide();

  s.addText("THREE THINGS TO TAKE WITH YOU", {
    x: M, y: 0.72, w: 9, h: 0.32, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 12, bold: true, charSpacing: 2, color: C.teal, valign: "middle",
  });
  s.addText("What makes this work", {
    x: M, y: 1.08, w: 9, h: 0.6, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 36, bold: true, color: C.white, valign: "middle",
  });

  const pts = [
    ["1", "The harness is the repo", "Context, ADRs and skills in version control are the asset. The agent surface is a runtime choice you can change on a Tuesday without rebuilding anything.", C.teal],
    ["2", "Name the gaps out loud", "No custom MCP in the platform, no plan mode, a five minute command ceiling. Saying so is what makes the rest of the recommendation credible to a client.", C.blue],
    ["3", "Build it so the client keeps it", "A harness only we can run is a dependency. One that runs in their browser, on their standards, is delivery work that outlives the engagement.", C.pink],
  ];
  pts.forEach((p, i) => {
    const y = 2.0 + i * 1.18;
    s.addShape(pres.ShapeType.roundRect, {
      x: M, y, w: 11.9, h: 1.02, rectRadius: 0.05,
      fill: { color: C.cardBgDark }, line: { color: C.cardBgDark, width: 0 },
    });
    s.addText(p[0], {
      x: M + 0.26, y: y + 0.26, w: 0.45, h: 0.5, isTextBox: true, margin: 0,
      fontFace: F, fontSize: 24, bold: true, color: p[3], valign: "middle",
    });
    s.addText(p[1], {
      x: M + 0.85, y: y + 0.16, w: 4.0, h: 0.34, isTextBox: true, margin: 0,
      fontFace: F, fontSize: 15, bold: true, color: C.white, valign: "middle",
    });
    s.addText(p[2], {
      x: M + 0.85, y: y + 0.5, w: 10.7, h: 0.44, isTextBox: true, margin: 0,
      fontFace: F, fontSize: 10.5, color: C.gray400, valign: "top", lineSpacingMultiple: 1.05,
    });
  });

  s.addText([
    { text: "Start here:  ", options: { bold: true, color: C.white, fontSize: 12 } },
    { text: "river-guidebook   •   the local dbt setup runbook   •   docs.getdbt.com for dbt Wizard", options: { color: C.gray400, fontSize: 12 } },
  ], {
    x: M, y: 5.62, w: 11.9, h: 0.3, isTextBox: true, margin: 0,
    fontFace: F, valign: "middle",
  });
  s.addText("Questions", {
    x: M, y: 6.14, w: 6, h: 0.42, isTextBox: true, margin: 0,
    fontFace: F, fontSize: 21, bold: true, color: C.teal, valign: "middle",
  });

  chrome(s, 11, true);
  s.addNotes(
`CLOSE (1 minute), then Q&A.

Land the three, do not read them word for word.

One. The harness is the repo. Callback to slide 3. If they remember one sentence from today, this is it.

Two. Name the gaps out loud. This is a consulting point more than a technical one. Volunteering the limitation is what makes the recommendation trustworthy.

Three. Build it so the client keeps it. Tie it to how we talk about delivery. A harness only we can run is a dependency we created. One that runs on their standards in their browser is something we left behind on purpose.

Then: "if you are starting a dbt Cloud engagement, take the guidebook framework and the setup runbook and come find me. I would rather you copy this than rebuild it."

LIKELY QUESTIONS:
- "Is MCP coming to the platform?" Not announced. dbt says talk to your account rep. Do not promise a date.
- "What does this cost?" Token-metered against account credits, per account not per user, and you can set a spend limit. Get the number from the engagement's dbt Cloud admin, not from me.
- "Does this replace Cortex Code?" No. Different surface, same harness. On Snowflake engagements Cortex stays our default locally.
- "Is it production-ready?" Studio IDE Wizard is public preview. Treat it accordingly, and verify the feature set before you promise it to a client, because this is moving fast.
- "Can the client's analysts really use it?" Yes, in Explore only mode a read-only user can ask questions and cannot change a model. That is the safest entry point.`);
}

pres.writeFile({ fileName: "Harness-Engineering-with-dbt-Cloud.pptx" }).then(() => console.log("written"));
