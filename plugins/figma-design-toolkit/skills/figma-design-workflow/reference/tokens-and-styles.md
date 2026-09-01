# Tokens, variables & text styles — figma-design-workflow

> **Load when:** planning a variable collection, creating/binding text styles, or binding color /
> spacing / radius variables in code.

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
- **⚠️ A text style sets typography ONLY — NOT fill color.** After `setTextStyleIdAsync` the node's
  `fills` stays its default solid black, **unbound** → a hardcoded-color violation that's easy to miss
  (the text looks fine, but the audit flags it). After applying the style, **bind the fill separately**:
  `node.fills = [figma.variables.setBoundVariableForPaint(node.fills[0] || {type:'SOLID',color:{r:0,g:0,b:0},opacity:1}, 'color', textColorVar)]`
  (e.g. `color/text/body` for default, `color/text/muted` for secondary). Wrap text creation in a helper
  (`txt(parent, styleName, chars, colorVar)`) so style + font-load + characters + fill-bind always happen together.

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

## Binding FLOAT variables (spacing & radius)

> **⚠️ Variable NAMES may not equal pixel VALUES — always map by value, never by name.**
> Many design systems name spacing on a rem/Tailwind scale where `spacing/N = N × 4 px`
> (so `spacing/4` = 16px, `spacing/16` = **64px**). Looking up `name === 'spacing/16'` to get
> 16px silently gives you 64px (real bug: a 64px gap where 16 was intended). Worse, names like
> `spacing/24`/`spacing/20` often **don't exist** → `find` returns `undefined` → `setBoundVariable`
> is silently skipped → the literal px stays UNBOUND (a token violation no error surfaces).
> **Build a px→variable map once and look up by resolved value:**

```javascript
const vars = await figma.variables.getLocalVariablesAsync();
const _sp = vars.filter(v => /^spacing\//.test(v.name))
  .map(v => ({ v, val: v.valuesByMode[Object.keys(v.valuesByMode)[0]] }));
const spPx = px => _sp.find(s => s.val === px)?.v;   // spPx(16) → the variable whose VALUE is 16px
// helper that sets value AND binds (kills the "undefined → unbound literal" trap):
const setSp = (node, prop, px) => { node[prop] = px; const v = spPx(px); if (v) node.setBoundVariable(prop, v); };

const sp8   = spPx(8);
const radMd = vars.find(v => v.name === 'radius/md' && v.resolvedType === 'FLOAT');

// Bind padding / gap — one call per property
node.setBoundVariable('paddingTop',    sp8);
node.setBoundVariable('paddingBottom', sp8);
node.setBoundVariable('paddingLeft',   sp8);
node.setBoundVariable('paddingRight',  sp8);
node.setBoundVariable('itemSpacing',   sp8);

// Uniform corner radius
node.setBoundVariable('cornerRadius', radMd);

// Mixed corners (when node.cornerRadius === figma.mixed) — bind each individually
node.setBoundVariable('topLeftRadius',     radMd);
node.setBoundVariable('topRightRadius',    radMd);
node.setBoundVariable('bottomRightRadius', radMd);
node.setBoundVariable('bottomLeftRadius',  radMd);
```

**Spacing scale (standard):** 4, 8, 12, 16, 20, 24, 32, 40, 48, 64px — values outside this scale need justification.

**Verify:** `node.boundVariables?.paddingTop?.type === 'VARIABLE_ALIAS'` → bound ✓

---
