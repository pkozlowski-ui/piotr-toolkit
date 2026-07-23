---
name: ideate
description: Structured divergent ideation — spawn N isolated cognitive frames that generate in parallel (no cross-talk), then an independent critic scores / clusters / flags anti-patterns, then the top picks get deepened. Use for genuinely open-ended creative, design, product, or naming problems ("give me directions for X", "ways to approach Y", a brainstorm with structure) where the risk is anchoring on the first idea. NOT for problems with a knowable answer, for producing final ship-ready variants, or for critiquing something that already exists (use second-opinion for that). Triggers EN+PL — "ideate", "ideation", "divergent", "give me directions / approaches / angles", "structured brainstorm", "X ways to", "ideacja", "daj kierunki", "rozbież", "burza mózgów strukturalna".
argument-hint: "The open-ended problem to ideate on (+ optional domain: design / IA / naming / product)"
---

# Skill: ideate

## Purpose

Beat **premature convergence**. A single reasoning pass anchors on its first plausible idea and elaborates that one; even a "list of 10" from one prompt is ten variants of the same anchor. `ideate` forces genuine divergence by generating from **isolated frames that never see each other**, then converges with an independent, adversarial critic. It is the upstream half of design work — it produces raw *directions*, not finished variants.

Mechanically it is a packaged, opinionated **Workflow** recipe (the `Workflow` tool's native fan-out). The value over an ad-hoc fan-out is the tuning: domain-fit frame libraries, an anti-pattern trap filter, model delegation, and a convergence stage that hands off cleanly to build.

## When to use (trigger, not default)

Reach for it only when the problem is **wide open and the cost of a narrow answer is real**:
- "Give me directions/angles/approaches for X" · naming · a fuzzy concept with many possible shapes · a design surface where the layout isn't obvious.

Do **NOT** use it for:
- A problem with a knowable/lookup answer, or clearly-scoped mechanical work → just do it.
- Producing final, ship-ready **variants** → that is downstream. Divergence here is deliberately *incoherent* (the whole point). Coherent-variation discipline ("one shared motif") applies AFTER you converge, not here.
- Critiquing / pressure-testing something that already exists → `second-opinion`.
- A conversational think-together → a plain back-and-forth (or `product-management:brainstorm`).

## The three phases (run via the `Workflow` tool)

1. **Diverge** — pick 5–10 cognitive frames. Spawn one isolated agent per frame, each getting only the problem + context + its frame's vantage prompt + a hard directive: *generate, do not evaluate*. Branches never see each other — that isolation IS the method. ~5–6 ideas each.
2. **Converge** — one independent **critic** (a different mind, adversarial stance) scores every idea (novelty / viability / fit / effort), clusters by underlying approach, and flags which **anti-patterns** each idea trips. Shortlist = top few by weighted score AND novelty that are trap-clean; plus one high-novelty **wildcard**.
3. **Deepen** — expand the shortlist + wildcard into sketches (concrete artifact + the one load-bearing risk + smallest first step to test it + how it fits what already exists). Highest-effort model here.

## The one invariant

**Branches must run isolated and in parallel — never serialized, never sharing context.** A sequential simulation collapses the method into "one wider thought." Use `parallel()` for diverge (barrier: the critic needs the whole pool at once).

## Model delegation + two cost modes

Match the model split to the doctrine "delegate mechanics, keep judgment on the top tier":
- **Diverge** → `sonnet` (generation, not pure mechanics), `effort: medium`.
- **Critic** → `sonnet`, `effort: high`.
- **Deepen** → inherit the session model (Opus), `effort: high` — this is the judgment that earns the cost.
- The **main session curates** the final digest; don't outsource the recommendation.

Two modes — **always state which you ran**:
- **Lean (default):** 5–6 frames × 5 ideas, deepen top-3. One good sweep, respects the usage cap.
- **Max (only on explicit "don't spare tokens" / "be exhaustive"):** 8–10 frames × 6, deepen top-3 + wildcard. The validation run cost ~1.3M subagent tokens — do not reach for max by default.

## Frames — pick orthogonal, adapt per domain (do not reuse generic)

Frames are the lever. Pick 5–10 that attack the problem from **genuinely different angles**; if several frames keep collapsing to the same idea, they weren't orthogonal (a real failure mode — the validation run had 10 near-duplicate "morning brief" ideas because too many frames implied narration). Starter libraries by domain:

- **Design / look & feel:** de-chrome minimalist · information-density · editorial/typography · a named competitor · "remove one step" · the primary end-user at their worst moment.
- **IA / flow:** the tired power-user at 4pm · a brand-new user on day 1 · inversion ("what if this screen didn't exist") · the highest-frequency task.
- **Naming:** plain-English · glossary/consistency lens · competitor-parity · audience register.
- **Product / strategy:** each real decision-maker as a lens · jobs-to-be-done · the sceptic who thinks the feature is unnecessary.
- **AI/assistant surfaces:** where the AI removes work (not relabels it) · signal vs noise · trust/explainability.

Always include at least one **inversion** frame and one **domain-expert / real-user** frame — they consistently surface the non-obvious and kill vanity ideas.

## Traps — the convergence filter is the domain's anti-patterns

The critic's trap list is where domain knowledge enters. Supply the **known anti-patterns** for the domain as explicit flags, so convergence enforces house rules, not generic "trap detection."
- **In antisys (Staff/design work):** pull them from `CLAUDE.md` + Pattern Decision Library — e.g. template-first dashboard, Manta unbranded / signal-stacking off-context, color-only meaning (WCAG 1.4.1), DeltaChip amber-for-positive, inventing a new archetype instead of scoping one, PII on a board-safe surface, decorative (not semantic) data-viz, reskin-dressed-as-idea, scope-bleed. (This is what made the validation run catch real DS violations, not hallucinated ones.)
- **Generic:** derive the domain's failure modes first, or ask the caller for them. A trap list of clichés is what separates this from a generic brainstorm.

## Output — digest always, deliverable routed, converge before build

- **Always:** a chat digest — shortlist + wildcard + a single clear recommendation (a table reads well). This is a recommendation skill; end with a pick.
- **Route the payload** per deliverable discipline (never leave it only in chat):
  - Design ideation → **FigJam** stickies (clusters = sections) — but only once it is a real review artifact, not a raw unvetted dump.
  - Naming / product / research → **Obsidian** (`Research/` or a concept note linked from the task).
- **Converge → build handoff.** The chosen direction is the input to the normal pipeline (`figma-design-workflow`, `lighthouse-to-mvp`); coherent-variation discipline kicks in there. `ideate` never ships a screen.
- If the ideation is on an **open concept not yet verified against source** (a Linear ticket, a brief), say so — keep it as a note, don't push it to a team surface as if it were vetted.

## Script skeleton

Write the script inline to `Workflow` (it auto-persists to a file you can iterate on). Shape:

```js
export const meta = { name: 'ideate', description: '...', phases: [{title:'Diverge'},{title:'Converge'},{title:'Deepen'}] }
const PROBLEM = `...`, CONTEXT = `... persona + house canon, tight`
const FRAMES = [ { key, prompt }, ... ]           // 5-10 orthogonal
const TRAPS  = [ 'domain anti-pattern', ... ]      // house rules
// Diverge — barrier, isolated
const pool = (await parallel(FRAMES.map(f => () =>
  agent(`${CONTEXT}\nPROBLEM:${PROBLEM}\nFRAME:${f.prompt}\nGenerate 6 ideas from THIS frame only. Do NOT evaluate.`,
    {label:`frame:${f.key}`, phase:'Diverge', model:'sonnet', effort:'medium', schema:IDEA_SCHEMA})
    .then(r => (r?.ideas||[]).map(i => ({...i, frame:f.key})))))).filter(Boolean).flat()
// Converge — single critic, needs whole pool
const c = await agent(`...critic: score+cluster+flag TRAPS+shortlist+wildcard. Pool: ${JSON.stringify(pool)}`,
  {label:'critic', phase:'Converge', model:'sonnet', effort:'high', schema:SCORE_SCHEMA})
// Deepen — top picks, judgment tier
const deepened = await parallel([...c.shortlist, c.wildcard].filter(Boolean).map(t => () =>
  agent(`Deepen "${t}": sketch, load-bearing risk, first step, fit to existing.`,
    {label:`deepen:${t.slice(0,24)}`, phase:'Deepen', effort:'high', schema:DEEPEN_SCHEMA})))
return { clusters:c.clusters, scored:c.scored, shortlist:c.shortlist, wildcard:c.wildcard, deepened:deepened.filter(Boolean) }
```

## Rules

- **Isolation is non-negotiable.** Parallel, no cross-talk. If you can't run them isolated, you're not running `ideate`.
- **Frames orthogonal, adapted, ≥1 inversion + ≥1 real-user/expert.** Generic reused frames = a generic brainstorm.
- **Traps = real house anti-patterns**, or the skill is just a wider thought.
- **Lean by default; max only on explicit request.** State the mode and the rough cost.
- **End with a recommendation**, route the deliverable, hand off to build — never ship from here.

## Provenance

Adapted from the ADHD skill (UditAkhourii/adhd — divergence/convergence against premature convergence), retuned to this toolkit's doctrine: domain-fit frames, house anti-pattern traps, model delegation, deliverable routing. Gate-validated 2026-07-23 on a real antisys problem (KIPP School Leader VA dashboard directions): produced ≥3 non-obvious directions and the trap filter caught real DS violations (unbranded Manta, color-only meaning, new-archetype, PII-on-glance) rather than hallucinated ones.
