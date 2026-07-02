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

## Tool selection — don't funnel everything through `figma_execute`

`figma_execute` is the **most expensive and timeout-prone** path (see "Performance & the timeout budget" below). Reserve it for what *only* it can do; push everything else to a cheaper tool.

| Task | Tool |
|---|---|
| New screen/component from JSX, shadcn/tailwind tokens, UI blocks | **figma-cli** (`render` / `blocks` / `tokens`) |
| Read design context, screenshot for code, generate-from-intent, FigJam | **official Figma MCP** (Dev Mode, `localhost:3845` — has write now, no 7s ceiling) |
| Variants, programmatic variable binding, multi-page ops, DS audit/parity, prototype reactions — **small/iterative** | **figma-console** (`figma_execute`) — keep each call small |
| **Heavy / bulk node write** — a sweep over **≥~50 nodes**, or any write you'd otherwise have to *chunk* to dodge the 5 s cap | **`use_figma`** (official remote MCP, via `figma-cloud`) — **no 5 s ceiling, atomic.** Beats chunking `figma_execute`, and sidesteps the Bridge dying mid-sweep (Figma kills the plugin runtime every ~1–3 min). |
| Bulk variable create/update | **figma-console** `figma_batch_create_variables` / `figma_batch_update_variables` (not a loop in `execute`) |
| No Desktop Bridge (phone, web, cloud container) | **`figma-cloud`** → official remote MCP (`mcp.figma.com`) |

Both MCP servers can run **simultaneously** — figma-console for DS/variant/parity work, official Figma MCP for read/codegen/generation. Assembling a prototype from an existing DS (instances + variants + reactions) stays in figma-console; that can't move to JSX render.

**Threshold rule — don't chunk a doomed script, switch channels.** The 5 s/7 s cap is a hardcoded guard in *this* bridge, **not** a Figma Plugin API limit (the Plugin API has no forced kill — verified 2026-07-02). So a big sweep has two escapes: chunk it into sub-5 s `figma_execute` calls (fine for ~2–3 chunks), or — once it's genuinely large (**≥~50 nodes** or you're writing chunking scaffolding just to fit) — run it through **`use_figma`** instead: one atomic script, no ceiling, no partial-state, and immune to the mid-session Bridge drop. Keep `figma-console` for what it's best at: fast iterative edits, inspection, `figma_capture_screenshot`, the multi-file active-file model. (Load the `figma:figma-use` skill before the first `use_figma` call; see `figma-cloud` for remote mechanics — full doc access, not dynamic-page.)

## Performance & the timeout budget — READ FIRST

`figma_execute` is hardcoded to a **two-layer timeout** (verified in figma-console-mcp source — **NOT configurable** by env var or tool param):
- the plugin kills the script at **5000 ms**
- the WebSocket command then fails at **7000 ms** → `WebSocket command EXECUTE_CODE timed out after 7000ms`

**Any single script needing more than ~5 s of plugin work ALWAYS times out** — and a timeout can leave **partial artifacts** (it is not reliably atomic). This is the #1 source of wasted loops. The median call is fast (~0.5 s); the pain comes entirely from heavy multi-task scripts and page-wide traversal. Stay under budget:

1. **One job per call, ≤ ~15 awaits.** Each `createInstance` / `setText` / `setProperties` / `setReactionsAsync` / `loadFontAsync` counts as one. Build a screen as a *chain* of small calls (container → tokens → instances → layout → reactions), validating between — never one mega-script.
2. **Cheap traversal — the biggest hidden cost (≈97% of scripts traverse).**
   - Hold node IDs and pass them forward between calls → `getNodeByIdAsync(id)`. Don't re-`findAll` the page to re-find a node you just created.
   - Use `findAllWithCriteria({ types: ['INSTANCE'] })` (indexed, fast) instead of predicate `findAll(n => n.type === …)`.
   - Scope to the smallest subtree (`section.findAll…`), not `figma.root` / the whole `currentPage`, whenever you can.
   - `loadAllPagesAsync()` once per session is fine (cached) — the cost is the *scan*, not the load. Skip it when you already hold the node by ID on the current page.
3. **Batch variables** via `figma_batch_create_variables` / `figma_batch_update_variables` (≤100/call, 10–50× faster) — never a `createVariable` loop inside `execute`.
4. **Screenshots: `figma_capture_screenshot` only** (~0.7 s). `figma_take_screenshot` is REST (~7–14 s, caches stale bytes) — see the validation section.
5. **`figma_search_components` is the single slowest tool** (~19 s median, up to ~70 s). Call it rarely: prefer the project catalog (`docs/design-system/components.md`), search once at session start, reuse the IDs.

**Pre-send self-check (do this before every `figma_execute`):**
- Count the `await`s in the script — **> ~15? Split it.**
- Any `findAll` on `figma.root` or the whole `currentPage`? **Scope it** to a section, or page it (below).
- Holding a node from a previous call? Use `getNodeByIdAsync(id)` — don't re-search for it.

**Chunked traversal (for genuinely large pages — avoids the timeout at the source):**
```javascript
// Page once via findAllWithCriteria (indexed), then process in small batches across calls.
// Call 1 — collect IDs only (cheap), return them:
const ids = figma.currentPage.findAllWithCriteria({ types: ['INSTANCE'] }).map(n => n.id);
return { ids, total: ids.length };
// Call 2..N — process a slice (e.g. 25) per call, pass the offset forward:
const slice = BATCH_IDS;                 // ~25 ids from the previous return
const nodes = await Promise.all(slice.map(id => figma.getNodeByIdAsync(id)));
// …do the work on `nodes`… return progress { done, nextOffset }
```
This turns one doomed page-wide script into a chain of sub-5 s calls.

**Genuinely un-splittable heavy op?** (rare). The ceiling can be raised by running a pinned, *patched* figma-console (`5000/7000 → 30000/32000`) instead of `npx …@latest` — but that's a maintained fork and 5 s is also a runaway-script guard. Ask the user before going there; first try splitting.

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

> **⚠️ DYNAMIC-PAGE: sync getters/setters throw.** The bridge runs in `documentAccess: dynamic-page`.
> Many synchronous accessors throw `Cannot call with documentAccess: dynamic-page. Use …Async instead.`
> (the single most common avoidable error). Default to the **async** variant:
>
> | Sync (throws) | Async (use this) |
> |---|---|
> | `instance.mainComponent` | `await instance.getMainComponentAsync()` |
> | `component.instances` | `await component.getInstancesAsync()` |
> | `node.reactions = […]` | `await node.setReactionsAsync([…])` (read getter `node.reactions` still works) |
> | `node.setTextStyleId(id)` | `await node.setTextStyleIdAsync(id)` |
> | `figma.currentPage = page` | `await figma.setCurrentPageAsync(page)` |
> | `figma.getNodeById(id)` | `await figma.getNodeByIdAsync(id)` |
> | accessing other pages' nodes | `await figma.loadAllPagesAsync()` first |
>
> Rule of thumb: if a getter/setter touches a *component relationship*, *another page*, or *reactions*, reach for its `…Async` form.

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

### Connection — resilience protocol (don't loop reconnects)

Bridge drops are the #1 session-start friction. Follow a **bounded** recovery, then hand off — never
spin `figma_reconnect` or guess ports:

1. `figma_get_status` — check.
2. If down → **one** `figma_reconnect` (it already handles the 9223–9232 port pool itself — don't try ports by hand).
3. `figma_get_status` again. Still down → **before you block, consider the `use_figma` fallback** (next paragraph). If the pending work fits it, switch and keep going. If it genuinely needs the Desktop Bridge (`figma_capture_screenshot`, fast iterative inspection, active-file model) → **STOP and ask Piotr loudly**: "Open the Desktop Bridge in Figma Desktop (Plugins → Development → Figma Desktop Bridge), then tell me to continue." Wait. Asking is the correct path, not a workaround. (See "Manual steps are the user's" below.)

**Bridge died mid-session → `use_figma` is a full write-fallback, not just a "no-Desktop" path.** When the Desktop Bridge drops and won't reconnect, you do **not** have to block on a relaunch to keep writing. The official remote MCP `use_figma` (`mcp__…__use_figma`, `fileKey` + `code`, same Plugin API) writes **headless/cloud, no Desktop Bridge** — and for heavy work it is often the *better* tool anyway:
- **Atomic** — a bad script doesn't execute at all (zero partial-state, retry-safe), unlike `figma_execute`.
- **No 5 s ceiling** — carries sync-loops over dozens of nodes + cross-page `getInstancesAsync`/`getNodeByIdAsync` without timing out. (Proven: KpiCard sweep, 275 instances, after a mid-session Bridge drop.)
- Load the MANDATORY `figma:figma-use` skill before the first call, then follow `figma-cloud` mechanics (remote = full document access, **not** dynamic-page — don't port the async-getter dance; `loadAllPagesAsync()` throws there).
- Gotchas: `figma.currentPage` resets to page 1 each call (`getNodeByIdAsync` still works cross-page without a set); multi-page = fan out N parallel calls (1 `setCurrentPageAsync`/call).

**Rule:** Bridge down → don't loop reconnects or block a big sweep on a relaunch. If the work is a write (especially a large/atomic one), switch to `use_figma`. Keep the Desktop Bridge only for what needs it (`figma_capture_screenshot`, quick iterative inspection, multi-file active-file model).

**Distinguish two failures — they have different fixes:**
- `figma_*` tools **don't exist at all** → the MCP **server isn't registered** (install problem). `figma_reconnect` won't help — see Install / Setup.
- Tools exist but error `"Make sure the Desktop Bridge plugin is running"` / `"Cannot connect to Figma Desktop"` → the **plugin isn't running** in the app → the protocol above (ask Piotr to launch it).

### Multiple files
```
figma_list_open_files       // which files have Desktop Bridge plugin
figma_navigate              // switch active file
```

**Active-file model (read before multi-file work).** One MCP server per Claude session; the Desktop Bridge plugin — launched **per file** — connects to all servers (port pool 9223–9232). Each server has ONE active file: `figma_execute` always targets it (no per-call `targetFileKey`), and the active file **follows the user's last click** (selection/page change broadcasts to every server). Treat "active file" as session state that drifts — re-assert `figma_navigate` before a write batch. Three cases:
- **Several files, one project (screens + DS):** open each and **launch the bridge in each**. To use DS in the screens file, prefer `importComponentByKeyAsync(key)` + `createInstance()` over switching files. Work one file at a time (the active one); node IDs are per-file.
- **Parallel work / two sessions on two files:** access works, isolation doesn't — every server's active file converges to the last-touched file, so parallel **writes** race. Read in parallel, **serialize writes**, and re-assert `figma_navigate(yourFile)` right before each write batch.
- **Manual switching:** the active file follows your clicks — but don't switch while the agent is mid-build (its next command lands where you clicked), and a freshly opened file isn't connected until you launch the bridge in it.

**Manual steps are the user's — ask loudly, don't work around.** If you need a specific file open, the Desktop Bridge launched in a file, an access granted, or a blocked action approved → state it plainly and wait. Asking is the best path, not a blocker.

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
| `"Cannot call with documentAccess: dynamic-page. Use getMainComponentAsync instead"` | Sync `instance.mainComponent` | `await instance.getMainComponentAsync()` |
| `"…Use getInstancesAsync instead"` | Sync `component.instances` | `await component.getInstancesAsync()` |
| `"…dynamic-page"` on reactions / page set / node lookup | Any sync getter/setter in dynamic-page | Use the `…Async` variant (see the dynamic-page table above) |
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
