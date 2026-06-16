---
name: figma-console
description: Prerequisite for figma-console MCP tools (figma_execute, figma_capture_screenshot, figma_search_components etc.). Load before any figma_execute call. Use when you need full Plugin API access via Figma Desktop — complex component creation, variant management, variable binding, programmatic design operations that figma-cli's JSX syntax can't handle.
---

# figma-console — Desktop Bridge MCP

Controls Figma Desktop via WebSocket (Desktop Bridge plugin). Requires Figma to be open with the plugin running.

## Install / Setup (MCP server)

The `figma_execute` / `figma_capture_screenshot` / `figma_search_components` tools come from the
**figma-console MCP server** — a separate component, not bundled with this plugin. On a fresh machine
the tools won't exist until it's installed and registered.

- **Repo:** https://github.com/southleft/figma-console-mcp (clone + follow its README for install + MCP registration)
- After registering the MCP server, the Figma Desktop side needs the **Desktop Bridge plugin** running
  (Figma open, plugin launched) — see that repo for the bridge setup.
- Verify with `figma_get_status`. If the `figma_*` tools aren't available at all → the MCP server isn't
  registered (this is install, not a connection drop — `figma_reconnect` won't help).

> Część skilla `workflow-toolkit:bootstrap-machine` (onboarding nowej maszyny) powinna obejmować ten krok.

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

**figma_capture_screenshot vs figma_take_screenshot — ALWAYS use `capture` to verify edits:**
- `figma_capture_screenshot` — `exportAsync` from the plugin runtime. Renders the LIVE node every call, **independent of which page is active**, and reflects your last edit immediately. The only reliable screenshot for validation.
- `figma_take_screenshot` — cloud/REST path with two real failure modes that each waste a whole loop:
  1. **Caches per nodeId** — repeat calls on the same node return *identical bytes* even after the node changed.
  2. **Renders stale master defaults for instance SLOT content** (Modal/SideDrawer/AssistantPanel `content`/`footer`) unless that node's page is the *active* page.
- Corollary: never trust a `take` screenshot showing an "old value". The model is the truth — confirm with `componentProperties` / `.characters`, or just re-shoot with `capture`. (Verified 2026-06-15: `capture` rendered live slot content correctly while a *different* page was active; `take` showed defaults + cached bytes.)

## Embedding images / screenshots INTO FigJam (or any board)

**Programmatic image embedding via this bridge is NOT reliable — don't burn time re-trying it.** Verified empirically (2026-06-16):
- `figma.createImageAsync(URL)` is blocked by the plugin's `networkAccess.allowedDomains` — and even a *listed* `http://localhost:PORT` is rejected (mixed-content: HTTP inside Figma's HTTPS runtime). Surfaces as a generic "does not satisfy the allowedDomains" error.
- `figma.createImageAsync('data:image/…;base64,…')` and `figma_set_image_fill` (base64) DO bypass the domain check and work *in principle* — BUT the base64 must pass through the agent into the tool call, and at real screenshot sizes the transcription **corrupts the byte stream** (image renders with a garbled/grey lower half). `figma_set_image_fill` also tends to **time out (60s)** on non-trivial payloads.
- The plugin manifest **regenerates from the npm package on every server start** (`copyFileSync` in `setupStablePluginDir`), so hand-editing `~/.figma-console-mcp/plugin/manifest.json` to add domains is futile — it reverts.
- Figma REST API cannot create nodes / upload media (read-only + comments only).

**→ Workflow for screenshots on FigJam/boards (do this EVERY time screenshot work comes up):**
1. Create a **folder on the macOS Desktop** (`~/Desktop/…`, named per task).
2. Drop in every screenshot you can source — from Figma files via `get_screenshot` → `curl` the returned (short-lived) URL to a file; public web screenshots via curl / browser tools; Mobbin etc.
3. **User drags the files into FigJam** (FigJam embeds them losslessly — zero corruption).
4. **You arrange / size / caption** them in the target section.
Screens that live only in chat (pasted) or behind a login → user drops into the same folder.

Full automation only becomes possible if figma-console adds **local-file-path** input for images (announced in PR #31, absent in 1.31.0) — then the MCP server reads the file and base64 never passes through the agent. Until then: Desktop-folder → drag-drop.

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

⚠️ `figma_execute` is **NOT reliably atomic on this bridge** — a throw, and *especially* a timeout, mid-script can leave **partial artifacts** (half-built frames, duplicated nodes). Do not assume a failed call changed nothing.

**On error:**
1. STOP — don't retry immediately
2. Read the error message carefully
3. `figma_capture_screenshot` (live) + inspect — check what, if anything, was created
4. **Clean up partial artifacts before retrying** (find by name / empty children, remove)
5. Fix the script — make it **cleanup-tolerant** (guard-and-reuse existing nodes, not blind create)
6. Keep each call small (**≤ ~15 awaits**; each `createInstance`/`txt`/`setReactionsAsync` is one) to stay under the ~5s budget — long scripts time out and that's the main partial-state cause

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
| `"Cannot move node. New parent is an instance or is inside of an instance"` | Appending to a plain FRAME inside an instance | The target frame must be a SLOT node. In the DS component use `componentNode.createSlot()` instead of `createFrame()`. Then in instances: `instance.findOne(n => n.type === 'SLOT').appendChild(newChild)` |

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
