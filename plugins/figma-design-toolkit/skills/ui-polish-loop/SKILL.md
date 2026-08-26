---
name: ui-polish-loop
description: >-
  Iteratively raise the UI quality of a Figma flow — audit → triage → fix → re-audit until
  convergence. Combines a mechanical layer (token/scale/instance/spacing/copy compliance, if the
  project has a gate for it) with a qualitative layer (hierarchy, spacing rhythm, alignment,
  look & feel, AI-slop, a11y, copy register) and a cross-screen layer (instance drift, nav
  active-state, mobile↔desktop parity). Auto-fixes mechanical/structural findings; proposes
  visual ones ranked by impact×effort. Self-improves: rejected fixes and retros promote new
  heuristics back into the loop. Two layers: a project-agnostic engine (this file — the loop,
  the dimension catalog, the triage rule, the four terminal states, the self-improvement
  mechanism) + a per-project overlay (gate functions, screen registry, component names, brand/
  experience rules) that lives in the product repo. Use when asked to "polish/audit-and-fix a
  flow", "improve screen quality", "dociśnij/wypoleruj flow", or after building a new flow
  before review. Figma-only — the built-prototype counterpart is
  design-toolkit:code-design-audit. NOT for: a first build of a screen (→
  figma-design-workflow), pure craft judgement with no iteration loop (→
  design-toolkit:design-tweaker alone), or a one-off token/drift sweep (→ figma-ds-tools).
---

> **Cross-project canonical skill** (piotr-toolkit → `figma-design-toolkit`). This file is the
> **doctrine layer**: the loop, the dimension catalog, the triage rule, the terminal states, the
> self-improvement mechanism. It works against any Figma design system, with or without a
> project-specific mechanical gate.
> The **per-project overlay** (gate functions, screen/node-id registry, component names,
> intentional-exception ledger, experience/brand rules) does **not** live here — it lives in the
> product repo. Seed it from `reference/config-template.json`.
> **Reference implementation:** the Anti-SIS engagement
> (`docs/design-system/04-page-blueprints/ui-polish-loop-playbook.md`, ~730 lines of accumulated
> patterns/gotchas/tuning-log across 3 sibling experiences) — that playbook is the fully worked
> instance of everything below, plus 200+ lines of product-specific pattern library that does
> **not** belong here. Promote new heuristics back to this file (§9); keep product vocabulary,
> node IDs and dated incidents in the product repo.

# ui-polish-loop

Drive a Figma flow to UI-quality convergence via `audit → triage → fix → re-audit` rounds. The
design-side counterpart of `design-toolkit:code-design-audit` — that skill drives a **built**
prototype to design-faithfulness; this one drives the **design file itself** to quality. The two
audit different substrates and hand code-owned vs design-owned findings to each other rather than
duplicating work.

## 0. Two layers, and what actually runs here

**Doctrine (this file)** ports 1:1 to any Figma file. **The gate does not** — a project without one
still runs the loop, just leaning harder on judgement (design-tweaker) instead of mechanical
auto-fix. Before promising anything, state which tier this project can reach:

| Tier | Needs | Gives |
|---|---|---|
| **T0 — loop only** | a Figma file + `design-tweaker` | the sequence, the dimension catalog as a manual checklist, named terminal states, the triage rule. Every finding comes from screenshot + judgement. |
| **T1 — mechanical gate** | project's own audit functions (token/scale, instance-ratio, spacing, copy) | 3a becomes automatic and objective; real defects auto-fix without a human reading every screen. |
| **T2 — registry + cross-screen** | a screen↔node-id↔flow-tier registry + a shared-master verification helper | 3c (cross-screen drift) becomes checkable flow-wide instead of screen-by-screen guesswork. |
| **T3 — decision library** | a recorded ledger of intentional exceptions ("don't fix these") | 3d triage separates real defects from deliberate design choices instead of auto-fixing both. |

**A project without a gate stops at T0 — that is the correct outcome, not a failure.** Say so
explicitly. The failure mode is skipping the craft pass because the mechanical layer felt like
enough (see the convergence precondition, §6).

## 1. Overlay — propose-first, never guess

The overlay is project data; inventing it produces confident nonsense (a copy register guessed
from vibes will flag the product's own house style as a violation). If the project has no overlay:

**Stop and propose one from `reference/config-template.json`.** Do not fabricate gate-function
names, component names, or node IDs. Ask for what only the human knows: which DS/Figma file, which
tier (§0) this project is on, which components carry navigation/footer/form semantics, and whether
the product has more than one brand/experience sharing this design system.

The overlay declares, at minimum:

- `designSystem` — the Figma file(s), the DS page(s) that hold canonical masters.
- `gate` — whether a T1 mechanical gate exists, and where its functions live. **Never re-implement
  a project's gate here** — call it.
- `registry` — screen ↔ node-id ↔ flow map (T2). Without it, cross-screen checks are manual.
- `decisionLibrary` — the ledger of intentional exceptions (T3), or explicitly none.
- `components` — nav/footer/field/step component names, so the generic cross-screen checks (§3c)
  know what to look for in *this* DS.
- `experiences` — if the product has sibling brands/products sharing this file (e.g. an internal
  tool + a customer-facing app), each with its own chrome/nav rules and copy register.
- `copy` — pointer to the project's UX-writing canon (register-by-audience, acronyms, ghost terms).
- `convergence` — `maxIterations` (default 3) and the hard ceiling (default 8), if the project
  wants different numbers than the default.
- `scopeGuard` — a one-line statement of what this loop must NOT invent (typically: DS-only, no
  new component/variant without a separate proposal).

## 2. The loop

0. **SETUP** — name the flow and every screen's node id from the registry (T2) or by hand (T0/T1).
   Baseline screenshot of each screen. Read the project's overlay and any accumulated
   pattern-library/playbook before working from memory.
   **Re-run on a flow that already has entries:** `decisionLibrary` LEAVE entries and a prior
   `converged` declaration (§6) are both calls written as fact-on-the-day, never re-checked. While
   reading the overlay, spot-check each LEAVE entry that applies to a screen in THIS flow against
   its current screenshot — does the exception still hold, or did the DS evolve past it since it
   was recorded? A LEAVE that no longer matches → flag it in TRIAGE (§4) as "open judgement call,
   re-ask" instead of silently re-applying it. Same for a prior `converged`: if this run exists at
   all, something regressed or grew — note in the overlay whether the earlier convergence held
   until now or broke quietly (no fix needed, just the correction on record for the next reader).
1. **AUDIT (per screen + cross-screen)** — three layers (§3):
   - **3a Mechanical** (auto, T1) — run the project's gate per screen. Pass = all counts zero /
     `pass:true`. **T0: skip; findings come from 3b instead.**
   - **3b Visual** (screenshot + judgement, every tier) — the dimension catalog (§3), scored by
     severity. **Deep pass:** `design-toolkit:design-tweaker`, run **at least once per flow**
     before declaring convergence — clean mechanics are not craft (§6 precondition).
   - **3c Cross-screen** (T2 sharpens this, but doable manually at T0/T1) — instance drift, nav
     active-state, chrome consistency, padding/CTA sizing, mobile↔desktop parity, layout-archetype
     consistency across siblings of the same screen type.
   - Produce a findings ledger: `{screen, lens, severity, finding, fix, impact, effort, confidence}`.
2. **TRIAGE (§4)** — split auto-fix (mechanical + structural cross-screen, **after** the decision-
   library check at T3) vs propose (visual). Rank visual findings by impact×effort. A structural
   finding (wrong layout archetype) is a STOP, not an auto-fix — decide the archetype with the user
   first.
3. **FIX** — auto-fix mechanical/structural findings (master-first; re-verify shared instances;
   clear stale overrides). Present visual proposals with rationale; apply on confirmation. DS-only
   — a fix that needs a new component/variant is a separate proposal, not a quiet addition.
4. **RE-AUDIT** — re-run the mechanical layer on touched screens (if T1) + fresh screenshots;
   confirm no regressions. Loop back to 1 if new findings surfaced.
5. **CONVERGE** (§6) — explicit `max_iterations` + four named terminal states.

## 3. Dimension catalog

### 3a. Mechanical (T1 — project gate, instance-opaque)

Whatever the project's gate checks — typically token/scale compliance, instance-ratio, spacing/
padding compounding, copy hygiene (placeholders, casing, retired terms), and any project-specific
extra rules. **Never hand-reconstruct a gate's checklist from memory** — call the gate, or read its
manifest, so a shrinking check-set isn't mistaken for a clean pass (a recurring failure mode: see
the reference implementation's "gate discipline" lesson — never trade completeness of the check set
for speed; split work by screen, never by check).

### 3b. Visual (screenshot + structural read — every tier)

**Two depths — pick per flow:**
- **Default (inline, cheap, every screen):** the lenses below — a fast sweep from a screenshot.
- **Deep (`design-toolkit:design-tweaker`):** run when the flow is new/rough, the user asks for a
  thorough pass, or the inline read is ambiguous ("something's off, can't say what"). Gives
  reference-grounding, a structural-vs-cosmetic split (structural = STOP, §4), and panel-mode
  agreement across lenses as a confidence signal. Feed it real screenshots + this DS's tokens/
  components so it grounds in *this* system, not generic taste. Run it **at least once per flow**
  — never skip it just because the mechanical layer is clean (§6).

Lenses (severity: **BLOCKER** / **MAJOR** / **MINOR** / **NIT** — see §4 for how each is handled):

0. **Job & context** (check first, most often skipped) — what is this screen *for*, and in what
   state/context does it render? Does the chrome match the auth/role/funnel state (e.g. a
   post-login screen showing pre-login chrome, or an anonymous funnel screen carrying a
   personalized user-menu, is a context mismatch no pixel check will catch).
1. **Hierarchy** — does the eye land on the title and the primary action first? At most one
   dominant primary CTA per screen (a Back/Next pair is the standard exception). Text-style ladder
   reads top-to-bottom (display → heading → label → body → caption), not "everything body/md".
2. **Spacing rhythm and density** — a token/scale check catches off-scale values, not an
   inconsistent *choice* among valid ones. Look for uneven gaps between sibling sections, density
   mismatched to context (a dense table reading like a form, or vice versa).
3. **Alignment and measure** — sibling sections' left edges line up; content width and primary-CTA
   width follow the project's measure convention; no orphaned or misaligned element; icon+text
   pairs are optically centered.
4. **Look & feel / craft** — empty/loading/error states exist; restraint reads as premium, not
   bare. Any project-specific "always branded" element (an AI/assistant surface, a signature
   pattern) carries its required visual marker consistently.
5. **AI-slop / genericness** — design-tweaker's two tests: "would someone say this was made by AI?"
   and "does this screen look different from its siblings?". Three or more tells (identical cards,
   gradient text, a generic side-stripe, an unbranded gradient, a reflex font) trigger a structural
   diagnosis (bad architecture vs bad execution) — structural is a STOP; cosmetic goes to the
   ranking.
6. **A11y (visual)** — focus ring visible on every interactive element; state never carried by
   color alone; contrast holds on tinted surfaces; touch targets ≥44px; icon-only controls carry a
   label/tooltip.
7. **Copy / register** — register-by-audience, canonical terminology, tone, per the project's
   UX-writing canon. A copy gate (if the project has one) is only the floor.

**Domain-specific pattern languages** (e.g. dashboards, wizards, data tables) often have their own
rules a generic lens catalog won't encode — declare them in the overlay as additional numbered
lenses rather than inventing generic-sounding rules here that are really one product's convention.

### 3c. Cross-screen (flow-level)

The most common invisible drift — check across every screen in the flow at once, not screen by
screen:

- **Instance consistency** — the same shared component renders identically on every screen; a
  verification helper against the master catches stale per-instance overrides.
- **Container/padding consistency** — uniform page padding and content width between sibling
  screens.
- **CTA sizing consistency** — a project's desktop-vs-mobile CTA-sizing convention holds on every
  screen of the flow, not just the one it was designed on.
- **Mobile↔desktop parity** — same content and components when both exist; desktop is a responsive
  re-layout, not a redesign. A deliberate, documented difference is fine; an undocumented one is a
  build artifact.
- **Layout-archetype consistency** — screens of the same role (e.g. every variant of a "home"/
  "list" screen) share the same column skeleton; a divergence is usually a build artifact, not a
  deliberate choice, and counts as structural (§4 STOP).
- **Navigation active-state** — every screen sets the correct active item in its nav/tab
  component, per the project's IA (declare nav components in the overlay, §1).

## 4. Triage — the gate flags, the decision library adjudicates (T3)

A mechanical gate knows geometry, tokens and types — not intent. Route every 3a finding through the
project's decision library (if one exists) before fixing:

1. **Real defect → FIX** (§5).
2. **Intentional exception → LEAVE** (a recorded "don't fix this" — a bespoke layout, a raw
   composite the DS deliberately doesn't componentize). Fixing it breaks the concept it protects.
3. **Open judgement call → ASK** — no recorded precedent, or conflicting ones.

At T0/T1 (no decision library yet), do this by asking rather than guessing — the first project this
happens on is exactly when the library starts getting written.

## 5. Fix rules (auto vs propose)

- **Mechanical (3a, post-triage) + structural cross-screen (3c: active-state, chrome, instance
  drift) → AUTO-FIX.** Fix, then re-audit the touched screens. No need to ask. Bind
  colors/tokens/borders by the node's *role*, never in bulk by color — a bulk re-bind by matched
  color is exactly how a fix inverts a hierarchy it didn't mean to touch.
- **Visual (3b: hierarchy/rhythm/alignment/craft/slop/copy-register) → PROPOSE.** Rank
  impact×effort, present with rationale (and a reference when the complaint is "generic/not
  premium"). Apply on confirmation. A structural finding (wrong layout archetype) is a STOP —
  decide the archetype with the user before touching anything.
- **Master-first** — a fix that could land on the shared master lands on the master, never on an
  instance. Verify shared instances and clear stale overrides after any master change.
- **DS-only** — fixes use existing components/variants. A fix that needs a new one is a separate
  proposal with its own definition-of-done, not something folded in quietly.
- A failed iteration gets undone in Figma before the next attempt — never layer a new pass on an
  inconsistent state left by a previous one.

## 6. Convergence

Explicit `max_iterations` (project default, typically 3 rounds of audit→fix→re-audit) and a hard
ceiling (typically 8) above which the loop always ends `max_iterations_reached` regardless of
requests for "one more round" — raising the ceiling is a decision on the record, not silent
continuation.

Four terminal states, reported **by name**, never inferred from the tone of the last round (an
unnamed "didn't quite converge" is indistinguishable from `converged` — the same failure class as a
gate that goes quiet instead of failing loud):

1. **`converged`** — the mechanical layer is clean (if T1) **and** the craft pass has run **and**
   two consecutive rounds surfaced nothing ≥ MAJOR (loop-until-dry; NITs don't reset the counter).
2. **`max_iterations_reached`** — the ceiling was hit without meeting (1). Report the round it
   stopped at and what remains, with severity. **This is not `converged`**, even if the last round
   looked clean — without two dry rounds there's no evidence of convergence, only a lack of time to
   find the next issue.
3. **`failed`** — the loop mechanism itself broke (a dead gate function, an unreachable node, a
   baseline that wouldn't load) — an instrument failure, not a large finding count.
4. **`interrupted`** — the user stopped, or the session ended mid-round.

**Precondition on `converged` (the one lesson every reference run re-learned the hard way):** never
declare it before the craft pass (design-tweaker, or a deliberate human look at lenses 4/5) has run
at least once. A flow can be 100% mechanically clean and still be craft-poor — that combination is
exactly what "converged" must not describe.

Don't stop mid-round on an unresolved BLOCKER — fix it or name it explicitly as a decision the user
needs to make. That's a gate inside a round, not a fifth terminal state.

## 7. Self-improvement (the point)

Two feedback sources, both written down:

1. **During the loop** — when the user rejects or edits a proposed visual fix, capture
   `{finding, proposed fix, verdict, reason}`. The reason is a candidate heuristic: "don't propose
   X in context Y" (an anti-pattern) or "in this DS, X is done like Z" (a threshold refinement).
2. **At close-out (retro)** — promote: a fix pattern repeated ≥2× → the project's pattern library; a
   recurring finding a mechanical check *could* catch → propose a new gate function (moves 3b→3a,
   a permanent loop upgrade, not a one-off); a new judgement call → the decision library; a new
   gotcha → the project's notes; log the round in a tuning log.

## 8. Synergy map

- `design-toolkit:design-tweaker` — **owns the craft pass** (§2 step 1, §6 precondition). Delegate;
  never reimplement its lenses here.
- `design-toolkit:code-design-audit` — the built-prototype counterpart. Hand it code-owned findings
  (a fix the design file can't express); take back design-owned findings it surfaces about the
  design file. Keep **one** overlay shape where a project runs both (component names, brand rules).
- `figma-design-workflow` — owns the *first build* of a screen (component-first methodology,
  pre-flight). This loop runs *after* a flow exists, not instead of building it correctly the first
  time.
- `figma-accessibility` — WCAG/ARIA spec reference for lens 6 when a deeper a11y read is needed.
- `figma-ds-tools` — a one-off drift sweep (hardcoded values → tokens) outside a flow-level loop;
  call it instead of this skill when there's no flow context, just a token audit.
- `obsidian-toolkit:obsidian-kanban` — deferred findings become cards, with severity and reason.
- `workflow-toolkit:session-retro` — where new heuristics get promoted (§7).

## 9. Engine distribution (deliberately not shipped yet)

The mechanical gate (dispatcher + check functions) is project-specific by nature — token names,
component names and node IDs differ per DS. It is **not** vendored into this plugin: a project
without one runs T0 and says so. When a second project's gate turns out to share real structure
with the reference implementation's, extract the shared shape into this plugin as an optional
`reference/gate-template.md`; don't generalize from a single instance.

Two check classes from the reference implementation are irreducibly project-specific and must
**not** be copied blind into a new project's gate: an iteration-phase check (a screen tagged for a
later release still importing that release's chrome) and a multi-brand/experience check (chrome
belonging to one sibling brand leaking into another's screens). Both encode one product's release-
phase or multi-brand model — the *concept* (declare an axis, gate on it) generalizes; the specific
values don't.

## 10. Definition of Done

Terminal state named per §6 + a ledger reported (fixed / proposed / deferred, with severity) + the
tier stated (§0) + any new heuristic promoted into the project's pattern library and, if
project-agnostic, back into this file (§7).

## 11. Self-improvement (this file)

Promote back here anything that is **not about one product**: a new lens, a new terminal-state
lesson, a better triage rule, a new synergy. Keep component names, node IDs, brand rules and dated
incidents in the product repo's overlay/playbook. A lesson arriving without a measurement (a
before/after, a count of how often it recurred) is a preference, not an invariant — say so before
folding it in.
