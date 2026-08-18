---
name: code-design-audit
description: >-
  Audit a built front-end against its design — the code-side counterpart of a Figma-side polish
  loop. Layered: static design-system/a11y/copy checks on source, design↔DOM content parity,
  measured geometry/affordance parity, and a craft pass delegated to design-toolkit:design-tweaker
  on real screenshots. Routes every finding to the artefact that owns it (when the design file is
  the source of truth, a code-only fix is drift) instead of fixing the symptom where it was seen.
  Two layers: a project-agnostic loop + invariants (this file) and a per-project overlay (screen
  registry, token sources, copy lexicon, exception ledger) that lives in the product repo. Use when
  asked to "audit the prototype", "check the code against Figma", "is the prototype faithful to the
  design", "design-vs-code audit", "zaudytuj prototyp", "sprawdź zgodność kodu z designem", or
  before handing a built prototype to review. NOT for: design-file quality (→
  figma-design-toolkit:ui-polish-loop), a quick smoke check after one edit (→
  workflow-toolkit:browser-verify), correctness review of a diff (→ code-review), or pure craft
  judgement with no design file to compare against (→ design-toolkit:design-tweaker alone).
---

> **Cross-project canonical skill** (piotr-toolkit → `design-toolkit`). This file is the
> **doctrine layer**: the loop, the invariants, the terminal states, the routing rule. It works
> against any codebase, with or without the JS check engine.
> The **per-project overlay** (screen registry, token sources, roots, copy lexicon, owners map,
> exception ledgers) does **not** live here — it lives in the product repo. Seed it from
> `reference/config-template.json` + `reference/manifest-template.json`.
> **Reference implementation:** the Anti-SIS engagement (`eval/audit/` + `eval/audit/README.md`,
> ~3 400 lines of engine, 2 751-line self-test, 109 screens) — that repo's README is the fully
> worked instance of everything below. Promote new heuristics back here (§9).

# code-design-audit

Drive a **built prototype** to design-faithfulness. `figma-design-toolkit:ui-polish-loop` does this
for the design file; this does it for the running app, and deliberately does not duplicate it — the
two audit different substrates and route findings to different places.

## 0. Two layers, and what actually runs here

**Doctrine (this file)** ports 1:1 to any project. **The engine does not** — it needs a screen
registry, a readable token layer, and captured baselines. Before promising anything, establish
which tier this project can reach:

| Tier | Needs | Gives |
|---|---|---|
| **T0 — loop only** | nothing | the sequence, the invariants, named terminal states, owner routing. Findings come from reading + `design-tweaker`. |
| **T1 — static** | token sources + source roots (§1) | design-system token drift, layout invariants, a11y code tells, copy-lexicon violations. Seconds, no browser. |
| **T2 — runtime DOM** | dev server + Playwright + axe | measured WCAG on the rendered page, glyph/paint colour, affordance inventory. |
| **T3 — design parity** | design file as source of truth + per-screen node ids + captured baselines | content parity (is this the right record set?), geometry parity (is an off-scale value drift or a faithful copy?). |

**A project without a design file as source of truth stops at T2 — that is the correct outcome,
not a failure.** Say so explicitly. The failure mode is a T3 layer that never ran reading as
green: an uncaptured screen is *unverified*, never *clean*.

## 0.5 Cost gate and inspection scope — map first, then inspect

A full T1–T3 pass over a large surface costs real context: static checks across every source root, a
browser run per screen, and a `design-tweaker` delegation per screenshot. Bound it before you start.

**Abort checks.** Any "no" → do the smaller thing instead and say so in one line.

1. **Is there a design artefact or shipped surface to be faithful to?** Otherwise there is nothing to
   measure parity against → `design-toolkit:design-tweaker` alone.
2. **Is more than one screen in question?** A single edit just landed → `workflow-toolkit:browser-verify`.
3. **Did the user leave the target open?** If they named the screen, audit that screen. Do not widen a
   pointed question into a full sweep.

An explicit "full audit" / "zaudytuj cały prototyp" is an opt-in: skip the checks and run it.

**Surface tiers.** Always map first, then inspect selectively.

| Surface | Approach |
|---|---|
| **Small** — under ~10 screens | inspect every screen directly, across the tiers the project reaches |
| **Medium** — ~10–40 screens | map the registry first, then T1 across all of it, T2/T3 only on the screens the question touches plus the highest-traffic ones |
| **Large / monorepo** — several apps or 40+ screens | **ask which app or module.** If the user cannot narrow it, produce a shallow map and name the most useful target for a deep pass. Do not silently audit all of it. |

**Inspection scope note — mandatory in every report.** A broad request must not silently become an
exhaustive audit, and a partial audit must not read as a clean bill of health. State:

- what was **mapped** (registry, roots, token sources)
- what was **inspected deeply**, and at which tier
- what was **sampled**
- what was **intentionally skipped**, and why
- which findings are **high confidence** vs **provisional**

This is §0's "an uncaptured screen is *unverified*, never *clean*" made visible to the reader instead
of implied. A report without the scope note is not finishable — it is the thing that stops a T3 layer
that never ran from reading as green.

## 1. Overlay — propose-first, never guess

The overlay is project data, and inventing it produces confident nonsense (a copy lexicon guessed
from vibes will flag every acronym in the product). If the project has no overlay:

**Stop and propose one from `reference/config-template.json`.** Do not fabricate token paths,
acronym lists, or exception ledgers. Ask for what only the human knows: which UI library, which
token layer is canonical, whether the design file is the source of truth, and which screens exist.

The overlay declares, at minimum:

- `tokenSources` — where the scale actually lives (CSS custom properties + theme file). **Scales
  are derived from these at runtime, never hardcoded in a check.**
- `roots` — app / design-system / screens / fixtures source roots.
- `typeScale`, `scaleExtras` — the allowed values, plus the ones legitimately on-scale but not
  derivable from a declaration (each with a stated reason).
- `runtimeTokenPrefixes` — vendor/runtime CSS-var prefixes to ignore (e.g. a UI library's own).
- `copy` — acronyms, ghost/retired terms, placeholders, canonical year/number formats, Title-Case
  stopwords. **Pure product vocabulary.**
- `owners` — check id → owning artefact (`code` / `figma` / `both` / `verify` / `process`).
- `outOfScope`, `exceptions`, `nodeExceptions` — the ledgers of what is knowingly unmeasured or
  knowingly accepted, **each entry carrying a reason**. These are debt, not settings.
- A screen registry (`reference/manifest-template.json`): `id ↔ route ↔ design nodeId ↔ viewport`,
  plus `baseUrl` and the design `fileKey`. This is what makes T2/T3 addressable at all.

## 2. What each gate already claims — don't re-audit it

Write this table for the project before running anything; the point is the right-hand column.

| Gate | Claim | Blind to |
|---|---|---|
| pixel diff vs design export | geometry + chrome match at one viewport, one state | content, tokens in code, a11y, copy, states, breakpoints |
| static layer | tokens on scale, layout invariants, a11y code tells, copy rules | anything needing a rendered page |
| content parity | the record set on screen matches the design | whether the design itself is any good; field *order*; exact wording |
| `design-tweaker` | craft and judgement | cross-screen consistency, mechanics |
| runtime a11y | WCAG A/AA measured on the DOM | intent; anything not rendered |
| geometry parity | whether an off-scale value is code drift or a faithful copy | anything outside spacing/radius/type |
| affordance inventory | controls the code renders that the design doesn't draw, and vice versa | affordance kinds not modelled; screens with no baseline |

## 3. The loop

0. **SETUP** — name the flow and its screens from the registry. Read the project's audit canon.
   Start the dev server through the harness's preview tooling (never a bare shell), and **confirm
   the port belongs to this checkout** — a dead server frees its port and the harness will happily
   measure another branch's code:
   ```bash
   lsof -a -p "$(lsof -ti tcp:<port> | tail -1)" -d cwd -Fn | grep '^n'
   ```

1. **PROVE THE INSTRUMENTS** — run the self-test. **If a lens is dead, its green result means
   nothing.** Fix it before reading any report. Same rule as any design-side gate.

2. **STATIC LAYER** — report-only first. Read the whole report before fixing anything: a check
   firing 40× is describing a convention (one shared-component defect), not 40 defects.

3. **PARITY** — needs baselines. A screen reporting `no-baseline` is **unverified**, whatever the
   pixel gate says about it. **Read the baseline-missing list as a to-do list, not as noise** — in
   the reference implementation, five real divergences were found by reading the design file
   directly in a flow where 7 of 15 screens had never had a baseline captured and parity had never
   been run that session; the INFO finding had been saying "unverified" the whole time.

3b. **STRUCTURAL WALKTHROUGH — mandatory for any screen with meaningful interactive surface**
    (drawers, forms, rows with actions). No mechanical layer measures these three, and treating
    them as "covered because the gate is green" is exactly how they ship silently:
    - **Component variant/prop identity per instance** — a DS-compliant, token-correct call site
      can still use the wrong *variant* for this screen (badge `dot` vs `tint`: same component,
      same tokens, different look). Nothing is wrong in isolation, so no static check can see it.
    - **Field/section order and exact label wording** — parity compares content as a *set*, not a
      sequence, so two swapped fields, or a label reworded to a different-but-valid string, read
      as independent `missing`/`extra` items instead of the structural defect they are.
    - **The interactive-element SET** — does the code render an affordance the design does not
      draw, or miss one it does. These carry no text, so a text-based parity walk cannot see them
      *by construction*, not by a gap in baseline coverage.

    Do it by pulling the design context/metadata for the screen's exact node and listing every
    component instance + variant/props, every interactive element, and the field order
    top-to-bottom — then diff that list against the call sites and the rendered DOM by hand.

4. **CRAFT** — `design-toolkit:design-tweaker`, panel mode for a whole flow. Feed it **real
   screenshots** plus the design-system context (tokens, component registry) so it grounds in
   *this* system. Run it at least once per flow — clean mechanics are not craft.

5. **TRIAGE — read the direction, don't invent it.** Every finding carries an `owner`. For
   `verify`, run the geometry measurement — it settles direction by measuring the design file's
   layout inventory instead of leaving it to judgement. **Do not reason your way to a direction a
   tool can measure**: in the reference implementation that judgement was made by hand for four
   entries ("forced by a layout transcribed from Figma"), and the measurement showed the design
   used neither value anywhere. STRUCTURAL slop (wrong layout archetype) ⇒ STOP, decide with the
   user. A rule failing on most screens is **one shared-component defect**, not N.

6. **FIX** — code-owned findings only (a11y semantics, keyboard, states, parity gaps, token
   bypasses). Anything owned by the design file goes back through the design-side loop, and the
   code follows.

7. **RE-AUDIT** — static layer as a gate (not report-only) + parity on touched screens + runtime
   a11y + the pixel gate, to confirm nothing moved geometrically. Geometry parity must exit 0 — it
   fails when a ledger entry justifies itself with the design file while the design file does not
   carry the value. **Still red → this closes round N; loop to 6 for N+1, bounded by
   `max_iterations`.**

8. **HAND THE OTHER DIRECTION OVER** — collect every non-code-owned finding into one design to-do
   list. Route it to the project's design-side loop, `figma-design-toolkit:ui-polish-loop`.
   **Fallback when the project hasn't set up that loop yet**: route those findings to
   `design-toolkit:design-tweaker` for the design-side judgement, and park each one as a task/card
   with its owner and reason. **Never silently fix a design-owned finding in code** because no
   design-side loop exists — that is exactly the drift this skill is for.

9. **CONVERGE** — explicit `max_iterations` (default 3 rounds of 6→7, hard ceiling 8) and four
   terminal states, reported **by name**, never inferred:
   - **`converged`** — static layer clean of errors · parity within budget or every divergence
     documented with a reason · every screen has a baseline, or the gap is named as debt rather
     than silently accepted · the structural walkthrough (3b) has run on every screen with
     interactive surface · the craft pass has run ≥1× · pixel gate green.
   - **`max_iterations_reached`** — ceiling hit without all of the above. Report the round it
     stopped at and what remains as WARN/INFO debt. **This is NOT `converged`**, even if the last
     round's diff was small — there is no dry-round check here, so don't claim a convergence you
     didn't measure.
   - **`failed`** — a gate itself couldn't run (self-test failing, server on the wrong port, an
     unreachable design node). The loop broke; it didn't just find a lot.
   - **`interrupted`** — the user stopped mid-round, or the session ended before a round closed.

## 4. Invariants (the transferable part — each one is a paid-for lesson)

1. **No "clean" without the self-test passing.** A green audit on a dead lens is a false claim.
2. **`0 findings` is only readable together with coverage.** "Not measured" and "measured clean"
   are different facts. A screen that failed to render is an error-severity finding of its own
   class, never folded into a green count.
3. **Adding a check means adding its break-restore case** — introduce a defect of that class,
   confirm the check fires, restore. No exceptions. Take the check's name from the report's own
   counts, not from a grep over the source, or the proof is of the wrong thing.
4. **Direction is a field, not advice.** `owner` travels with the finding so it survives a session
   that never reads this file.
5. **Measure the property that paints**, not the one that inherits (a host's `color` is not the
   glyph's `stroke`) — proxies produce confident findings on working code.
6. **An anchored regex is blind to alternative syntax** for the same defect: ternary, template
   literal, runtime transform, missing word boundary. Cheap test: re-grep with the anchor removed
   and compare counts.
7. **A false acquittal is worse than a false finding.** Any rule that *softens* a verdict
   (derivation, escape, collapse) needs a mirrored break-restore — fire *and* silent — or it
   whitewashes real drift.
8. **A fix can be as dead as a check.** Verify systemic fixes in the rendered result, not in the
   diff. (Programmatic `.focus()` does not satisfy `:focus-visible` and lies in both directions.)
9. **Never raise a budget or add a ledger exception without a stated reason.** Budgets and
   exceptions are debt on the record, not settings — re-test them after any design-system fix.
10. **A green pixel gate is not evidence about content.** Say "geometry matches", not "matches the
    design", unless parity ran.
11. **Name the unmeasured classes honestly** rather than forcing a bad check (variant identity and
    field order/wording are the two standing ones — §3b is the bridge until a cheap check exists).

12. **An a11y finding carries its WCAG success criterion id.** axe already reports it on every
    result (`tags: ["wcag143", "wcag412", …]`) — surface it in the finding instead of dropping it,
    and tag hand-found a11y findings from the crib sheet in
    `figma-design-toolkit:figma-accessibility`. Level travels with the id (A/AA = compliance,
    AAA = advice). Without the id the finding is an opinion; with it, it survives into a ticket
    and into the client's own compliance review unchanged.

## 5. Wire it into the harness, not into prose

A rule that says "run the audit before done" fires when someone remembers it — measured at 0/8
sessions in the reference implementation for a comparable rule. Wire the static layer to a
PostToolUse hook scoped by a **configurable path filter** (UI + design-system source only), run it
per edited file in report-only mode, and inject error/warn findings into the same turn; add a Stop
hook that reminds when a UI file was touched but the whole-repo run never happened. Treat injected
findings as findings you already have: route them, don't re-run everything to rediscover them.
A per-file run cannot see a defect whose shape is "one token, 24 screens" — the whole-repo run
stays the gate.

## 6. Synergy map (what to call, and what not to duplicate)

- `figma-design-toolkit:ui-polish-loop` — the design-side counterpart. Route design-owned findings
  there instead of fixing them in code; take code-owned findings it surfaces back here. Keep one
  overlay shape where a project runs both (component names, brand/experience rules).
- `design-toolkit:design-tweaker` — **owns craft judgement** (step 4, and the fallback in step 8).
  Delegate; never reimplement its lenses here.
- `design-toolkit:mobile-audit` — mobile-viewport deep dive when the flow is mobile-first.
- `figma-design-toolkit:figma-cloud` / `figma-console` — read design nodes and capture the
  baselines T3 depends on.
- `figma-design-toolkit:figma-handoff-prep` — its overlay (target UI library, token namespace,
  component registry) is **the same input** this skill needs. Keep one overlay shape per project,
  not two.
- `workflow-toolkit:browser-verify` — the cheap tier *below* this skill (one edit, smoke check).
- `workflow-toolkit:verifier` — independent black-box confirmation before declaring a terminal
  state.
- `workflow-toolkit:session-retro` — where new heuristics get promoted (§9).
- `obsidian-toolkit:obsidian-kanban` — deferred findings become cards, with owner and reason.

## 7. Engine distribution (Tier 2 — deliberately not shipped yet)

The check engine (dispatcher + `lib/` + static checks + runtime runners + self-test, ~3 400 lines)
is written to be portable — scales are derived from the token sources at runtime and everything
project-specific lives in the overlay. It is **not** vendored into this plugin yet: promoting it
without a second real project would harden it against a single instance. When a second project
needs it, vendor it as `engine/` beside this file plus a setup step that copies it into the target
repo and writes the npm scripts; upgrade to a versioned git/npm dependency when a third appears.
Until then, a new project runs T0–T2 from this doctrine plus the reference implementation's engine
as a copy source, and **says which tier it is on**.

Two check classes in the reference implementation are irreducibly project-specific and must **not**
be copied blind: an iteration-phase check (screen tagged as a later phase still importing that
phase's chrome) and a feature-flag-coverage check (module with no flag definition). Both encode one
product's phase/flag model.

## 8. Definition of Done

Terminal state named per §3.9 + a ledger reported (fixed / routed to the design side / deferred,
with severity and owner) + the tier stated (§0) + any new heuristic promoted into the project's
audit canon and, if project-agnostic, back into this file.

## 9. Self-improvement

Promote back here anything that is **not about one product**: a new invariant, a new instrument
failure class, a better convergence rule. Keep product vocabulary, paths, ledgers and dated
incidents in the product repo. When a lesson arrives with a measurement, bring the measurement —
an invariant without evidence is a preference.
