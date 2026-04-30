---
name: ux-tweaker
description: >
  Diagnostic layer for existing UI. Use when something feels wrong, generic,
  boring, or AI-made — but you're not sure what exactly or what to do about it.
  Scans the project's design system, names anti-patterns, diagnoses whether
  the layout problem is structural or cosmetic, proposes archetype alternatives,
  then routes to the right tool. Does NOT fix things itself — diagnoses and
  delegates. Triggers on: "something feels off", "looks like AI", "boring",
  "generic", "too templated", "what's wrong with this", /diagnose, /check.
  For execution after diagnosis → impeccable. For greenfield → frontend-design
  or taste-skill.
---

# UX Tweaker — Diagnostic Layer

**This skill diagnoses. It does not fix.**

Three-skill division of labor:
- **ux-tweaker** → something's wrong, figure out what and where
- **impeccable** → execute the fix (`/impeccable typeset`, `/impeccable bolder`, etc.)
- **taste-skill** → build new UI from scratch with strong aesthetic opinion
- **frontend-design** → greenfield, no constraints

---

## Flow

```
INTAKE → SYSTEM SCAN → ANTI-PATTERN SCAN → LAYOUT DIAGNOSIS → PRESCRIPTION
```

After impeccable runs → come back for **AI Slop Verification**.

---

## Step 1 — Intake

Skip if the message already answers both questions.

**Q1:** What are you showing me? (screenshot / file path / description)
**Q2:** What feels wrong?

| Complaint | Likely path |
|---|---|
| "Looks generic / AI-made / boring / templated" | Layout Diagnosis → structural |
| "Something's off, can't name it" | Anti-Pattern Scan → Prescription |
| "Font / color / spacing specifically" | Anti-Pattern Scan → `/impeccable typeset\|colorize\|layout` |
| "Too loud / cluttered" | → `/impeccable quieter` or `/impeccable distill` |
| "Timid / lacks personality" | Layout Diagnosis → bolder archetype → `/impeccable bolder` |
| "Final pass before ship" | → `/impeccable polish` |
| "Build something new" | → taste-skill or frontend-design |

---

## Step 2 — Design System Scan

**Before naming any problems, understand the constraints.** Changes that ignore existing tokens create new inconsistencies.

Scan in this order:
1. `CLAUDE.md` (root) — styling conventions, token constants, font stack
2. `DESIGN.md` — if impeccable is set up, read this; it's the ground truth
3. `tailwind.config.*`, global CSS, `src/styles/**`
4. Main component files — tokens sometimes live as JS `const` blocks (e.g. `NAVY`, `SKY`, `ORANGE` at top of a file), not in config
5. `src/components/**` — list existing primitives

Report one of three states:
- **System exists** → list tokens and components; these are constraints for any fix
- **Partial** → list what's there and what's missing; missing parts are where inconsistency lives
- **None** → flag: run `/impeccable document` first to generate DESIGN.md, then return

---

## Step 3 — Anti-Pattern Scan

Name every hit. Do not propose fixes here — that's impeccable's job.

**AI tells (highest signal)**
- Side-stripe border — thick `border-left/right` colored accent
- Gradient text — `background-clip: text` with gradient
- Hero metric layout — big number + small label + stats + gradient
- Identical card grid — icon + heading + body × N
- AI color palette — purple/violet gradients, cyan-on-dark, neon
- Everything center-aligned — hero + body + CTAs all centered
- Reflex font — Inter, Roboto, DM Sans, Space Grotesk, Outfit

**Layout**
- Nested cards
- Monotonous spacing — same gap/padding everywhere
- Line length > 75ch on body
- Wrapping everything in a container that doesn't need one

**Typography**
- Flat hierarchy — font sizes < 1.25× ratio between levels
- Icon tile above every card heading
- Single font family, no weight/size contrast

**Color**
- Gray text on colored background
- Pure `#000` / `#fff` as large surfaces

**Accessibility (design layer)**
- Contrast — body text < 4.5:1 against background (WCAG AA); large text/UI components < 3:1
- Color as sole state indicator — error, disabled, active states communicated only by color (no icon, no text label, no pattern)
- Focus ring — `:focus-visible` invisible or contrast < 3:1 against adjacent background; technically present but visually imperceptible
- Touch targets — interactive elements visually < 44×44px; buttons/links cramped with < 8px spacing between them

**Code-level**
- `outline-none` without `:focus-visible` replacement
- `transition: all`
- Icon buttons without `aria-label`
- `<div onClick>` instead of `<button>`
- `font-size < 16px` on form inputs (iOS auto-zoom)

---

## Step 4 — Layout Diagnosis

Run when: user mentioned "boring / generic / templated / AI-looking" OR Anti-Pattern Scan found 3+ AI tells.

**Do not suggest fixes until this step is complete.**

### Procedure

**1. Name the current archetype** — one concrete sentence:
- "3-column feature card grid with centered hero + metric row."
- "Vertical sections, each = heading + two columns, repeated 5×."
- "Full-bleed hero → alternating image/text rows → 3-up testimonials."

**2. Diagnose** — pick one, justify in one sentence:
- **STRUCTURAL** — wrong archetype for this content/brand. No amount of `/impeccable polish` will fix it.
- **COSMETIC** — archetype is fine, execution has template tells. Impeccable's refine commands are enough.

**3. If STRUCTURAL** → propose 2–3 alternatives from the Archetype Library below. For each:
- Name
- 2 sentences: what it does to this specific content, why it fits or clashes with the brand from Step 2
- One distinctive structural move (not a tweak)
- Honest "wrong when"

**Stop. Wait for pick. No code, no impeccable commands yet.**

**4. If COSMETIC** → go to Prescription.

### Anti-lipstick check
Before writing the Prescription, ask: *"Complaint was 'boring'. My prescription is only typeset + colorize with no archetype change. Is this lipstick on a pig?"* If yes — back to step 1.

---

## Step 5 — Prescription

Output format:

```
## What I found
[Anti-patterns, numbered, with location]

## Root cause
[Structural or cosmetic — one sentence]

## Recommended actions

1. [Problem] → /impeccable [command] [target]
   Context: [one sentence of specific context for that command]

2. [Problem] → /impeccable [command] [target]
   Context: ...

## Do first
[If design system is missing tokens or DESIGN.md doesn't exist:
 "Run /impeccable document before anything else — otherwise fixes won't be consistent."]

## Not worth fixing here
[Things that are P3 or stylistic — leave them]
```

Prescription rules:
- Every action maps to a specific impeccable command with context
- Order matters: token/system fixes before visual fixes
- If layout is structural: archetype pick comes BEFORE any impeccable command
- If impeccable isn't set up (no PRODUCT.md): recommend `/impeccable teach` first

---

## AI Slop Verification (after impeccable runs)

User comes back after running impeccable. Run this check:

> *"If someone saw this and immediately said 'AI made it' — would they be right?"*

**Yes** → still failed. Check which tells remain:
- Font still on reflex list?
- Category-reflex palette (e.g. "fintech → navy+gold", "SaaS → purple gradient")?
- Rounded cards + drop shadows everywhere?
- Same spacing value repeated?
- Everything still center-aligned?

Report remaining tells → suggest specific follow-up impeccable command.

**No** → done. Call `browser-verify`.

---

## Reference: Layout Archetype Library

### Editorial / magazine spread
Long-form reading. Body text is the hero.
- **Use:** opinion, explanation, publication feel
- **Avoid:** transactional, pricing, dashboards
- **Move:** 60ch reading column + metadata (date, author, tags) in left margin outside it

### Swiss grid
Oversized type as structure. Asymmetric but disciplined. Narrow palette.
- **Use:** gravitas, precision, confidence
- **Avoid:** playful / casual voice
- **Move:** one 120px+ display line anchored to grid; all body in a single column

### Brutalist
No decoration. Type and color do all work.
- **Use:** conviction-first brand, standing out
- **Avoid:** broad consumer, trust-sensitive
- **Move:** bold borders instead of buttons, intentional mono accents, zero rounding

### Oversized type as layout
Headline is the composition. Content flows around letterforms.
- **Use:** brand/marketing where the statement > the density
- **Avoid:** product surfaces, information density
- **Move:** headline at 40–60% viewport; supporting copy in one small precise block

### Cinematic hero
Full-bleed media + text. Sections below breathe widely.
- **Use:** strong photography/video; storytelling
- **Avoid:** no strong visuals; performance-critical
- **Move:** single large display cut over media; generous rhythm between sections

### Data-dense dashboard
Density is the feature. Bloomberg energy.
- **Use:** power users, ops/financial, real-time data
- **Avoid:** consumer onboarding, casual use
- **Move:** tabular layout, `tabular-nums`, 32–36px rows, color only for state changes

### Sidebar-driven
Left nav + content area. Documentation archetype.
- **Use:** deep structure, reference, multi-step workflows
- **Avoid:** marketing, short flows, mobile-first
- **Move:** persistent nav + 72ch content column + "on this page" right rail

### Diagonal / offset grid
Deliberate misalignment. Elements break the baseline.
- **Use:** energy without motion
- **Avoid:** trust-sensitive (finance, health)
- **Move:** every second section ±50px offset; one image overlaps two columns

### Manifesto / long-form
Single column. Large type. Pauses between thoughts.
- **Use:** about pages, brand statements
- **Avoid:** transactional, product pages
- **Move:** 55–65ch column; whitespace as dividers; pull quotes at 2× body

### Terminal / mechanical
Monospace + raw borders — deliberately, not as shorthand for "technical."
- **Use:** dev tools, retro-computing brand — only if the brand earns it
- **Avoid:** non-technical audience, or as a shortcut to look smart
- **Move:** single-pixel borders, block-cursor accent, mono for headings + body
