// Verified helper library for FigJam diagrams.
// Copy this block verbatim at the top of every `use_figma` call.
// Tested and confirmed working in FigJam. Do not modify function signatures.

// ── FONT LOADING (required before any text) ──────────────────────────────
await Promise.all([
  figma.loadFontAsync({ family: "Inter", style: "Regular" }),
  figma.loadFontAsync({ family: "Inter", style: "Bold" }),
]);

// ── COLOUR PALETTE ───────────────────────────────────────────────────────
const C = {
  blue:   { r: 0.29, g: 0.62, b: 1.00 },  // user / admin actions
  purple: { r: 0.49, g: 0.23, b: 0.93 },  // system state changes
  orange: { r: 0.96, g: 0.55, b: 0.18 },  // decisions / warnings
  green:  { r: 0.15, g: 0.73, b: 0.48 },  // success / end states
  gray:   { r: 0.60, g: 0.60, b: 0.65 },  // neutral / actor
  ink:    { r: 0.10, g: 0.10, b: 0.15 },  // body text
  white:  { r: 1.00, g: 1.00, b: 1.00 },
};

// ── SECTION ──────────────────────────────────────────────────────────────
// The section IS the background — set fills on the section, not via a child shape.
//
// ⚠ CRITICAL ORDER: set fills AFTER adding all children AND after adding a spacer anchor.
//   FigJam sections do NOT expand programmatically during script execution.
//   Even when fills are set "last", the section's reported bounding box is the
//   pre-script size — so the fill only covers a portion of the visible content.
//
// ✅ CORRECT PATTERN — use an invisible spacer anchor:
//   1. Add all content (header, tables, boxes, etc.)
//   2. Find maxX and maxY across all children
//   3. Append a 1×1 invisible spacer at (maxX + PAD, maxY + PAD)
//   4. THEN set s.fills = [{ type: "SOLID", color: C.white }]
//   The spacer forces the section to include that point in its bounding box,
//   so the white fill covers the full content area + padding.
//
// ⚠ SectionNode does NOT have resize() — calling it causes "TypeError: not a function".
// ⚠ DO NOT add a white shape as the first child to fake a background — anti-pattern.
//
// Pattern:
//   const s = mkSection("Name", x, y);        // create, no fills yet
//   // ... add all content ...
//   mkSectionAnchor(s, 80, 80);               // anchor fills, add padding
//   s.fills = [{ type: "SOLID", color: C.white }];  // set LAST
function mkSection(name, x, y) {
  const s = figma.createSection();
  s.name = name; s.x = x; s.y = y;
  // DO NOT set fills here — add content, call mkSectionAnchor, then set fills
  return s;
}

// ── SECTION ANCHOR (invisible spacer to force section bounding box) ───────
// Call AFTER adding all content, BEFORE setting s.fills.
// padX / padY: breathing room beyond the last child element.
function mkSectionAnchor(sec, padX, padY) {
  padX = padX || 80; padY = padY || 80;
  let maxX = 200, maxY = 200;
  for (const child of sec.children) {
    if (child.name === "__spacer__") continue;
    const r = child.x + child.width;
    const b = child.y + child.height;
    if (r > maxX) maxX = r;
    if (b > maxY) maxY = b;
  }
  const spacer = figma.createShapeWithText();
  spacer.name = "__spacer__";
  spacer.shapeType = "SQUARE";
  spacer.resize(1, 1);
  spacer.fills = []; spacer.strokes = [];
  spacer.text.characters = "";
  sec.appendChild(spacer);
  spacer.x = maxX + padX;
  spacer.y = maxY + padY;
}

// ── SECTION HEADER (title + subtitle) ────────────────────────────────────
// Always call this instead of a bare mkText description.
// title:    bold headline summarising the option in plain language
// subtitle: 1–2 sentences explaining what happens / why it matters
//
// Font sizes use FigJam's native text size scale:
//   Small=16 | Medium=24 | Large=40 | Extra large=64 | Huge=96
//   Title → Medium (24),  Subtitle → Small (16)
function mkHeader(parent, title, subtitle) {
  mkText(parent, title,    64, 28,  1400, 40,  24, true);   // Medium
  mkText(parent, subtitle, 64, 80,  1400, 44,  16, false);  // Small
}

// ── COLOURED STEP BOX ────────────────────────────────────────────────────
// shapeType: "SQUARE" | "HEXAGON" | "DIAMOND" | "ELLIPSE" | "ROUNDED_RECTANGLE"
// Hexagons are taller (177px) and are vertically offset -44px to stay centred.
function mkBox(parent, label, rx, ry, shapeType, color) {
  const isHex = shapeType === "HEXAGON";
  const s = figma.createShapeWithText();
  s.shapeType = shapeType;
  s.resize(176, isHex ? 177 : 88);
  s.fills   = [{ type: "SOLID", color }];
  s.strokes = [];
  s.text.characters          = label;
  s.text.fontSize            = 11;
  s.text.fills               = [{ type: "SOLID", color: C.white }];
  s.text.textAlignHorizontal = "CENTER";
  parent.appendChild(s);
  s.x = rx;
  s.y = isHex ? ry - 44 : ry;
  return s;
}

// ── PLAIN TEXT (transparent box) ─────────────────────────────────────────
// w / h: size of the invisible container. Text wraps within width.
//
// ⚠ ALWAYS use FigJam's native text size scale for standalone text elements
//   (headers, subtitles, annotations — anything NOT embedded inside a coloured shape):
//     Small = 16  →  annotations, captions, fine print
//     Medium = 24  →  section titles, bold headlines
//     Large = 40  →  prominent labels
//     Extra large = 64 / Huge = 96  →  very large display text
//   Text INSIDE shapes (step boxes, pros/cons) may use any size.
//
// ⚠ TEXT CLIPPING: always be generous with h.
//   Rule of thumb: each line ≈ 20px at size 16, ≈ 28px at size 24.
//   Add 30% buffer on top of the minimum you calculate.
//   If in doubt, use h=200 — sections auto-expand so excess height is harmless.
function mkText(parent, content, rx, ry, w, h, size, bold) {
  const s = figma.createShapeWithText();
  s.shapeType = "SQUARE";
  s.resize(w, h || 80);
  s.fills   = [];
  s.strokes = [];
  s.text.characters          = content;
  s.text.fontSize            = size || 16;  // default: Small (16)
  s.text.fontName            = { family: "Inter", style: bold ? "Bold" : "Regular" };
  s.text.fills               = [{ type: "SOLID", color: C.ink }];
  s.text.textAlignHorizontal = "LEFT";
  parent.appendChild(s);
  s.x = rx; s.y = ry;
  return s;
}

// ── ADVANTAGES BOX (green border, light green fill) ───────────────────────
// content: "ADVANTAGES:\n• Point one\n• Point two\n• Point three"
//
// HEIGHT FORMULA — calculate before calling, never guess:
//   h = (lineCount × 22) + 20 padding
//   lineCount = 1 (header) + number of bullet points
//   Example: "ADVANTAGES:\n• A\n• B\n• C" → 4 lines → h = (4×22)+20 = 108 → use 120
//   When in doubt, go larger — clipped text is the worst visible error.
//
// ⚠ Use SQUARE not ROUNDED_RECTANGLE — heavily-rounded shapes consume
//   internal space and clip text even when h looks correct.
function mkPros(parent, content, rx, ry, w, h) {
  const s = figma.createShapeWithText();
  s.shapeType    = "SQUARE";
  s.resize(w || 580, h || 110);
  s.fills        = [{ type: "SOLID", color: { r: 0.93, g: 1.00, b: 0.95 } }];
  s.strokes      = [{ type: "SOLID", color: { r: 0.15, g: 0.73, b: 0.48 } }];
  s.strokeWeight = 2;
  s.text.characters          = content;
  s.text.fontSize            = 11;
  s.text.fills               = [{ type: "SOLID", color: C.ink }];
  s.text.textAlignHorizontal = "LEFT";
  parent.appendChild(s);
  s.x = rx; s.y = ry;
  return s;
}

// ── SHORTCOMINGS BOX (red border, light red fill) ─────────────────────────
// Same height formula as mkPros. 4 bullets → h=110, 5 bullets → h=132.
function mkCons(parent, content, rx, ry, w, h) {
  const s = figma.createShapeWithText();
  s.shapeType    = "SQUARE";
  s.resize(w || 700, h || 110);
  s.fills        = [{ type: "SOLID", color: { r: 1.00, g: 0.95, b: 0.95 } }];
  s.strokes      = [{ type: "SOLID", color: { r: 0.90, g: 0.27, b: 0.27 } }];
  s.strokeWeight = 2;
  s.text.characters          = content;
  s.text.fontSize            = 11;
  s.text.fills               = [{ type: "SOLID", color: C.ink }];
  s.text.textAlignHorizontal = "LEFT";
  parent.appendChild(s);
  s.x = rx; s.y = ry;
  return s;
}

// ── ARROW CONNECTOR ──────────────────────────────────────────────────────
function mkArrow(parent, a, b) {
  const c = figma.createConnector();
  parent.appendChild(c);
  c.connectorStart          = { endpointNodeId: a.id, magnet: "AUTO" };
  c.connectorEnd            = { endpointNodeId: b.id, magnet: "AUTO" };
  c.connectorEndStrokeCap   = "ARROW_LINES";
  c.connectorStartStrokeCap = "NONE";
  return c;
}

// ── ACTOR ICON (native FigJam User shape) ────────────────────────────────
// Uses the real FigJam "Shapes > Advanced > User" component via importComponentByKeyAsync.
// Falls back to assembled shapes if the import fails.
// mkActor is async — always await it.
//
// Component key confirmed working: b3abe69f2adf828533836dc0e44328a9f74c706c
// Size: 88×88px. Label set via the nested "Text Label [PS_TEXT]" text node.
async function mkActor(parent, label, x, y) {
  const FIGJAM_USER_KEY = "b3abe69f2adf828533836dc0e44328a9f74c706c";
  try {
    const comp = await figma.importComponentByKeyAsync(FIGJAM_USER_KEY);
    const inst = comp.createInstance();
    inst.resize(88, 88);
    parent.appendChild(inst);
    inst.x = x; inst.y = y;
    // Set the label — must target by name, not by index (other text nodes exist inside)
    const labelNode = inst.findOne(n => n.type === "TEXT" && n.name === "Text Label [PS_TEXT]");
    if (labelNode) labelNode.characters = label;
    return inst;
  } catch(e) {
    // Fallback: assembled shapes if component import fails
    const head = figma.createShapeWithText();
    head.shapeType = "ELLIPSE"; head.resize(40, 40);
    head.fills = [{ type: "SOLID", color: C.gray }]; head.strokes = [];
    head.text.characters = "";
    parent.appendChild(head); head.x = x + 12; head.y = y;
    const body = figma.createShapeWithText();
    body.shapeType = "ROUNDED_RECTANGLE"; body.resize(64, 44);
    body.fills = [{ type: "SOLID", color: C.gray }]; body.strokes = [];
    body.text.characters = "";
    parent.appendChild(body); body.x = x; body.y = y + 46;
    mkText(parent, label, x, y + 98, 80, 24, 11, false);
  }
}

// ── FLOW ROW ─────────────────────────────────────────────────────────────
// steps = [{ t: "Label", hex: false, color: C.blue }, ...]
// Returns array of created nodes.
//
// Spacing constants — tuned for balanced clarity + compactness:
//   SY=195   — flow row sits close below the subtitle (title=24px + subtitle=16px need more room)
//   GAP=408  — center-to-center horizontal distance between steps
//   FX=265   — x of first step (leaves room for actor icon on the left)
const GAP = 408, FX = 265, SY = 195;

function mkFlow(parent, steps) {
  const nodes = steps.map((s, i) =>
    mkBox(parent, s.t, FX + GAP * i, SY, s.hex ? "HEXAGON" : "SQUARE", s.color || (s.hex ? C.purple : C.blue))
  );
  nodes.forEach((n, i) => { if (i < nodes.length - 1) mkArrow(parent, nodes[i], nodes[i + 1]); });
  return nodes;
}
