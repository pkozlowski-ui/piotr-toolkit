# Runtime gotchas & common mistakes — figma-design-workflow

> **Load when:** you are about to write (or are debugging) Plugin API code — `figma_execute`
> scripts, variant/COMPONENT_SET work, clone/append/resize operations.
> Index of the silent-failure traps lives in `SKILL.md` → "Gotchas index". This file is the detail.

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
