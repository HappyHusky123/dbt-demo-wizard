# Harness Engineering with dbt Cloud

**Speaker notes / talking points.** Tech Talk Tuesday, 30 minutes: 25 content, 5 Q&A.
These are the same notes embedded in the deck's speaker-notes pane.

| Slide | Segment | Leave by |
|---|---|---|
| 1 | Hook and thesis | 1:00 |
| 2 | Why this matters | 3:00 |
| 3 | One harness, two surfaces | 6:00 |
| 4 | Metadata engine | 8:30 |
| 5 | Surfaces and governance | 10:30 |
| 6 | Studio IDE setup | 14:30 |
| 7 | What transfers | 16:30 |
| 8 | Local setup | 18:00 |
| 9 | Demo | 26:00 |
| 10 | The decision | 28:00 |
| 11 | Close, then Q&A | 30:00 |

---

## Slide 1. Title

OPEN (60 seconds). Do not start with dbt Wizard. Start with the problem.

"Most of us have built an AI harness on a local setup. Context framework, ADRs, skills, Cortex Code. It works, and it is a real differentiator on engagements. Then a client tells you they are standardizing on dbt Cloud, and the quiet assumption in the room is that the harness was a local thing and now we lose it."

"That assumption is wrong, and this talk is about why."

Set the frame immediately: the harness is the repo, not the tool. The surface is swappable. Everything else today is evidence for that one sentence.

Name the two surfaces on the right so people know where we are going. Note that BrightStar Capital Partners is the live engagement behind this, so this is not theory.

TIMING: be off this slide by 1:00.

## Slide 2. The setup: the platform decision is not an AI decision

WHY THIS MATTERS (2 minutes).

Left card: do not oversell. These are good reasons. Governance, scheduling, CI, and an environment story the client's audit team can point at. We should not be talking clients out of dbt Cloud.

Middle card: this is the moment to be honest that we have all thought at least one of these. Say it plainly, it earns credibility for the rest of the talk.

Right card: three facts that flip it. Wizard is in the platform, custom skills load from the repo, our framework travels. Do not explain them yet, just plant them.

Bottom card is the one that matters to a partner or a client sponsor. Read it close to verbatim. A harness the client can run without us is a retention story, not a threat. If someone pushes on "does this commoditize us," the answer is that the value was never the tool, it was the ADRs and the standards we put in the repo.

TIMING: leave at 3:00.

## Slide 3. The thesis: one harness, two surfaces

THE THESIS (3 minutes). This is the slide people should photograph.

Walk it from the middle out, not top down. Point at the navy block first.

"Everything that makes our agent good at this work is in the repo. The context framework from river-guidebook. The ADRs. The skills. The conventions and contracts. None of that is tied to an editor."

Then the two surfaces. "These are consumers of that repo. Cortex Code reads it locally. dbt Wizard reads it in the browser. Same source of truth."

Then the base. "And underneath both, dbt Cloud is still doing the thing the client bought it for: Fusion, deferral, environments, jobs, CI."

The line to land: "If you change the surface, you do not rebuild the harness. You point a different agent at the same repo."

Callback for the room: this is the same principle Chris showed in the agentic workspace talk, thin skills over rich docs. We are testing whether it survives a platform move. It does.

TIMING: leave at 6:00.

## Slide 4. dbt Wizard 1 of 2: why it is not just another coding agent

dbt WIZARD, PART 1 (2.5 minutes). This is the slide that earns the audience's respect, because it is the part most people have not read.

Lead with the analogy, it does the work. "Wizard builds a structured index of the project before your first prompt. A generic coding agent greps files. The docs put it well: Wizard has a map of the whole city, a grep agent walks every street to figure out the layout."

Middle card, do not read all six. Pick two that land with this room: column-level lineage and contract status. Say "this is metadata we already generate, it is just indexed and handed to the agent up front."

Right card is the practical one and it is the most common failure mode. Stale manifest, stale agent. Locally you recompile. In the platform it comes from your connected dev environment.

Bottom row, the payoff. If you only say one: impact analysis. "What breaks if I change this column" is the question every analytics engineer asks ten times a day, and it is answered from an index rather than guessed.

Honest caveat if asked: this does not make it smarter than Cortex Code at writing SQL. It makes it better grounded in this specific project.

TIMING: leave at 8:30.

## Slide 5. dbt Wizard 2 of 2: where it runs, and how you keep it on a leash

dbt WIZARD, PART 2 (2 minutes). Move fast here. This is orientation, not a deep dive.

Left card: name the four surfaces once so nobody is confused later, then flag the correction. A lot of people, including my first draft of this agenda, say "Studio IDE with the Wizard CLI." Those are two different things. The CLI is a local terminal agent. Studio IDE Wizard is in the browser.

Throwaway that this room will like: the CLI supports Snowflake Cortex as a BYOK provider. So on a Snowflake engagement you can keep inference inside the account.

Right card is the one to slow down on for thirty seconds, because it is the client conversation. Agent mode and validation depth are not developer preferences, they are governance controls. Explore only means a read-only analyst can use the agent and cannot touch a model. That is how you get a client comfortable.

Bottom row: do not read it. Say "these four are the questions your engagement lead will ask, the slide is here so you can screenshot it." Flag that billing changed on September 1st and is per account, not per user, which matters for how we scope a pilot.

TIMING: leave at 10:30.

## Slide 6. Studio IDE: making the platform surface a real harness

STUDIO IDE SETUP (4 minutes). This is the how-to section. Be concrete, this is what they will copy.

1. Say the path out loud twice: dot agents, slash skills, slash skill name, slash SKILL dot md. Same Agent Skills format we already use, so our existing skills mostly move as-is. Note the precedence rule, a custom skill with the same name beats the dbt built-in, which is how you override their opinion with ours.

2. Connect to river-guidebook explicitly. The framework does not change, only where it sits. Reinforce thin skills over rich docs. Mention memories, they are underused.

3. Be honest about the gaps before anyone finds them in the demo. No custom MCP in the platform today, that is CLI only. No plan mode. Five minute command timeout. Say "if you need custom MCP, that is a reason to choose local, and that is a legitimate answer."

4. SLOW DOWN. This is the most useful thirty seconds in the talk. On BrightStar the dbt project sits in a subdirectory. Studio IDE resolves dot agents relative to the project root you configured, not the repo root. Put your skills at the repo root and the agent silently sees nothing. No error, just an agent that does not know your standards.

Bottom bar: edit a skill, start a new chat. People will hit this in the first hour.

TIMING: leave at 14:30.

## Slide 7. The honest comparison: what transfers, and what does not

WHAT TRANSFERS (2 minutes). Do not read either column. Let people scan, then make the point.

Give them ten seconds of silence to read. Then say the bottom line, which is the whole slide:

"The left column is the harness. The right column is tooling preference. Only one of those is a reason to walk away from the platform surface."

If you want one example from each side: skills travel, because it is the same open Agent Skills format. Custom MCP does not, because the platform only ships built-in dbt tooling today.

Expect pushback on MCP. This is the strongest objection and you should welcome it. Answer: "correct, and if your engagement depends on custom MCP, use the local surface. Notice that is a surface decision, not a harness decision. The repo did not change."

Also expect a question on the 5 minute timeout. It is real and it bites on large builds. It is an argument for running heavy builds as jobs, which is what dbt Cloud is for anyway.

TIMING: leave at 16:30.

## Slide 8. Local development: VS Code, connected to the platform

LOCAL SETUP (90 seconds, hard stop). Resist the urge to teach this. It is a runbook, not a talk.

The only conceptual point worth making, and it is the one that costs people an hour: there are two independent credentials and they do different jobs. dbt_cloud.yml gets you into dbt Cloud, which is what turns on Fusion and deferral. profiles.yml gets you into Snowflake. Neither substitutes for the other, and almost every setup ticket is someone assuming one covers both.

Call out externalbrowser. Local development authenticates as you over SSO, no service account, no key pair on a laptop. That is a security answer you can give a client directly.

Windows card: twenty seconds, tell it as a war story, not a procedure. It builds credibility that we have actually run this on a client-issued machine.

Then point at the runbook and move on. If people want the detail, it is written down and I will share the link.

TIMING: leave at 18:00. If you are running long anywhere in this deck, this is the slide to cut to thirty seconds.

## Slide 9. Demo

DEMO (8 minutes, rehearsed to 6).

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

TIMING: leave at 26:00.

## Slide 10. The decision: which surface, for which engagement

THE DECISION (2 minutes). Coming out of the demo, people want to know what to do with it. Give them a rule, not a feeling.

Left column is when local wins. The honest headline: heavy refactoring, custom MCP, context beyond the dbt project. Add the Snowflake point, if a client wants inference inside their account, that is the local CLI path with Cortex as a BYOK provider.

Right column is when the platform wins, and note that most of these are people problems, not technical ones. Locked-down laptops. Analysts who will never install a toolchain. A client who should still be able to run this after we roll off.

Bottom bar is the real answer and it is what we actually do. It is not either-or. Same repo, same ADRs, same skills, different surface depending on the person and the task. That is only possible because the harness is in the repo, which is where we started.

TIMING: leave at 28:00.

## Slide 11. Close: what makes this work

CLOSE (1 minute), then Q&A.

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
- "Can the client's analysts really use it?" Yes, in Explore only mode a read-only user can ask questions and cannot change a model. That is the safest entry point.
