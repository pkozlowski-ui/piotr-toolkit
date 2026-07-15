# Editing an existing FigJam board

Lessons verified while iterating on a real, populated board (not building from scratch).
The base SKILL.md assumes mostly *creation*; this file covers *editing, rearranging, and
ingesting user-uploaded images*.

---

## 1. Sections are positioned by Y coordinate, NOT by tree order

FigJam lays sections out by their absolute `y`, independent of their order in
`figma.currentPage.children`. Renaming, resizing, or deleting nodes can trigger an
auto-resize that pushes a section into **negative Y**, silently reordering the whole board.

**Symptom seen:** after deleting placeholders, the header section jumped to `y=-592` and the
"materials" section to `y=-206`, so they rendered *above* everything else.

**Fix — always re-flow every section from zero after structural edits:**
```javascript
const order = ["46:4","46:17","46:38", /* …in desired vertical order… */];
const GAP = 96;
let y = 0;
for (const id of order) {
  const s = await figma.getNodeByIdAsync(id);
  if (!s) continue;
  s.x = 0;
  s.y = y;
  y += s.height + GAP;   // height is current, post-resize
}
```
Do this as the LAST step of any edit that added/removed/resized content.

---

## 2. use_figma does NOT return console.log output

`console.log(...)` inside a `use_figma` call produces nothing in the tool result — the call
returns "executed with no return value". You cannot debug by logging.

**Instead, verify state with read tools:**
- `get_figjam(fileKey, nodeId)` → native structure (IDs, names, x/y/w/h, text) as XML
- `get_screenshot(fileKey, nodeId)` → visual check for clipping/overlap

Plan code to be correct without feedback, then confirm with one of the above. To "read back"
a value (e.g. list section positions), don't log it — re-fetch with `get_figjam` and read it
from the returned tree.

---

## 3. get_metadata is NOT supported on FigJam

`get_metadata` errors on `/board/` files ("FigJam files may only use get_figjam,
get_screenshot"). For structure use `get_figjam`; for pixels use `get_screenshot`.

---

## 4. Adding raster images: use the `upload_assets` tool

**Primary path — `upload_assets`.** The `upload_assets` MCP tool uploads PNG/JPG/GIF/WebP into a
FigJam `/board/` file and handles storage, commit, and canvas placement automatically (max 10MB per
asset; SVGs are NOT supported — for those use `use_figma` + `figma.createNodeFromSvg()`). Two modes:

- **Onto an existing node** — pass `count: 1` + `nodeId` → the image is set as a fill on that node.
  This is the clean way to fill a placeholder frame you already positioned: build the frame, then
  drop the image straight onto it, no manual drag and no coordinate-snapping.
- **New frames** — omit `nodeId` → each asset lands as a new frame with an image fill on the page.
  You then reposition/re-parent them (see §5 for the coordinate conversion when moving into a section).

> ✅ Verified live on a FigJam `/board/` (2026-07-15): `upload_assets(count:1)` → POST the PNG bytes to
> the returned `submitUrl` (multipart `file=@…` is preferred — the filename becomes the layer name) →
> the tool auto-creates a placed frame and returns `imageHash` + `placedOnNodeId`. Confirmed via
> `get_figjam` (new `<frame name="…">`) and `get_screenshot`. If a call ever fails, fall back to the
> manual pattern below.

**Fallback — placeholder → user drags PNGs in** (use only if `upload_assets` is unavailable or fails):

1. **Build named placeholders** — a `ROUNDED_RECTANGLE` shape-with-text whose *name* matches
   the intended image filename (e.g. `G1_template_title 1`). Lay them out where the images should go.
2. **User drags the actual PNGs onto the board** themselves (one bulk drag-drop). They land as
   loose `rounded-rectangle` image fills, usually grouped in a stray auto-created Section far
   off-canvas, named after the files (`… 2`).
3. **Map images onto placeholders by name** and delete the placeholders (§5), then remove the stray
   upload container (§6).

---

## 5. Moving a node into another section (the coordinate trap)

After `parent.appendChild(node)`, `node.x/y` become **relative to the new parent**. To make an
image land exactly where its placeholder was, convert absolute → section-relative using the
section's `absoluteTransform`:

```javascript
async function snap(placeholderId, imageId) {
  const ph  = await figma.getNodeByIdAsync(placeholderId);
  const img = await figma.getNodeByIdAsync(imageId);
  if (!ph || !img) return;

  // placeholder absolute position + size
  const ax = ph.absoluteTransform[0][2];
  const ay = ph.absoluteTransform[1][2];
  const w = ph.width, h = ph.height;
  const section = ph.parent;

  section.appendChild(img);          // re-parent FIRST
  img.resize(w, h);

  const sax = section.absoluteTransform[0][2];
  const say = section.absoluteTransform[1][2];
  img.x = ax - sax;                  // convert to section-relative
  img.y = ay - say;

  ph.remove();                       // delete the placeholder
}
```
Drive it from a `[name, placeholderId, imageId]` table built by reading both the placeholder
section and the stray upload section via `get_figjam`.

---

## 6. Clean up the stray upload container

Drag-dropped images often arrive inside an auto-created `Section` (e.g. named "Section 1") far
from your layout. After snapping every image onto its placeholder, that container is empty —
remove it:
```javascript
const junk = await figma.getNodeByIdAsync("59:241");
if (junk && junk.type === "SECTION" && junk.children.length === 0) junk.remove();
```
Verify it's empty first with `get_figjam` on that node id.

---

## 7. Name sections descriptively from the start

Avoid letter codes ("A — Canon", "B — Tagline"). They look like internal shorthand, force
the reader to decode them, and break the moment sections are reordered (the "A/B/C" no longer
matches position). Use plain descriptive names ("Rule documents — which one is live") for both
the layer-panel `node.name` AND the on-board header text. Likewise, don't reference sections by
code inside body copy ("see G", "F3") — name the thing ("see the deck-evolution section").

---

## 8. Editing text in place

To translate or reword without touching layout, walk the known node IDs and overwrite
`text.characters` only — never recreate nodes:
```javascript
for (const [id, txt] of edits) {
  const n = await figma.getNodeByIdAsync(id);
  if (n && n.type === "SHAPE_WITH_TEXT") n.text.characters = txt;
}
```
Section *names* (layer panel) are set with `n.name = "..."`, separately from the visible header
shape's text — update both when renaming a section.

For non-ASCII output (Polish, curly quotes, emoji) prefer `\uXXXX` escapes or ensure UTF-8 to
avoid mojibake in long string literals.

---

## Quick checklist for an edit session

1. `get_figjam(fileKey, "0:1")` — snapshot current structure + IDs.
2. Make text/structure edits in **one** `use_figma` call where possible.
3. If you added/removed/resized: re-flow all sections from `y=0` (section 1 above).
4. Remove empty stray containers (section 6).
5. `get_screenshot` the whole page to verify order + no clipping.
6. Tell the user any manual step that remains (e.g. dragging images, swapping actor shapes).
