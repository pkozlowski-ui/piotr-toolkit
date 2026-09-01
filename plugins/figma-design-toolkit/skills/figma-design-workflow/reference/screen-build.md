# Screen & page build recipes — figma-design-workflow

> **Load when:** building a new screen or page, discovering what an existing file uses,
> editing text/fills on instances without detaching, or creating a missing icon.

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
