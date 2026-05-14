---
name: figma-console
description: Prerequisite for figma-console MCP tools (figma_execute, figma_capture_screenshot, figma_search_components etc.). Load before any figma_execute call. Use when you need full Plugin API access via Figma Desktop — complex component creation, variant management, variable binding, programmatic design operations that figma-cli's JSX syntax can't handle.
---

# figma-console — Desktop Bridge MCP

Controls Figma Desktop via WebSocket (Desktop Bridge plugin). Requires Figma to be open with the plugin running.

## When to load
- About to call `figma_execute` for Plugin API operations
- Working with component variants (`setProperties`)
- Variable binding programmatically (`setBoundVariableForPaint`)
- Operations across multiple pages
- Anything that figma-cli JSX render can't express

## Tool selection

| Task | Tool |
|---|---|
| JSX render, shadcn tokens, UI blocks | **figma-cli** |
| Complex Plugin API, variants, variable binding | **figma-console** (`figma_execute`) |
| Read design context, screenshot for code | Figma desktop MCP read tools |
| Cloud fallback (no Desktop Bridge available) | claude.ai Figma MCP |

## Methodology — see figma-design-workflow

The component-first decision tree, pre-flight audit of existing pages, and color variable binding patterns live in the `figma-design-workflow` skill. Load it alongside this one when designing screens.

This skill covers **mechanics specific to `figma_execute`** — script format, error recovery, placement rules.

## Pre-flight (each session)

- `figma_get_status` — check connection
- `figma_list_open_files` — which file is active?
- `figma_search_components` — refresh node IDs (stale between sessions)
- `figma_capture_screenshot` — screenshot the page before changes
- Find free space, don't overlap existing content

**Node IDs are stale between conversations** — never reuse IDs from a previous session without re-searching.

## figma_execute — critical rules

### 1. JS code — format

```javascript
// GOOD — plain JS with top-level await and return
const frame = figma.createFrame();
frame.resize(200, 200);
return { id: frame.id, name: frame.name };

// BAD — don't wrap in async IIFE (auto-wrapped already)
(async () => { ... })()
```

### 2. Return is the only output channel

- `console.log()` → invisible, don't use
- `figma.notify()` → throws "not implemented", don't use
- Always `return` with data: `{ createdNodeIds: [...], status: "ok" }`

### 3. Instances — text must go through setProperties

```javascript
// BAD — FAILS SILENTLY (no error, but text doesn't change)
const inst = figma.createInstance(component);
inst.findOne(n => n.type === 'TEXT').characters = 'New text';

// GOOD — via instance properties
return Object.keys(instance.componentProperties);  // check first
instance.setProperties({ 'Label#2:0': 'New text' });
```

Or use `figma_set_instance_properties` tool directly.

### 4. Check resultAnalysis.warning

`figma_execute` returns `resultAnalysis` — always check `resultAnalysis.warning`:
- Empty arrays → operation may be a silent failure
- Null returns → node doesn't exist or wrong ID

### 5. Placement — always inside Section/Frame

```javascript
let section = figma.currentPage.findOne(n => n.type === 'SECTION' && n.name === 'Components');
if (!section) {
  section = figma.createSection();
  section.name = 'Components';
  const maxY = Math.max(0, ...figma.currentPage.children.map(n => n.y + n.height)) + 100;
  section.y = maxY;
}
const frame = figma.createFrame();
section.appendChild(frame);
```

### 6. Cleanup on error/retry

If a script failed and left partial artifacts — remove them before retrying:

```javascript
const orphans = figma.currentPage.findAll(n => n.name === 'Temp' || n.children?.length === 0);
orphans.forEach(n => n.remove());
```

Never build on a broken foundation.

### 7. Pages — don't duplicate

```javascript
await figma.loadAllPagesAsync();
const existing = figma.root.children.find(p => p.name === 'Design System');
if (existing) {
  await figma.setCurrentPageAsync(existing);
} else {
  const newPage = figma.createPage();
  newPage.name = 'Design System';
  await figma.setCurrentPageAsync(newPage);
}
```

### 8. Colors — range 0–1 (not 0–255)

```javascript
{ r: 1, g: 0, b: 0 }      // red ✓
{ r: 255, g: 0, b: 0 }    // BAD ✗
```

### 9. FILL after appendChild

```javascript
parent.appendChild(child);
child.layoutSizingHorizontal = 'FILL'; // AFTER append, not before
```

### 10. Font BEFORE text operations

```javascript
await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
const text = figma.createText();
text.characters = 'Hello'; // only after loadFontAsync
```

## Visual Validation Loop (required)

After every operation that creates or modifies visual elements:

1. `figma_capture_screenshot(nodeId: "NODE_ID")` — prefer over `figma_take_screenshot`
2. Check: alignment, spacing, proportions, visual balance
3. Iterate if something looks off (max 3 times)
4. Final `figma_capture_screenshot` for confirmation

**figma_capture_screenshot vs figma_take_screenshot:**
- `figma_capture_screenshot` — via plugin runtime, sees changes immediately, preferred for validation
- `figma_take_screenshot` — via REST API (cloud), may not reflect latest state

## Session Management

### Connection
```
figma_get_status            // check
figma_reconnect             // if status not OK
```

### Multiple files
```
figma_list_open_files       // which files have Desktop Bridge plugin
figma_navigate              // switch active file
```

### Discover file structure
```javascript
// Start with verbosity='summary', depth=1 — not 'full' (consumes tokens)
figma_get_file_data({ verbosity: 'summary', depth: 1 })
```

### Discover components
```
figma_search_components({ query: 'Button', limit: 10 })
figma_search_components({ category: 'Card', limit: 10 })
```

### Check user selection
```
figma_get_selection()
figma_get_selection({ verbose: true })  // with fills/strokes/styles
```

## Incremental workflow

1. **Inspect first** — screenshot + `figma_get_file_data(summary)` before creating
2. **One task per `figma_execute`** — don't build a whole screen in one call
3. **Return node IDs** from every call — needed in subsequent steps
4. **Validate after each step** — `figma_capture_screenshot` after creating components
5. **Fix before continuing** — don't build on a broken state

### Suggested order for complex tasks

```
Step 1: Inspect — figma_get_file_data + figma_capture_screenshot
Step 2: figma_search_components — what's available?
Step 3: Create Section/parent frame → return { sectionId }
Step 4: Create tokens/variables → validate
Step 5: Create components (one per call) → validate
Step 6: Compose layout from instances → validate
Step 7: Final validation of the whole screen
```

## Error Recovery

`figma_execute` is atomic — if the script throws, no changes are applied.

**On error:**
1. STOP — don't retry immediately
2. Read the error message carefully
3. If unclear — `figma_capture_screenshot` + `figma_get_file_data` to check state
4. Fix the script
5. Retry (safe — nothing was changed)

**On success but looks wrong:**
1. `figma_capture_screenshot(nodeId)` — not the whole page
2. Write a targeted fix script — don't rebuild from scratch

### Common errors and fixes

| Error | Cause | Fix |
|-------|-----------|-----|
| "not implemented" | `figma.notify()` | Remove it, use `return` |
| Text doesn't change, no error | Direct edit on instance | `setProperties()` or `figma_set_instance_properties` |
| `"Setting figma.currentPage is not supported"` | Sync setter | `await figma.setCurrentPageAsync(page)` |
| Empty array in result | Silent fail — node doesn't exist | Check ID, check page |
| FILL before appendChild | Crash on layoutSizing | Move FILL after appendChild |
| Font error | Missing loadFontAsync | Add `await figma.loadFontAsync(...)` before text ops |

## Pre-flight checklist (before figma_execute)

- `return` used as output (not `console.log`, not `figma.notify`)
- Code NOT wrapped in async IIFE
- Colors in range 0–1
- `layoutSizingH/V = 'FILL'` set AFTER `appendChild`
- `loadFontAsync()` called BEFORE text operations
- **Every `createText()` → `await node.setTextStyleIdAsync(id)` from `getLocalTextStylesAsync()`** (never set fontSize/fontFamily/fontWeight manually)
- Page switch via `await figma.setCurrentPageAsync(page)`
- Instances: text via `setProperties()`, not direct edit
- New nodes created inside Section/Frame (not on bare canvas)
- Node IDs returned from all created/modified elements
- Page duplication checked before creating
