---
name: figma-design-workflow
description: Universal methodology for building screens in Figma with any design system. Load this skill before designing screens, layouts, or UI elements in Figma. Covers component-first decision tree, pre-flight audit, variable binding, and common pitfalls — file-agnostic.
---

# figma-design-workflow — Universal Design Methodology

Methodological rules for building screens in Figma, independent of file and design system.
Use together with `figma-console` (MCP mechanics) or `figma-cli` (JSX render).

## When to load
- Designing a new screen, layout, or UI element in Figma
- Starting work on a new Figma file (cataloging components, tokens, conventions)
- Need a decision framework for "build new vs reuse existing"
- Always load this alongside `figma-console` or `figma-cli` when designing

## First decision — which tool to use

Before doing anything, pick the execution path. **Don't funnel everything through `figma_execute`** — it's the slowest, most timeout-prone path (hardcoded ~5 s budget; see `figma-console` → "Performance & the timeout budget — READ FIRST").

| Signal | Tool | Skill |
|---|---|---|
| New screen/component from JSX, shadcn/tailwind tokens, UI block | **figma-cli** | `figma-design-toolkit:figma-cli` |
| Read design context / screenshot for code / generate-from-intent / FigJam | **official Figma MCP** (Dev Mode, `localhost:3845`, has write) | `figma:figma-use` (external) |
| Variants, programmatic variable binding, multi-page ops, batch tokens, DS audit/parity, prototype reactions | **figma-console** (`figma_execute`, small scripts) | `figma-design-toolkit:figma-console` |
| **No Desktop Bridge** (phone, Claude Code on the web, cloud/restricted env) | **official remote MCP** `mcp.figma.com` (headless write) | `figma-design-toolkit:figma-cloud` |

- **Greenfield** (build new from scratch) → figma-cli.
- **Assembling from an existing DS** (instantiate components, set variants, wire prototype reactions) → figma-console; this can't move to JSX render — just keep each call small.
- Both MCP servers can run at once — split read/codegen (official Figma MCP) from DS/variant work (figma-console).
- **Cloud / headless** (no Figma Desktop): figma-cli and figma-console are unavailable; this methodology still applies, but execute through `figma-cloud` (remote MCP). The decision tree, pre-flight audit and token rules below are path-agnostic.

---

## Session start — before first figma_execute

Every script must start with `await figma.loadAllPagesAsync()`. Without it, `getNodeByIdAsync`
returns `null` for nodes on non-first pages — silent failure with no error.

Node IDs are **stale between conversations** — always re-search at session start:
- `figma_search_components({ query: 'Button', limit: 10 })` before referencing any component
- Never reuse IDs from memory/previous sessions without re-querying

**For new projects:** Before the first design session, check what's new in the Plugin API:
```
WebFetch("https://developers.figma.com/docs/plugins/api/")
```
Known additions since 2024 not in training data:
- `SlotNode` + `componentNode.createSlot()` — flexible content areas in components
- `TableNode` + `figma.createTable(rows, cols)` — native tables (avoid frame-grid workarounds)
- Variables API v2 — `figma.variables.*` COLOR/FLOAT/STRING/BOOLEAN with `setBoundVariable`
- `figma.getLocalTextStylesAsync()` / `getLocalPaintStylesAsync()` — prefer async over sync

---

## ABSOLUTE RULE: Never detach component instances

> **`detachInstance()` is forbidden.** No exceptions.
>
> Detach destroys the link to the DS component — variants, variable binding, and future
> updates stop working. There is no scenario where detach is "the only option" — there is
> always an alternative. If something seems impossible without detach, read the
> "Text and overrides on instances — without detach" in `reference/screen-build.md`.

---

## Before creating a new component — mandatory pre-flight

Run this pipeline BEFORE building any new component. Skip = risk of duplicate.

### Step 0a: Check the component catalog

If `docs/design-system/components.md` exists in the project → **read the relevant section before any Figma search.**

The catalog answers "which component for this use case" without API calls. If the component is listed there: use its Figma search query to find it (skip to Step 1 with that exact query), or skip directly to building if you already know the nodeId.

If not in catalog: continue with Step 0b.

### Step 0b: Mobbin research (for any new component type)

```
mcp__mobbin__search_screens(query="[UX problem, not component name]", mode="deep", limit=12)
```
- Query describes the problem the component solves: "multi-step progress indicator with labels" not "ProgressSteps"
- Pick 2-3 references from mature products
- Show user briefly ("I see X at Linear, Y at Notion") → agree on direction BEFORE building

### Step 1: Broad semantic search in DS

```javascript
figma_search_components({ query: "semantic term", limit: 20 })
figma_search_components({ query: "synonym / variant term", limit: 20 })
figma_search_components({ category: "category", limit: 20 })
```
Search by MEANING, not exact name. "steps" finds "ProgressSteps". "stepper" and "wizard" also find it.

### Step 2: Screenshot candidates

```
figma_capture_screenshot({ nodeId: "CANDIDATE_NODE_ID" })
```
For each candidate: does modifying it cover ≥70% of the new use case?

### Step 3: Decision

```
≥70% visual/functional overlap → EXTEND existing (add variant, prop, mode)
                                  NEVER create a separate component

<70% overlap, no semantic match → Create new, BUT:
  a) Place inside the correct DS section (see "DS page — canonical structure" in `reference/screen-build.md`)
  b) Resize the section after adding
  c) Never place on bare canvas
```

> Anti-pattern: creating `ProgressStepsWizard` when `ProgressSteps` exists and needed only a new variant/prop.
> New components create DS debt. Always prefer extension.

---

## Decision tree — BEFORE building anything

Every UI element must go through this process:

```
1. Does a component exist in the file that FITS this element?
   → YES → importComponentByKeyAsync(key) + createInstance()
            [if local/unpublished → getNodeByIdAsync(nodeId).createInstance()]

2. Does a component exist that ALMOST fits?
   (different context, similar look, different content)
   → YES → createInstance()
            + setProperties() for variants / icon visibility
            + findOne(TEXT).characters for content (see reference/screen-build.md)
            NEVER: detachInstance() — preserve the component link
            CONSIDER: adding a variant/prop to the existing component
                      instead of building a parallel one

3. No component fits?
   → Build ONLY with design tokens:
      - colors: bind variables (setBoundVariableForPaint), NOT hardcoded hex/RGB
      - typography: text styles via setTextStyleIdAsync, NOT manual font+size
      - spacing: bind FLOAT variables via setBoundVariable, NOT hardcoded px
      - radius: bind FLOAT variables via setBoundVariable, NOT hardcoded px
      - content areas: use `createSlot()` NOT `createFrame()` — see below
```

> Never start with `createRectangle()` + `createText()` without going through the tree above.
> Building from raw shapes bypasses the entire design system — hardcoded colors, inconsistent typography,
> token changes don't propagate.

### Content slots in new components — use `createSlot()` not `createFrame()`

When a new DS component has a **flexible content area** (Accordion body, Card body, Modal content, list container), the area **must be a `SLOT` node**, not a plain frame.

**Why it matters:** `appendChild()` on a plain `FRAME` inside an instance throws `"Cannot move node. New parent is an instance or is inside of an instance"`. A `SLOT` node allows free-form `appendChild()` in instances — that's the entire point of the API.

```javascript
// In the component (DS):
const slot = componentNode.createSlot();   // returns SlotNode (type === 'SLOT')
slot.name = 'Content';
slot.layoutMode = 'VERTICAL';
slot.layoutSizingHorizontal = 'FILL';
slot.layoutSizingVertical = 'HUG';
slot.fills = [];
// For a variant where the slot should be hidden (e.g. Closed state):
slot.visible = false;

// In an instance (screen):
const slot = instance.findOne(n => n.type === 'SLOT');
const child = someVariant.createInstance();
slot.appendChild(child);          // works — SLOT accepts appendChild in instances
child.layoutSizingHorizontal = 'FILL';

// Reset to component default:
slot.resetSlot();
```

`createSlot()` is available on `ComponentNode` (individual variants), not on `ComponentSet`. Each variant in a set gets its own slot.

⚠️ **Side effect when adding defaults to SLOT at component level:** Figma may silently remove
children from OTHER slots in existing instances of that component. Mechanism: Figma "re-resolves"
slot overrides when the component's default content changes.

**Rule:** Before adding defaults to any SLOT in a component, snapshot all instances:
```javascript
const instances = figma.currentPage.findAll(n => n.type === 'INSTANCE');
const before = instances
  .filter(i => i.mainComponent?.parent?.id === 'YOUR_COMPSET_ID')
  .map(inst => ({
    instId: inst.id,
    slots: inst.findAll(n => n.type === 'SLOT').map(s => ({
      slotId: s.id, children: s.children.map(c => c.id)
    }))
  }));
return before; // Save, then do component modification, then compare
```

---

## Reference files — load on demand, not up front

This skill keeps the always-true parts above and below. Everything else lives in `reference/` and is
read **only when the task reaches it** — read the file with the Read tool at that moment.

| File | Read it when |
|---|---|
| `reference/runtime-gotchas.md` | Before writing / while debugging Plugin API code — variants, COMPONENT_SET, clone, append, resize, timeouts. Includes the full common-mistakes table. |
| `reference/screen-build.md` | Building a new screen or page: pre-flight discovery, text/fill overrides without detach, page template, instance layout, DS-page section structure, creating a missing icon. |
| `reference/tokens-and-styles.md` | Planning a variable collection, creating/binding text styles, binding color or FLOAT (spacing/radius) variables. |
| `reference/audits.md` | Running the token-compliance audit, the instance-ratio audit, or cataloging a new design system. |
| `reference/ux-writing.md` | The screen has copy — capitalization by surface, CTA/helper/error rules, register by audience, terminology. |

> Copy is part of the design system, not an afterthought — when a screen has strings, read
> `reference/ux-writing.md` before writing them, and the project's
> `docs/design-system/01-foundations/ux-writing.md` for its glossary and registers.

---

## Gotchas index — know these exist, look up the detail

Each of these fails **silently** (no error, wrong result). Full explanation + fix for every line:
`reference/runtime-gotchas.md`.

- `loadFontAsync` — parallelize with `Promise.all`; always load before touching `characters`.
- `setProperties(Variant)` **resets all text overrides** → set variant first, text after.
- `combineAsVariants` → set `layoutMode = 'NONE'` immediately, or manual x/y is ignored.
- A new property on a COMPONENT_SET needs **every** variant combination, or props show "?".
- `clone()` drops `componentPropertyReferences` (TEXT too) and can drop a nested child.
- Inconsistent variant property keys → "Component set has existing errors"; normalize all names.
- New nodes inherit the **last-used paint** — clear or bind `fills`/`strokes` explicitly.
- A flipped SECTION (`scaleY=-1`) renders new children inverted; `.rotation` still reports 0.
- `figma_arrange_component_set` is **destructive** (clones the set) — never use it.
- `width` / `height` **are** bindable to FLOAT variables.
- `figma_execute` is **not transactional** — partial nodes survive a timeout; keep scripts small,
  never `findAll` over a whole page/document.
- Node references go **stale** after `appendChild` / `setProperties` — re-query.
- `layoutSizingVertical = 'HUG'` only works **after** `appendChild`.
- `resize()` is a no-op on nested instance nodes — use layout sizing modes.
- Spacing variables: map by **resolved px value**, never by name (`spacing/16` is often 64px).
- A text style sets typography only — the fill stays unbound black; bind it separately.

---
## Post-build quality checklist

Run after completing every screen or component. Check each item before declaring done.

**Definition of done — GATE (hard).** Before you say "done" / "gotowe" / "fixed" about a screen or component:
run `gateScreen(<id>)` from the project `figma-build-kit.md` (token + instance-ratio + padding + fixed100 +
copy) and **paste the returned JSON** — `pass:true` is required. `pass:false` = not done, fix per the fields
(`token.issues` / `fixed100.issues` / `padding.issues` / `copy.issues` / `ratio.violations`). Proof = the JSON,
not words and not a screenshot. (No build-kit in the project yet? Run the audits from `reference/audits.md`, or
scaffold via `figma-ds-init`.) This enforces the cross-project rule "no done without proof".

**Inspect-before-mutate.** Before hide/swap/delete/setText on an existing instance, read its children
(`kids(node)`) and target by `find(c => c.name === …)` / type — NEVER by positional index (real bug: hid a
Switch instead of an Input on assumed child order).

**verifyInstances** (separate, after any structural fix): confirms instances didn't accumulate stale
`primaryAxisAlignItems` / `itemSpacing` / sizing overrides — screenshots can't see this.

```
STRUCTURE
□ Every visible UI element = INSTANCE of DS component (not raw FRAME/RECT/GROUP)
  Audit: figma.currentPage.findAll(n => ['FRAME','RECTANGLE','GROUP'].includes(n.type)
         && n.parent?.type !== 'INSTANCE' && n.parent?.type !== 'SECTION')
□ All auto-layout frames have descriptive names (not "Frame 123", "Group 7")
□ No orphan nodes outside sections (DS page) or outside screen frames (screen pages)
□ New DS components placed in correct section; section resized after adding
□ After adding default content to a SLOT at component level → snapshot-check existing instances for lost children
□ No buildX() helper functions in scripts — helpers mask component duplication; use figma_execute per component, never a local helper that creates nodes

TOKENS
□ Zero hardcoded fills — only setBoundVariableForPaint()
□ Zero hardcoded typography — only setTextStyleIdAsync() (never fontSize/fontFamily/fontWeight manually)
□ Spacing/padding/gap/radius bound to FLOAT variables via setBoundVariable()

SIZING
□ Each instance: verify inst.width/inst.height after appendChild matches design spec
  (if different → set layoutSizingVertical + resize explicitly)
□ layoutSizingH/V = 'FILL'/'HUG' set AFTER appendChild (not before)

DOCUMENTATION
□ New DS component created → add entry to docs/design-system/components.md immediately
□ Discovered new usage nuance → update the relevant entry ("Kiedy"/"Nie używaj gdy")
□ Component renamed or restructured → sync the entry
```

---
## Relation to other skills

### Desktop Bridge path (preferred — faster, local)
| Skill | Role |
|-------|------|
| `figma-design-toolkit:figma-design-workflow` (this) | **Methodology** — decision tree, pre-flight, code patterns |
| `figma-design-toolkit:figma-console` | **Desktop mechanics** — figma_execute, error recovery, placement |
| `figma-design-toolkit:figma-cli` | **CLI** — JSX render, shadcn tokens, faster than MCP |

Load both when designing screens: `/figma-design-toolkit:figma-design-workflow` + `/figma-design-toolkit:figma-console`

### Cloud path (fallback — when Desktop Bridge unavailable)
| Skill | Role |
|-------|------|
| `figma:figma-use` | Plugin API prerequisite for cloud write ops |
| `figma:figma-generate-design` | Code/description → Figma screen (cloud) |
| `figma:figma-generate-library` | Design system from code (cloud) |
| `figma:figma-code-connect` | Map Figma components ↔ code components |

> This skill (`figma-design-workflow`) is path-agnostic — the decision tree methodology
> and pre-flight audit apply to both Desktop Bridge and Cloud path.
