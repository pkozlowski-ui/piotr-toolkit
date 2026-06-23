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
> "Text and overrides on instances" section below.

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
  a) Place inside the correct DS section (see "DS page canonical structure" below)
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
            + findOne(TEXT).characters for content (see section below)
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

## Creating missing icons

When `figma_search_components({ query: 'icon-name' })` returns nothing:

1. Fetch SVG from the project's icon library (Lucide for most projects):
   `WebFetch("https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/<name>.svg")`
2. Extract the `d` attribute from the `<path>` element.
   ⚠️ Lucide uses lowercase arc commands (`a`) — Plugin API only supports uppercase commands.
   Arcs must be converted to cubic beziers or replaced with `figma.createEllipse()`.
3. Create a COMPONENT (not raw vector) in the correct DS icons section:

```javascript
const iconComp = figma.createComponent();
iconComp.name = 'Icon/name';
iconComp.resize(24, 24);
iconComp.fills = [];

const vector = figma.createVector();
vector.vectorPaths = [{ windingRule: 'NONE', data: 'M 12 2 L 22 21 L 2 21 Z' }]; // replace
vector.strokeWeight = 2;
vector.strokeCap = 'ROUND';
vector.strokeJoin = 'ROUND';
vector.fills = [];
// Bind stroke color to a token
const vars = await figma.variables.getLocalVariablesAsync();
const textVar = vars.find(v => v.name === 'text');
vector.strokes = [figma.variables.setBoundVariableForPaint(
  { type: 'SOLID', color: { r: 0.09, g: 0.12, b: 0.20 } }, 'color', textVar
)];
iconComp.appendChild(vector);
vector.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
```

4. Swap the icon in a Button/IconButton: `iconInstance.swapComponent(newIconComp)`
5. Add entry to docs/design-system/components.md under Icons section.

**NEVER:** embed icons as Unicode characters in text nodes (e.g. "SCHOOL ↕") — no token binding, no swap, no resize.

---

## Variable collection architecture — plan before building

Designing variable structure *after* components are built means retroactive rebinding — 3× more work.
Define collections, modes, and naming **before creating the first component**.

### Source-of-truth cascade pattern

```
brand (EduVista / ACME modes)   ← the single switcher
  ├── colors (navy, sky, orange, surface, tint, …)
  ├── font-sans / font-mono  (STRING → binds to Text Style fontFamily)
  ├── radius/*               (FLOAT → radius collection aliases these)
  └── spacing/*              (FLOAT → spacing collection aliases these)

radius collection  → all vars = VARIABLE_ALIAS → brand/radius/*  (1 mode only)
spacing collection → all vars = VARIABLE_ALIAS → brand/spacing/*  (1 mode only)
shadcn/semantic    → 6 tokens = VARIABLE_ALIAS → brand/*

// Switch everything at once:
figma.currentPage.setExplicitVariableModeForCollection(brandColl, acmeModeId)
// → cascades to radius + spacing + semantic automatically
```

### Rules

- **Alias, don't duplicate modes**: `radius` and `spacing` don't need their own brand modes — they alias `brand/*`. Adding modes per collection = manual sync debt.
- **STRING variable → fontFamily**: bind Text Style fontFamily to a STRING variable (`brand/font-sans`) via `style.setBoundVariable('fontFamily', stringVar)` — font switches with brand mode.
- **WCAG first**: check palette contrast ratios before building screens, not after. Lime/neon colors often fail on white (`#C8FF00` = 1.7:1 on white → WCAG fail).
- **Figma hard limit**: variables **cannot** drive component variant switches. Workaround for logo/wordmark: use a **boolean component property** + layer visibility, then bind that boolean property to a boolean variable — boolean component props *can* be bound, variant props *cannot*.

---

## Text Styles — rules

- Create Text Styles **simultaneously** with the first components — not retroactively.
- Bind `fontFamily` to `brand/font-sans` STRING variable for 1-click font theming.
- Pre-flight: audit existing styles before building a screen:

```javascript
const styles = await figma.getLocalTextStylesAsync();
return styles.map(s => ({ id: s.id, name: s.name, size: s.fontSize, weight: s.fontName.style }));
```

- Bind text nodes: **always async** — `await node.setTextStyleIdAsync(style.id)`.
- **⚠️ A text style sets typography ONLY — NOT fill color.** After `setTextStyleIdAsync` the node's
  `fills` stays its default solid black, **unbound** → a hardcoded-color violation that's easy to miss
  (the text looks fine, but the audit flags it). After applying the style, **bind the fill separately**:
  `node.fills = [figma.variables.setBoundVariableForPaint(node.fills[0] || {type:'SOLID',color:{r:0,g:0,b:0},opacity:1}, 'color', textColorVar)]`
  (e.g. `color/text/body` for default, `color/text/muted` for secondary). Wrap text creation in a helper
  (`txt(parent, styleName, chars, colorVar)`) so style + font-load + characters + fill-bind always happen together.

---

## Content / UX-writing — copy is PART of the design system

Every string you write IS a design-system decision — audit it like tokens, not as an afterthought. These are
UNIVERSAL rules (file-agnostic); the project's actual glossary, voice registers, and per-surface specifics live
in `docs/design-system/01-foundations/ux-writing.md` (scaffolded by `figma-ds-init`) — read it before writing copy.

**Capitalization by SURFACE (the one rule to internalize):** sentence case is the default. The only exceptions:
eyebrows + table-column headers (UPPERCASE *via style*, never typed caps) and proper nouns + formal data-field
labels (Title Case). Descriptive categories/filters are NOT proper nouns → sentence case (`Open seats only`, not
`Open Seats Only`; `Middle school`, not `Middle School`). Real proper nouns stay (`LaGuardia High School`).

**Buttons / CTAs:** verb-first, sentence case, no terminal period, **no glyph in the label** (icon = separate slot).
One base label per action across the flow (don't let "Save" wear five labels).

**Helpers / errors / descriptions:** helper = fragment→no period, full sentence→period, carry the *why* when stakes
are real; errors = full sentence + period, supportive (never blaming), name the fix; page descriptions = full
sentence. No placeholders ship (`Button`, `Helper text`, `Lorem`, `Description goes here` = pre-ship fail).

**Register by AUDIENCE, not by screen** — pick the voice from who reads it (define the project's registers in
`ux-writing.md`; typical split: internal/admin tooling = operational & scannable; consumer funnel = warm,
benefit-first, low-friction, plain/ESL; returning-user dashboard = status + next-action + "no action needed").
An **AI layer** is advisory (attribution → finding → action, hedged, never blocks, human decides); decide its
**brand exposure per audience** (often white-label / unbranded for end-users, branded for internal).

**Terminology = one canonical string per concept** (a glossary in `ux-writing.md`). Synonyms read as new concepts.
Watch for **ghost terms** (renamed/removed features still in copy) and **keys ≠ display** (typed enum/filter keys
live in code/types/fixtures — never rename them for copy; render a display label-map instead).

**Pre-flight + audit:** when the screen has copy, run `copyAudit()` from `figma-build-kit.md` (mechanical: Title-Case
CTAs, placeholders, year format, glyph-in-label, ghost terms) → `count:0` before done. For a new experience or a big
copy change, run the full **harvest → register → fix** playbook (see the project's `03-patterns/ux-writing-audit-playbook.md`).
`copyAudit` is mechanical only — register/tone is a human judgment against `ux-writing.md`.

---

## Critical Runtime Gotchas

### loadFontAsync — use Promise.all for multiple fonts

```javascript
// GOOD — parallel (2-3× faster)
await Promise.all([
  figma.loadFontAsync({ family: 'Inter', style: 'Regular' }),
  figma.loadFontAsync({ family: 'Inter', style: 'Medium' }),
  figma.loadFontAsync({ family: 'Inter', style: 'SemiBold' }),
]);
// BAD — sequential await calls (do not chain)
```

### setProperties(Variant) resets ALL text overrides

Changing a VARIANT property resets all text content back to component defaults.
**Always set variant first, then text:**

```javascript
inst.setProperties({ 'Type': 'Primary', 'Size': 'md' }); // variant FIRST
// Set text AFTER — anything set before variant change is lost
const labelKey = Object.keys(inst.componentProperties)
  .find(k => inst.componentProperties[k].type === 'TEXT');
if (labelKey) inst.setProperties({ [labelKey]: 'Save changes' });
```

### COMPONENT_SET: set layoutMode = 'NONE' before manual positioning

```javascript
const set = figma.combineAsVariants([v1, v2, v3], figma.currentPage);
set.layoutMode = 'NONE'; // MUST be set immediately — otherwise x/y on variants is ignored
v1.x = 0; v1.y = 0;
v2.x = 0; v2.y = v1.height + 40;
```

### COMPONENT_SET: new property requires ALL variant combinations

Adding a property `Size` (sm/md/lg) to a set already having `State × Type` (3×3 = 9)
means you need 27 variants for ALL combinations. Missing combinations → "?" in properties panel.
Plan the property space **before** building variants.

### clone() does NOT copy componentPropertyReferences

After `node.clone()`, the clone loses property bindings — both INSTANCE_SWAP **and** TEXT `characters`
refs (labels revert to defaults; `setProperties` on them silently no-ops). Rebind explicitly:
`textNode.componentPropertyReferences = { ...textNode.componentPropertyReferences, characters: 'Label#id' }`.
Two ordering rules when cloning a variant into a COMPONENT_SET: (1) **rename before append** — a clone keeps
the source's variant name → duplicate-variant conflict; (2) **set refs only after the clone is in the set** —
props don't resolve on an orphan ("Could not find a component property with name…"). Also observed: `clone()`
of a frame can silently **drop a nested child** — verify `clone.children` for critical structures.

### COMPONENT_SET with inconsistent variant props → "existing errors"

If some variants define a property others don't (e.g. half named `Size,Active`, half `Size,Active,Focus`),
`componentPropertyDefinitions` throws "Component set has existing errors" and you can't read or extend it.
**Repair:** normalize EVERY variant name to the same property keys (add the missing one, e.g. `, Focus=False`).
The error then clears and you can append new variants (e.g. a `Size=5` row) + new TEXT props (`addComponentProperty`).

### New nodes inherit the last-used paint

`createComponent` / `createRectangle` / new strokes can inherit the **last paint used in the Figma session**
(e.g. a leftover gradient stroke appears on a "plain" new component). Never assume a clean default — explicitly
set or clear right after creating (`node.strokes = []`, or bind a token). Token audits only flag SOLID paints,
so a stray GRADIENT stroke slips through — check `strokes[0].type` when something looks off.

### Flipped/rotated SECTION renders new children inverted

A SECTION with a flipped transform (`relativeTransform [[1,0,x],[0,-1,y]]`, scaleY=-1) makes newly-created
children render upside-down *in that section* (existing siblings compensate with their own scaleY=-1).
Instances placed in a normal frame are upright regardless. `node.rotation` reports `0` even when flipped —
inspect `relativeTransform`, not `.rotation`. **Prefer normalizing over compensating:** un-flip the section
(`sec.relativeTransform=[[1,0,0],[0,1,0]]`) AND every child that carried a compensating scaleY=-1
(`n.relativeTransform=[[sx,0,tx],[0,1,ty]]`), then build normally. Keep sections at abs (0,0) — negative-Y
sections also export mirrored PNGs. Audit: `figma-ds-tools` A5.

### figma_arrange_component_set is destructive — do NOT use

This tool **clones the entire component set** into a new "Component Container" doc-frame on the *currently
active page* (not the set's own page), creating a **duplicate master** with a fresh ID. The duplicate
pollutes the library and steals instances. Variants in a set are selected by **property, not position** —
a loose grid after `clone()`+`appendChild` is harmless and needs no "tidying". If you must arrange visually,
set `x/y` on variants by hand. (If already run: delete the cloned container, verify the original set's
variant count is intact, confirm instances still point at the original.)

### width / height ARE bindable to FLOAT variables

`node.setBoundVariable('width', floatVar)` works (also `'height'`) — tokenize panel/drawer/rail dimensions
instead of hardcoding (e.g. a `width/drawer` token), and binding at the component level propagates to instances.
⚠️ Guard against an instance's width getting bound to the *wrong* size token — it overrides the component default.

### figma_execute timeouts on heavy scripts / whole-tree findAll

Creating many instances in one call, or `findAll`/`findAllWithCriteria` over a whole page/document, hits the
execution timeout (default ~5–7s; max 30s — pass `timeout`). Split into smaller calls, scope `findAll` to a
specific node (never `figma.root`/page), and wrap geometry reads (`n.height`) in `try` — stale instance-sublayer
nodes throw "node … does not exist". `figma_execute` is **not** transactional — partial nodes persist on
error/timeout; inspect and clean them before retrying.

### Node references go stale after tree modification

After `appendChild`, `setProperties` (variant change), or `insertChild`, previously captured
`findOne()` references may silently point to removed/replaced nodes:

```javascript
// RISKY
const icon = inst.findOne(n => n.name === 'Icon');
inst.setProperties({ 'Type': 'Primary' }); // tree restructured
icon.swapComponent(newIcon); // MAY FAIL — stale reference

// SAFE — re-query after modification
inst.setProperties({ 'Type': 'Primary' });
const icon = inst.findOne(n => n.name === 'Icon'); // fresh reference
icon.swapComponent(newIcon);
```

### Container frame stays tiny without layoutSizingVertical = 'HUG' after appendChild

```javascript
// WRONG — set before appendChild has no effect
frame.layoutSizingVertical = 'HUG';
frame.appendChild(child); // frame stays 10px

// CORRECT
frame.appendChild(child);
frame.layoutSizingVertical = 'HUG'; // AFTER appendChild
```

### resize() is a no-op on nested instance nodes

Calling `nestedInst.resize(w, h)` inside a parent component has no effect.
Use `layoutSizingHorizontal = 'FILL'` / `layoutSizingVertical = 'FIXED'` on direct
children only. For deeper nesting: adjust layout sizing modes, not explicit resize.

---

## Pre-flight — before every new screen

### Step 1: Discover components used in similar screens

The fastest way to find the right components is to read what existing pages use:

```javascript
// Adjust page name to the file
await figma.loadAllPagesAsync();
const page = figma.root.children.find(p => p.name.includes('YOUR_REFERENCE_PAGE'));
await figma.setCurrentPageAsync(page);

const frame = page.children[0]; // or find the right frame
const results = [];
for (const child of frame.children) {
  if (child.type !== 'INSTANCE') continue;
  const mc = await child.getMainComponentAsync();
  if (!mc) continue;
  results.push({
    name: child.name,
    key: mc.key,           // use this key to import
    variant: mc.name,      // full variant name
    size: { w: child.width, h: child.height }
  });
}
return results;
// Result: ready list of components with keys — copy to the next step
```

### Step 2: Discover available color variables

```javascript
const vars = await figma.variables.getLocalVariablesAsync();
const colors = vars
  .filter(v => v.resolvedType === 'COLOR')
  .map(v => ({ name: v.name, id: v.id }));
return { count: colors.length, sample: colors.slice(0, 20) };
// Use names to identify — then getVariableByIdAsync(id) to bind
```

### Step 3: Check file conventions

```javascript
await figma.loadAllPagesAsync();
const pages = figma.root.children.map(p => p.name);
// Find a sample frame and check its width
const refPage = figma.root.children.find(p => !p.name.startsWith('---'));
await figma.setCurrentPageAsync(refPage);
const frame = refPage.children[0];
return {
  pages,
  frameWidth: frame?.width,   // e.g. 1440, 1563, 1280
  frameHeight: frame?.height
};
```

### Step 4: Screenshot variant before using

Before instantiating a component, screenshot it to confirm the right variant:
```
figma_capture_screenshot({ nodeId: 'COMPONENT_NODE_ID' })
```

Check available variants after import:
```javascript
const comp = await figma.importComponentByKeyAsync('KEY');
const inst = comp.createInstance();
const props = Object.entries(inst.componentProperties)
  .map(([k, v]) => ({ key: k, type: v.type, value: v.value }));
inst.remove(); // remove the test instance
return props;
// If VARIANT props exist → you can change via setProperties({ 'Type': 'Primary' })
// If TEXT props exist → you can change via setProperties({ 'Label#123': 'New text' })
// No text props → content is fixed, cannot be changed
```

---

## Text and overrides on instances — without detach

### Hierarchy of approaches (most correct first):

**Step 1: setProperties — when TEXT component property exists**
```javascript
const inst = comp.createInstance();
const props = Object.keys(inst.componentProperties);
const labelKey = props.find(k => inst.componentProperties[k].type === 'TEXT');
if (labelKey) inst.setProperties({ [labelKey]: 'New text' });
```

**Step 2: findOne(TEXT).characters — when no TEXT property (ghost prop)**

When a component doesn't expose text via `componentProperties`, set it directly on the
text node inside the instance. The instance **remains an instance** — component link is preserved.

```javascript
const inst = comp.createInstance();
parent.appendChild(inst);
const textNode = inst.findOne(n => n.type === 'TEXT');
if (textNode) {
  await figma.loadFontAsync(textNode.fontName); // ALWAYS before text edit
  textNode.characters = 'New text';
}
// inst.type === 'INSTANCE' ← still true, link preserved
```

**Step 3: Fill override on instance — when variant color doesn't fit**

Fills can be overridden on an instance without detaching. Instance stays an instance:
```javascript
const v = await figma.variables.getVariableByIdAsync('VariableID:4:283');
const paint = figma.variables.setBoundVariableForPaint(
  { type: 'SOLID', color: { r: 0.09, g: 0.20, b: 0.36 } }, 'color', v
);
inst.fills = [paint]; // fill override — does not detach
// inst.type === 'INSTANCE' ← still true
```

**There is no Step 4.** If Steps 1–3 don't work, the cause is an error in the approach,
not a lack of options. Inspect component structure (`inst.findAll(n => n.type === 'TEXT')`),
ensure `loadFontAsync` is called before editing, and check that the node isn't hidden.

---

## Binding color variables

When the file has design tokens, **always** bind instead of hardcoded values:

```javascript
// By ID (more efficient — if you know the ID from the file catalog)
const v = await figma.variables.getVariableByIdAsync('VariableID:XXXX:YYYY');

// By name (more readable — when you don't know the ID)
const vars = await figma.variables.getLocalVariablesAsync();
const v = vars.find(x => x.name === 'colors/background/bg-brand');

// Apply to fills — CRITICAL: base color must be the REAL color of the variable.
// Screenshots (exportAsync) render the base color, NOT the variable value.
// { r:0, g:0, b:0 } as base → screenshot shows black node despite correct binding.
// Always pass the approximate hex of the token as base:
const paint = figma.variables.setBoundVariableForPaint(
  { type: 'SOLID', color: { r: 0.09, g: 0.20, b: 0.36 } }, // ← actual token color
  'color', v
);
node.fills = [paint];

// Apply to strokes
node.strokes = [figma.variables.setBoundVariableForPaint(
  { type: 'SOLID', color: { r: 0.89, g: 0.88, b: 0.87 } }, 'color', borderVar
)];

// Opacity via spread (setBoundVariableForPaint ignores opacity in input paint):
node.fills = [{ ...paint, opacity: 0.12 }]; // spread AFTER the call
```

---

## Binding FLOAT variables (spacing & radius)

> **⚠️ Variable NAMES may not equal pixel VALUES — always map by value, never by name.**
> Many design systems name spacing on a rem/Tailwind scale where `spacing/N = N × 4 px`
> (so `spacing/4` = 16px, `spacing/16` = **64px**). Looking up `name === 'spacing/16'` to get
> 16px silently gives you 64px (real bug: a 64px gap where 16 was intended). Worse, names like
> `spacing/24`/`spacing/20` often **don't exist** → `find` returns `undefined` → `setBoundVariable`
> is silently skipped → the literal px stays UNBOUND (a token violation no error surfaces).
> **Build a px→variable map once and look up by resolved value:**

```javascript
const vars = await figma.variables.getLocalVariablesAsync();
const _sp = vars.filter(v => /^spacing\//.test(v.name))
  .map(v => ({ v, val: v.valuesByMode[Object.keys(v.valuesByMode)[0]] }));
const spPx = px => _sp.find(s => s.val === px)?.v;   // spPx(16) → the variable whose VALUE is 16px
// helper that sets value AND binds (kills the "undefined → unbound literal" trap):
const setSp = (node, prop, px) => { node[prop] = px; const v = spPx(px); if (v) node.setBoundVariable(prop, v); };

const sp8   = spPx(8);
const radMd = vars.find(v => v.name === 'radius/md' && v.resolvedType === 'FLOAT');

// Bind padding / gap — one call per property
node.setBoundVariable('paddingTop',    sp8);
node.setBoundVariable('paddingBottom', sp8);
node.setBoundVariable('paddingLeft',   sp8);
node.setBoundVariable('paddingRight',  sp8);
node.setBoundVariable('itemSpacing',   sp8);

// Uniform corner radius
node.setBoundVariable('cornerRadius', radMd);

// Mixed corners (when node.cornerRadius === figma.mixed) — bind each individually
node.setBoundVariable('topLeftRadius',     radMd);
node.setBoundVariable('topRightRadius',    radMd);
node.setBoundVariable('bottomRightRadius', radMd);
node.setBoundVariable('bottomLeftRadius',  radMd);
```

**Spacing scale (standard):** 4, 8, 12, 16, 20, 24, 32, 40, 48, 64px — values outside this scale need justification.

**Verify:** `node.boundVariables?.paddingTop?.type === 'VARIABLE_ALIAS'` → bound ✓

---

## Building a new page — step-by-step workflow

```
1. Pre-flight: audit existing pages → list of components with keys
2. Check conventions: frameWidth, page names, hierarchy
3. Create new page (check if it already exists!)
4. Create main frame (matching width)
5. Build in sections — one figma_execute per section:
   a. Import component → createInstance() → append to frame
   b. Position (x=0, y=previous_section_y + height)
   c. figma_capture_screenshot → visual validation
6. Final validation of the entire screen
```

### New page — template

```javascript
await figma.loadAllPagesAsync();
const pageName = 'Checkout Step 1'; // adjust

// Don't duplicate
const existing = figma.root.children.find(p => p.name === pageName);
if (existing) {
  await figma.setCurrentPageAsync(existing);
  return { status: 'page_exists', id: existing.id };
}

const page = figma.createPage();
page.name = pageName;
await figma.setCurrentPageAsync(page);

const W = 1440; // adjust to file conventions
const frame = figma.createFrame();
frame.name = pageName;
frame.resize(W, 100); // height will grow as instances are appended
frame.x = 0;
frame.y = 0;
page.appendChild(frame);

return { pageId: page.id, frameId: frame.id };
```

### Laying out instances

```javascript
// Import and stack from top
const comp = await figma.importComponentByKeyAsync('COMPONENT_KEY');
const inst = comp.createInstance();
frame.appendChild(inst);

// CRITICAL: set sizing AFTER appendChild — before has no effect in auto-layout
inst.layoutSizingHorizontal = 'FILL';
inst.layoutSizingVertical = 'FIXED'; // or HUG depending on component

inst.x = 0;
inst.y = currentY; // track accumulated height

// Verify actual size after layout — auto-layout parent can change it
const actualH = inst.height;
const expectedH = EXPECTED_HEIGHT; // from design spec
if (Math.abs(actualH - expectedH) > 2) {
  inst.resize(inst.width, expectedH); // force if auto-layout crushes/stretches it
}

currentY += inst.height;
return { instanceId: inst.id, actualH: inst.height, newY: currentY };
```

---

## DS page — canonical structure

Every DS page should use named SECTION nodes in this order (200px gap between sections):

```
01 – Foundations        Typography, Colors, Spacing, Icons, Radius/Border
02 – Core               Buttons, Badges, Chips, Dividers
03 – Forms              Input, Select, Checkbox, Radio, Switch, FieldInfo, SelectionCard
04 – Navigation         TopBar, AppBar, ProgressSteps, Breadcrumbs, Tabs
05 – Layout             SplitLayout, Cards, Panels
06 – Feedback           Toasts, Alerts, Empty states, Loading
07 – Patterns           Composite / multi-component patterns
```

Rules:
- New component → always placed inside the correct section, never on bare canvas
- After adding → `section.resizeWithoutConstraints(newW, newH)` to fit content
- Sections are Figma `SECTION` type (not frames) for proper canvas organization

### Create/find a section

```javascript
await figma.loadAllPagesAsync();
const dsPage = figma.root.children.find(p => p.name.includes('Design System') || p.id === 'DS_PAGE_ID');
await figma.setCurrentPageAsync(dsPage);

const sectionName = '02 – Core';
let section = dsPage.children.find(n => n.type === 'SECTION' && n.name === sectionName);
if (!section) {
  section = figma.createSection();
  section.name = sectionName;
  // Position below all existing content
  const maxY = Math.max(0, ...dsPage.children.map(n => (n.y || 0) + (n.height || 0))) + 200;
  section.y = maxY;
}
// Place component inside section
section.appendChild(newComponent);
```

---

## Post-build quality checklist

Run after completing every screen or component. Check each item before declaring done.

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

## Token compliance audit script

Run this after building any DS component to verify zero hardcoded values:

```javascript
// Replace 'MyComponent' with the component's exact name
const comp = figma.currentPage.findOne(n => n.name === 'MyComponent');
const issues = [];
const SPACING_VALS = new Set([4,8,12,16,20,24,32,40,48,64]);
const RADIUS_VALS  = new Set([4,6,8,12,16,9999]);

comp.findAll(() => true).forEach(n => {
  ['fills','strokes'].forEach(kind => {
    const paints = n[kind];
    if (!paints || paints === figma.mixed || paints.length === 0) return;
    paints.forEach((p, i) => {
      if (p.type !== 'SOLID' || p.opacity === 0) return;
      const bound = n.boundVariables?.[kind]?.[i]?.type === 'VARIABLE_ALIAS';
      if (!bound) issues.push(`${n.name} [${n.id}]: hardcoded ${kind} #${
        ['r','g','b'].map(c => Math.round(p.color[c]*255).toString(16).padStart(2,'0')).join('')
      }`);
    });
  });
  if (n.type === 'TEXT') {
    if (!n.textStyleId || n.textStyleId === figma.mixed)
      issues.push(`${n.name} [${n.id}]: missing text style (${n.fontSize}px)`);
  }
  ['paddingTop','paddingRight','paddingBottom','paddingLeft','itemSpacing'].forEach(prop => {
    const val = n[prop];
    if (typeof val !== 'number' || val === 0) return;
    if (n.boundVariables?.[prop]?.type !== 'VARIABLE_ALIAS')
      issues.push(`${n.name} [${n.id}]: hardcoded ${prop}=${val}${SPACING_VALS.has(val) ? '' : ' ⚠️ off-scale'}`);
  });
  const crBound = n.boundVariables?.cornerRadius?.type === 'VARIABLE_ALIAS';
  const anyCornerBound = ['topLeftRadius','topRightRadius','bottomLeftRadius','bottomRightRadius']
    .some(p => n.boundVariables?.[p]?.type === 'VARIABLE_ALIAS');
  if (!crBound && !anyCornerBound) {
    const cr = n.cornerRadius;
    if (typeof cr === 'number' && cr > 0)
      issues.push(`${n.name} [${n.id}]: hardcoded cornerRadius=${cr}${RADIUS_VALS.has(cr) ? '' : ' ⚠️ off-scale'}`);
  }
});
return { issueCount: issues.length, issues };
// issueCount: 0 → ready to ship. Anything else → fix before closing the session.
```

> **For SCREEN-level audits, treat each INSTANCE as opaque** (count it, don't recurse into it).
> `findAll(()=>true)` descends into DS components and flags their internal frames (NavRail, AppTopBar)
> as violations — you'll see a false ~70% where the real composition is 100%. Use a manual walk:

```javascript
// Instance-ratio audit for a screen — instance = opaque
function instanceRatioAudit(screen){
  const LAYOUT=/section|row|col|cols|container|content|wrapper|wrap|group|stack|list|grid|scroll|panel|bar$|spacer|footer|filter|head|header|body|main|kpi|table|card|drawer/i;
  const violations=[]; let instances=0, layoutFrames=0;
  (function walk(n){ for(const c of (n.children||[])){
    if(c.type==='INSTANCE'){ instances++; continue; }            // opaque — never recurse
    if(c.type==='TEXT'||c.type==='VECTOR'||c.type==='RECTANGLE'||c.type==='SLOT') continue;
    if(c.type==='FRAME'){
      if(LAYOUT.test(c.name)){ layoutFrames++; }
      else { const textChild=c.findOne?.(x=>x.type==='TEXT'),
                   hasFill=Array.isArray(c.fills)&&c.fills.some(f=>f.visible!==false&&f.opacity!==0),
                   hasStroke=Array.isArray(c.strokes)&&c.strokes.length>0;
             if((c.width<240&&c.height<80)||textChild||hasFill||hasStroke) violations.push(c.name); }
      walk(c);
    }
  }})(screen);
  const total=instances+violations.length;
  return { ratio:(total?Math.round(instances/total*100):100)+'%', pass: total? instances/total>=0.95 : true, instances, layoutFrames, violations };
}
// pass:true (≥95%) → ship. Replace violations with DS instances otherwise.
```

---

## Common mistakes and how to avoid them

| Mistake | Fix |
|------|-----|
| Manual rect+text instead of instances | Always go through the decision tree first |
| Hardcoded `{ r: 0.12, g: 0.17, b: 0.30 }` | `setBoundVariableForPaint` with a token |
| Only navbar+footer as instances, rest manual | EVERY element is an instance |
| Skipping audit of existing pages | `getMainComponentAsync` on a similar page |
| Importing local component by key | Local components: `getNodeByIdAsync(nodeId)` |
| One giant `figma_execute` for the whole screen | Split into sections, screenshot after each |
| Wrong frame width (e.g. 1440 vs 1563) | Check `frame.width` on an existing page |
| Cloned variant labels revert / `setProperties` no-ops on a clone | `clone()` drops `componentPropertyReferences` (TEXT too) — rename before append, then re-set `componentPropertyReferences.characters` once the clone is in the set |
| New component has a stray gradient/odd stroke | New nodes inherit last-used paint — set/clear `strokes`/`fills` explicitly (audit skips non-SOLID paints) |
| Component renders upside-down on the DS page | Parent SECTION is flipped (`scaleY=-1`) — match siblings' `relativeTransform` or build in a non-flipped section (`.rotation` reports 0) |
| Hardcoded panel/drawer/rail width | Bind to a FLOAT token: `node.setBoundVariable('width', widthVar)` (width/height ARE bindable) |
| COMPONENT_SET won't read/extend ("existing errors") | Variant property sets are inconsistent — normalize every variant name to the same keys (add the missing `Prop=Default`) |
| Text in instance — no TEXT prop | `setProperties` if prop exists; `findOne(TEXT).characters` after `loadFontAsync` if not. NEVER detach. |
| `detachInstance()` to change text or color | Use: (1) `setProperties` for TEXT props, (2) `findOne(TEXT).characters`, (3) fill override on instance |
| Content area built with `createFrame()` in a DS component | Use `createSlot()` instead — only SLOT nodes accept `appendChild` in instances; FRAME inside instance throws "Cannot move node" |
| Trying to `appendChild` to a FRAME inside an instance | Find a SLOT node: `instance.findOne(n => n.type === 'SLOT').appendChild(newChild)` |
| `getLocalVariables()` instead of async | `getLocalVariablesAsync()` |
| Hardcoded `node.cornerRadius = 8` instead of token | `node.setBoundVariable('cornerRadius', radiusVar)` using `getVariableByIdAsync` |
| `node.cornerRadius` without typeof check | Returns `figma.mixed` (Symbol) on nodes with per-corner radii — check `typeof node.cornerRadius === 'number'` before binding |
| `node.setTextStyleId(id)` sync call | `await node.setTextStyleIdAsync(id)` — sync throws in dynamic-page context |
| `vectorPaths` with arc (A) SVG command | Plugin API rejects arc — use `figma.createEllipse()` or `figma.createRectangle()` instead |
| New variant property added to COMPONENT_SET | Existing instances don't update automatically — run `inst.setProperties({ 'NewProp': 'DefaultValue' })` on all instances |
| Component has correct height standalone but wrong height in screen | `layoutSizingVertical` set before `appendChild`, or parent auto-layout overrides it | Always `appendChild` first, then set sizing; verify `inst.height` after and call `inst.resize()` if needed |
| New component created when existing one could be extended | Skipped semantic search / searched by exact name only | Run `figma_search_components` with synonyms; if ≥70% overlap → add variant/prop, don't create new |
| New component placed on bare canvas | Skipped DS page structure check | Always find/create the correct section first (`01–07`), `section.appendChild(component)` |
| Icon embedded as Unicode character in text node (e.g. "SCHOOL ↕") | Saves time short-term, breaks DS — no variable binding, no swap, no resize | Always use a separate INSTANCE of an icon component. If the icon doesn't exist in the DS iconset → create it from the icon library consistently used in the project, then instantiate. |
| Multiple `await loadFontAsync` calls in series | Sequential loads are 2-3× slower | Use `Promise.all([figma.loadFontAsync(...), ...])` |
| `setProperties(Variant)` before setting text | Variant change resets all text overrides to component defaults | Set variant first, then text — never before |
| COMPONENT_SET manual x/y without `layoutMode='NONE'` | Variants snap to auto-layout, x/y is ignored | Set `set.layoutMode = 'NONE'` immediately after `combineAsVariants()` |
| `node.clone()` and expect property bindings to persist | `clone()` resets componentPropertyReferences | Rebind INSTANCE_SWAP properties manually after cloning |
| Using saved `findOne()` reference after `setProperties` | References go stale after variant/tree changes | Re-query via `findOne` after any `setProperties` or `appendChild` |
| `buildX()` helper function in figma_execute | Helpers mask component duplication and bypass the DS decision tree | Use `figma_search_components` + `createInstance()` for each element; no local builder helpers |
| Building data table from FRAME grid | Fragile layout, hard to update | `figma.createTable(rows, cols)` → `TableNode` with `.cellAt(r,c)`, `.insertRow()`, `.resizeRow()` |
| Spacing variable looked up by name (`spacing/16` for 16px) | Names often follow a rem scale (`spacing/N = N×4px`) → `spacing/16` is 64px; missing names → `undefined` → silent skip → unbound literal | Map by resolved value: `spPx(px)` (see "Binding FLOAT variables"); never `find(v=>v.name==='spacing/'+px)` |
| Text fill left default after `setTextStyleIdAsync` | Text style sets typography, not color → fill stays unbound black (hardcoded violation) | Bind fill separately to `color/text/*` right after applying the style |
| FILL / `layoutGrow=1` child not expanding (stays at min width) | Parent auto-layout is hugging on the primary axis, so there's no free space to distribute | Set parent `primaryAxisSizingMode = 'FIXED'` (or `layoutSizingHorizontal='FILL'`) so free space exists; then the FILL child fills it |
| Retrying a failed `figma_execute` assuming it rolled back | `figma_execute` is **not** transactional — on error OR timeout, nodes created before the failure persist | Before retry, read current state (`parent.children.map(c=>c.name)`); make scripts small + idempotent; clean partial nodes first |
| Instance-ratio / token audit descending into instances | Counts DS components' internal frames (NavRail, AppTopBar) as violations → false 70% where it's really 100% | Treat each INSTANCE as **opaque** — count it, don't recurse into it (see the audit scripts; manual `walk` that `continue`s on `type==='INSTANCE'`) |

---

## How to catalog a new design system

On first contact with a new Figma file, run this script and save the result to memory:

```javascript
await figma.loadAllPagesAsync();
const pages = figma.root.children.map(p => ({ name: p.name, id: p.id }));

// Find first meaningful page (skip pages with '---' prefix)
const refPage = figma.root.children.find(p => !p.name.startsWith('---') && p.children.length > 0);
await figma.setCurrentPageAsync(refPage);

// File conventions
const frame = refPage.children[0];
const frameWidth = frame?.width;

// Color variables
const vars = await figma.variables.getLocalVariablesAsync();
const colorVars = vars.filter(v => v.resolvedType === 'COLOR')
  .map(v => ({ name: v.name, id: v.id }));

// Components from instances on the reference page
const instances = refPage.findAll(n => n.type === 'INSTANCE');
const compMap = {};
for (const inst of instances.slice(0, 30)) {
  const mc = await inst.getMainComponentAsync();
  if (mc && mc.key) compMap[mc.key] = { name: mc.name, key: mc.key };
}

return {
  pages: pages.map(p => p.name),
  frameWidth,
  colorVarCount: colorVars.length,
  colorSample: colorVars.slice(0, 15),
  componentSample: Object.values(compMap)
};
// → Copy the result to memory/ as a reference for this file
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
| `figma:figma-implement-design` | Figma design → production code |

> This skill (`figma-design-workflow`) is path-agnostic — the decision tree methodology
> and pre-flight audit apply to both Desktop Bridge and Cloud path.
