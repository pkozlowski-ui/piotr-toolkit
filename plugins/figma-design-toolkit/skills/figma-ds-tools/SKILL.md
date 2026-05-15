---
name: figma-ds-tools
description: >
  Audit and repair design system drift in Figma files. Load when checking DS compliance,
  finding hardcoded values that should be tokens, reconnecting detached instances,
  or running a token audit across pages.
---

# figma-ds-tools — Design System Audit & Repair

Two workflows: **Audit** (find drift) and **Apply** (repair drift).
Use together with `figma-design-toolkit:figma-console` for execution.

## When to load
- "Audit this file for DS compliance"
- "Find hardcoded colors / values not using tokens"
- "Reconnect these components to the library"
- "How far has this file drifted from the design system?"
- Taking over a file that grew organically without DS discipline

## Skill boundaries
For broader screen building on top of a DS, load `figma-design-toolkit:figma-design-workflow`.
For accessibility audit of components, load `figma-design-toolkit:figma-accessibility`.

---

## Workflow A — Audit

Run all three scripts below. Collect counts. Then prioritize by impact.

### A1 — Find detached instances (disconnected from main component)

```javascript
await figma.loadAllPagesAsync();
const detached = [];

for (const page of figma.root.children) {
  await figma.setCurrentPageAsync(page);
  const instances = page.findAll(n => n.type === 'INSTANCE');
  for (const inst of instances) {
    const main = await inst.getMainComponentAsync();
    if (!main) {
      detached.push({
        page: page.name,
        name: inst.name,
        id: inst.id,
        x: Math.round(inst.x),
        y: Math.round(inst.y)
      });
    }
  }
}
return { count: detached.length, detached };
// Detached instances = DS changes won't propagate here
// Priority: 🔴 High
```

### A2 — Find hardcoded fills (not bound to a color variable)

```javascript
await figma.loadAllPagesAsync();
const hardcoded = [];

function rgbToHex(r, g, b) {
  return '#' + [r, g, b]
    .map(v => Math.round(v * 255).toString(16).padStart(2, '0'))
    .join('').toUpperCase();
}

for (const page of figma.root.children) {
  await figma.setCurrentPageAsync(page);
  const nodes = page.findAll(n => Array.isArray(n.fills) && n.fills.length > 0);
  for (const n of nodes) {
    for (const fill of n.fills) {
      if (fill.type === 'SOLID' && !fill.boundVariables?.color) {
        hardcoded.push({
          page: page.name,
          node: n.name,
          id: n.id,
          hex: rgbToHex(fill.color.r, fill.color.g, fill.color.b)
        });
      }
    }
  }
}
return { count: hardcoded.length, sample: hardcoded.slice(0, 40) };
// Priority: 🟡 Medium — won't update with theme changes
```

### A3 — Find hardcoded corner radii (not bound to a variable)

```javascript
// Run on current page — adjust scope if needed
const nodes = figma.currentPage.findAll(n =>
  'cornerRadius' in n &&
  typeof n.cornerRadius === 'number' && // figma.mixed = per-corner, skip
  n.cornerRadius > 0
);
const hardcoded = nodes
  .filter(n => !n.boundVariables?.cornerRadius)
  .map(n => ({ name: n.name, id: n.id, radius: n.cornerRadius }));

return { count: hardcoded.length, hardcoded };
// Priority: 🟡 Medium
```

### Audit summary table

After running A1–A3, produce this before any repair work:

| Issue | Count | Priority | Impact |
|---|---|---|---|
| Detached instances | — | 🔴 High | DS updates don't reach these nodes |
| Hardcoded fills | — | 🟡 Medium | Theme switch won't affect these colors |
| Hardcoded radii | — | 🟡 Medium | Radius token changes won't propagate |

Agree on priority order with the team before repairing.

---

## Workflow B — Apply (repair)

### B1 — Reconnect a detached instance to its main component

```javascript
// Prerequisite: know the target component key (from figma-design-workflow pre-flight catalog)
const TARGET_KEY = 'COMPONENT_KEY'; // replace
const DETACHED_ID = 'DETACHED_NODE_ID'; // replace

const comp = await figma.importComponentByKeyAsync(TARGET_KEY);
const detached = await figma.getNodeByIdAsync(DETACHED_ID);

const parent = detached.parent;
const idx = parent.children.indexOf(detached);
const { x, y, width, height } = detached;

const newInst = comp.createInstance();
parent.insertChild(idx, newInst);
newInst.x = x;
newInst.y = y;
newInst.resize(width, height);
detached.remove();

return { replaced: true, newId: newInst.id };
// ⚠ Check component properties after replacement — text content may need resetting:
// newInst.setProperties({ 'Label#123': 'Original text' })
```

### B2 — Bind a single hardcoded fill to a variable

```javascript
// Find the right variable by name (from color catalog)
const vars = await figma.variables.getLocalVariablesAsync();
const targetVar = vars.find(v => v.name === 'colors/background/bg-primary'); // adjust name

const node = await figma.getNodeByIdAsync('NODE_ID'); // replace
const paint = figma.variables.setBoundVariableForPaint(
  { type: 'SOLID', color: { r: 0, g: 0, b: 0 } },
  'color',
  targetVar
);
node.fills = [paint];
return { bound: targetVar.name, nodeId: node.id };
```

### B3 — Bulk-bind: replace all occurrences of one hardcoded hex with a token

```javascript
// Replace all fills matching a specific color with a DS variable
// Run on current page — adjust scope if needed
const TARGET_HEX = { r: 0x1A / 255, g: 0x2B / 255, b: 0x4C / 255 }; // adjust to target color
const THRESHOLD = 0.01; // tolerance for float comparison
const TOKEN_NAME = 'colors/brand/navy'; // adjust to matching variable name

const vars = await figma.variables.getLocalVariablesAsync();
const targetVar = vars.find(v => v.name === TOKEN_NAME);
if (!targetVar) return { error: `Variable "${TOKEN_NAME}" not found` };

const nodes = figma.currentPage.findAll(n =>
  Array.isArray(n.fills) && n.fills.length > 0
);

let bound = 0;
for (const n of nodes) {
  let changed = false;
  const newFills = n.fills.map(fill => {
    if (
      fill.type === 'SOLID' &&
      !fill.boundVariables?.color &&
      Math.abs(fill.color.r - TARGET_HEX.r) < THRESHOLD &&
      Math.abs(fill.color.g - TARGET_HEX.g) < THRESHOLD &&
      Math.abs(fill.color.b - TARGET_HEX.b) < THRESHOLD
    ) {
      changed = true;
      bound++;
      return figma.variables.setBoundVariableForPaint(fill, 'color', targetVar);
    }
    return fill;
  });
  if (changed) n.fills = newFills;
}
return { bound, token: TOKEN_NAME };
// Run once per unique hardcoded color from the A2 audit
```

### B4 — Bind corner radius to variable

```javascript
const vars = await figma.variables.getLocalVariablesAsync();
const radiusVar = vars.find(v => v.name === 'radius/md'); // adjust

const node = await figma.getNodeByIdAsync('NODE_ID');
// Guard: cornerRadius must be a number (not figma.mixed = per-corner)
if (typeof node.cornerRadius !== 'number') {
  return { error: 'Node has per-corner radii — bind each corner individually' };
}
node.setBoundVariable('cornerRadius', radiusVar);
return { bound: radiusVar.name };
```

---

## Common mistakes in repair

| Mistake | Fix |
|---|---|
| Removing detached node before creating replacement | Always insert new instance first, then remove old |
| Bulk-bind overwrites intentional overrides | Check for `fill.boundVariables` before replacing — already-bound fills are skipped by B3 |
| `typeof node.cornerRadius` check skipped | `figma.mixed` (Symbol) for per-corner radii — `typeof` check prevents silent failures |
| Importing local components with `importComponentByKeyAsync` | Local components: use `figma.getNodeByIdAsync(nodeId)` — keys are for library components |
| Running bulk-bind on all pages without audit first | Run A2 first, confirm hex matches, test on 1 node before bulk |
