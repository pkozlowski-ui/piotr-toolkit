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

Before doing anything, pick the execution path:

| Signal | Tool | Skill |
|---|---|---|
| Render a frame/component from JSX, apply shadcn/tailwind tokens, create UI block | **figma-cli** | `figma-design-toolkit:figma-cli` |
| Need component variants, programmatic variable binding, multi-page operations | **figma-console** | `figma-design-toolkit:figma-console` |
| Read design context / screenshot for code generation | Figma desktop MCP read tools | n/a |
| Desktop Bridge unavailable (no Figma Desktop, restricted env) | claude.ai Figma MCP | `figma:figma-use` (external) |

Default: **figma-cli** for new screens, **figma-console** when JSX falls short.

---

## ABSOLUTE RULE: Never detach component instances

> **`detachInstance()` is forbidden.** No exceptions.
>
> Detach destroys the link to the DS component — variants, variable binding, and future
> updates stop working. There is no scenario where detach is "the only option" — there is
> always an alternative. If something seems impossible without detach, read the
> "Text and overrides on instances" section below.

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

3. No component fits?
   → Build ONLY with design tokens:
      - colors: bind variables (setBoundVariableForPaint), NOT hardcoded hex/RGB
      - typography: text styles via setTextStyleIdAsync, NOT manual font+size
      - spacing: bind FLOAT variables via setBoundVariable, NOT hardcoded px
      - radius: bind FLOAT variables via setBoundVariable, NOT hardcoded px
```

> Never start with `createRectangle()` + `createText()` without going through the tree above.
> Building from raw shapes bypasses the entire design system — hardcoded colors, inconsistent typography,
> token changes don't propagate.

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
inst.x = 0;
inst.y = currentY; // track accumulated height
inst.resize(W, inst.height); // stretch to full width

currentY += inst.height;
return { instanceId: inst.id, newY: currentY };
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
| Text in instance — no TEXT prop | `setProperties` if prop exists; `findOne(TEXT).characters` after `loadFontAsync` if not. NEVER detach. |
| `detachInstance()` to change text or color | Use: (1) `setProperties` for TEXT props, (2) `findOne(TEXT).characters`, (3) fill override on instance |
| `getLocalVariables()` instead of async | `getLocalVariablesAsync()` |
| Hardcoded `node.cornerRadius = 8` instead of token | `node.setBoundVariable('cornerRadius', radiusVar)` using `getVariableByIdAsync` |
| `node.cornerRadius` without typeof check | Returns `figma.mixed` (Symbol) on nodes with per-corner radii — check `typeof node.cornerRadius === 'number'` before binding |
| `node.setTextStyleId(id)` sync call | `await node.setTextStyleIdAsync(id)` — sync throws in dynamic-page context |
| `vectorPaths` with arc (A) SVG command | Plugin API rejects arc — use `figma.createEllipse()` or `figma.createRectangle()` instead |
| New variant property added to COMPONENT_SET | Existing instances don't update automatically — run `inst.setProperties({ 'NewProp': 'DefaultValue' })` on all instances |

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
