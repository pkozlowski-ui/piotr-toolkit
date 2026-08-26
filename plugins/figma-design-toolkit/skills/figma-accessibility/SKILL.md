---
name: figma-accessibility
description: >
  Generate accessibility specs from Figma components: ARIA roles, labels, screen reader
  reading order, and WCAG 2.1 AA compliance audit. Load when asked about accessibility,
  WCAG, ARIA, screen reader specs, VoiceOver, TalkBack, focus order, or color contrast.
---

# figma-accessibility — Accessibility Specs from Figma

Generates screen reader specs (ARIA roles, reading order, labels) and runs
WCAG 2.1 AA contrast audits directly from Figma files.

Use together with `figma-design-toolkit:figma-console` for script execution.

## When to load
- Generating accessibility specs / handoff document for developers
- Auditing a screen for WCAG 2.1 AA compliance
- Checking color contrast of design tokens
- Creating VoiceOver / TalkBack annotations for a component
- Reviewing form accessibility (labels, errors, required indicators)

## Skill boundaries
This skill generates **specs and audits** — it reads from Figma, it does not write to canvas.
For adding annotation layers to Figma (e.g. ARIA overlay), load `figma-console` alongside this skill.

---

## Step 0 — Re-audit: check the prior report before writing a new one

Every row in the "Audit output format" table and every ARIA role mapping (below) is a call written as
fact-on-the-day: a measured ratio, or a role *guessed from the layer's name* (layer naming is
inconsistent across files — `Dropdown` might really be a `button` that opens a menu). Neither is
ever checked against what the developer actually shipped.

**Trigger:** this screen/component already has a prior accessibility audit or handoff spec (a
`docs/*accessibility*` file, a prior "Audit output" table in the conversation history, or a note
in `code-design-audit`'s a11y layer for the same screen).

**When it fires:**
1. Pull the prior findings table (or handoff spec) for this exact screen.
2. For each prior finding, check whether it was fixed as recommended — re-run the Step 1 contrast
   script or re-inspect the layer, don't assume from memory.
3. **Fixed as recommended** → skip it, no need to restate.
4. **Fixed differently, or the ARIA-role guess didn't match what got implemented** → note it
   inline in the new audit as `**Korekta:** <original finding> assumed X, actual implementation
   did Y` — this is the signal that a layer-naming pattern or a mapping-table row is unreliable
   for this project's convention, not just a one-off miss.
5. No prior report for this screen → skip this step, proceed to Step 1 normally.

---

## Step 1 — Color contrast audit

Verify the palette passes WCAG 2.1 AA **before** auditing components.

### Thresholds
| Context | Minimum ratio |
|---|---|
| Normal text (< 18pt, < 14pt bold) | **4.5 : 1** |
| Large text (≥ 18pt or ≥ 14pt bold) | **3 : 1** |
| UI components (borders, icons, input outlines) | **3 : 1** |
| Focus indicators | **3 : 1** against adjacent background |

### Every finding carries its WCAG success criterion

A finding without a criterion id is an opinion; with one it is auditable, ticketable, and speaks
the same vocabulary as the client's own compliance review. Tag **every** audit row from this crib
sheet — never ship a bare "contrast too low".

| What failed | Success criterion | Level |
|---|---|---|
| Text contrast below the thresholds above | **1.4.3** Contrast (Minimum) | AA |
| Icon / border / input outline / focus ring below 3:1 | **1.4.11** Non-text Contrast | AA |
| Meaningful image or icon-only control with no text alternative | **1.1.1** Non-text Content | A |
| Structure carried by styling only (heading, list, group, table) | **1.3.1** Info and Relationships | A |
| Meaning carried by color alone (status dot, required field, chart series) | **1.4.1** Use of Color | A |
| Control unreachable or unusable by keyboard | **2.1.1** Keyboard | A |
| Focus trapped with no way out (modal, drawer, embed) | **2.1.2** No Keyboard Trap | A |
| Tab / reading order does not follow meaning | **2.4.3** Focus Order | A |
| No visible focus indicator | **2.4.7** Focus Visible | AA |
| Touch target below 24 × 24 px | **2.5.8** Target Size (Minimum) | AA (WCAG 2.2) |
| Touch target below 44 × 44 px | **2.5.5** Target Size (Enhanced) | AAA — but it is the iOS/Android HIG floor, so treat a sub-44 tap target on mobile as a real defect and cite 2.5.8 as the compliance hook |
| Input with no label or instruction | **3.3.2** Labels or Instructions | A |
| Error not identified in text (color/border only) | **3.3.1** Error Identification | A |
| Component with no accessible name, role, or state | **4.1.2** Name, Role, Value | A |

Two rules on citing: (1) **level travels with the id** — a AAA finding is advice, an A/AA finding is
compliance, and collapsing the two oversells the report; (2) when a screen cannot be measured
(no rendered state, missing token resolution), report it as **unmeasured**, not as passing — the
criterion tells the reader what was *supposed* to be checked.

### Script: extract all COLOR variables with resolved values

```javascript
const vars = await figma.variables.getLocalVariablesAsync();
const colors = vars
  .filter(v => v.resolvedType === 'COLOR')
  .map(v => {
    const modeId = Object.keys(v.valuesByMode)[0];
    const val = v.valuesByMode[modeId];
    // Convert 0–1 range to 0–255 hex for readability
    const hex = [val.r, val.g, val.b]
      .map(c => Math.round(c * 255).toString(16).padStart(2, '0'))
      .join('').toUpperCase();
    return { name: v.name, id: v.id, hex: '#' + hex, r: val.r, g: val.g, b: val.b };
  });
return colors;
// → Use pairs (foreground / background) in the contrast formula below
```

### Contrast ratio formula

```javascript
function luminance({ r, g, b }) {
  return [r, g, b]
    .map(c => c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4))
    .reduce((acc, c, i) => acc + c * [0.2126, 0.7152, 0.0722][i], 0);
}
function contrast(fg, bg) {
  const L1 = luminance(fg), L2 = luminance(bg);
  const [hi, lo] = L1 > L2 ? [L1, L2] : [L2, L1];
  return (hi + 0.05) / (lo + 0.05);
}
// contrast(fgColor, bgColor) >= 4.5  →  AA pass for normal text
// contrast(fgColor, bgColor) >= 3.0  →  AA pass for large text / UI components
```

⚠ Common failures: lime/neon accents on white (`#C8FF00` = 1.7:1), light gray on white (`#767676` = 4.48:1 — borderline), primary blue on dark background (check both modes if variables have light/dark).

---

## Step 2 — Extract component tree for ARIA mapping

```javascript
// Adjust nodeId to the frame or component to audit
const node = await figma.getNodeByIdAsync('NODE_ID');

function extractTree(n, depth = 0) {
  const info = {
    depth,
    type: n.type,
    name: n.name,
    visible: n.visible,
  };
  if (n.type === 'TEXT') {
    info.text = n.characters;
    info.fontSize = n.fontSize;
  }
  if ('children' in n) {
    info.children = n.children.map(c => extractTree(c, depth + 1));
  }
  return info;
}
return extractTree(node);
// → Use this tree to map each layer to an ARIA role (see table below)
```

---

## ARIA role mapping

| Figma layer name pattern | ARIA role | Required attributes |
|---|---|---|
| `Button`, `CTA`, `Submit`, `Action` | `button` | If it navigates → use `a` with `href` instead |
| `Input`, `Text field`, `Field` | `textbox` | `aria-label` or `aria-labelledby` pointing to label node |
| `Textarea` | `textbox` | `aria-multiline="true"` |
| `Dropdown`, `Select`, `Combobox` | `combobox` | `aria-expanded`, `aria-haspopup="listbox"` |
| `Checkbox` | `checkbox` | `aria-checked` (true / false / mixed) |
| `Radio`, `Radio button` | `radio` | Parent container: `radiogroup` |
| `Toggle`, `Switch` | `switch` | `aria-checked` |
| `Modal`, `Dialog`, `Overlay` | `dialog` | `aria-modal="true"`, `aria-labelledby` → heading id |
| `Alert`, `Error message`, `Toast` | `alert` | Auto-announces — use only for errors / confirmations |
| `Step indicator`, `Breadcrumb` | `list` of `listitem` | Active step: `aria-current="step"` |
| `Progress bar` | `progressbar` | `aria-valuenow`, `aria-valuemin`, `aria-valuemax` |
| `Navigation`, `Nav` | `nav` | `aria-label` to distinguish multiple navs |
| `Card`, `List item` | `listitem` | Parent: `list` or `ul` |
| `Icon` (decorative) | — | `aria-hidden="true"` — no role, no label |
| `Icon` (interactive, no text) | `button` | `aria-label` required |

---

## Step 3 — Form accessibility checklist

For every form field component, verify all of the following:

```
☐ Label is visible text — NOT placeholder-only (fails when field is filled)
☐ Label connected to input: aria-labelledby="[label-node-id]" or aria-label on input
☐ Required fields: aria-required="true" + visible indicator that is NOT color alone
    (e.g. asterisk with screen-reader text "required")
☐ Error state:
    - aria-invalid="true" on the input
    - aria-describedby="[error-node-id]" pointing to the error message
    - Error message layer: role="alert" or aria-live="polite"
☐ Hint / helper text: aria-describedby (separate id from error)
☐ Disabled state: aria-disabled="true" — not just visual graying
☐ Multi-step form: aria-current="step" on the active step indicator
☐ Submission success/failure: aria-live="polite" region that announces the result
```

### Script: find all text layers in a form frame (label/error audit)

```javascript
const frame = await figma.getNodeByIdAsync('FRAME_NODE_ID');
const textNodes = frame.findAll(n => n.type === 'TEXT');
return textNodes
  .filter(n => n.visible)
  .map(n => ({
    name: n.name,
    text: n.characters,
    fontSize: n.fontSize,
    parentName: n.parent?.name
  }));
// → Verify: every input has an associated label, error texts are present in error state
```

---

## Step 4 — Screen reader reading order

Reading order follows Figma auto-layout: **top → bottom, left → right** (LTR).
Layer order in the panel = DOM order = screen reader order.

```javascript
// Extract visible text in reading order
const frame = await figma.getNodeByIdAsync('FRAME_NODE_ID');

function readingOrder(node, path = []) {
  const result = [];
  if (node.type === 'TEXT' && node.visible) {
    result.push({
      path: [...path, node.name].join(' > '),
      text: node.characters,
      fontSize: node.fontSize
    });
  }
  if ('children' in node) {
    for (const child of node.children) {
      result.push(...readingOrder(child, [...path, node.name]));
    }
  }
  return result;
}
return readingOrder(frame);
// → Verify: logical reading order matches what a sighted user scans
// → Flag: groups with absolute positioning (read in layer order, not visual position)
```

⚠ Groups and frames with absolute positioning break reading order.
Interactive elements (buttons, inputs) must appear in the order they are reached by Tab key.

---

## Audit output format

Audit findings (what is wrong) are a different table from the handoff spec (what to build) below.
One row per finding, criterion mandatory:

| # | Finding (located: frame → layer) | Criterion | Level | Severity | Measured | Fix |
|---|---|---|---|---|---|---|
| 1 | Login → helper text on `bg/surface` | 1.4.3 Contrast (Minimum) | AA | Critical | 3.1:1 (needs 4.5:1) | Bind to `text/secondary` (5.7:1) |
| 2 | Login → "show password" icon button | 4.1.2 Name, Role, Value | A | Major | no name | `aria-label="Show password"` |
| 3 | Verify → code inputs | 2.5.8 Target Size (Minimum) | AA | Major | 20 × 20 px | Grow to ≥ 44 × 44 px hit area |

Group by criterion when the same one fires across many layers — that is **one** systemic defect
(a token or a component), not N findings.

---

## Handoff output format

When generating accessibility specs for developers, output as a structured table
— one row per interactive or semantically meaningful element:

| Component | HTML element / ARIA role | Label source | States | Notes |
|---|---|---|---|---|
| Email input | `<input type="email">` | `aria-labelledby="label-email"` | `aria-required="true"`, `aria-invalid` on error | Error: `aria-describedby="error-email"` |
| Submit button | `<button>` | Visual text "Submit" | `aria-disabled` when form invalid | — |
| Step 1 indicator | `<li role="listitem">` | `aria-label="Step 1 of 4"` | `aria-current="step"` when active | — |
| Verification code input | `<input type="text" inputmode="numeric">` | `aria-labelledby="label-code"` | `aria-required="true"`, `aria-invalid` on wrong code | Autocomplete hint: `autocomplete="one-time-code"` |
| Error banner | `<div role="alert">` | Dynamic content | Always `aria-live="assertive"` | Appears on failed submission |

Include all states: default, focus, error, disabled, success.
