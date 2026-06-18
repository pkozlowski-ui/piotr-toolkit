---
name: figma-ds-init
description: Scaffold the design-system documentation + workflow layer in a project. Sets up the per-project DS knowledge structure (registry, component catalog, canonical patterns) and drops in the universal, auto-discovering build kit + token-compliance rules. Use when starting Figma/DS work in a new project, or when a project has ad-hoc DS docs that should be standardized. Triggers: "set up design system docs", "zainicjalizuj DS", "ustaw design system", "scaffold DS workflow", "bootstrap figma docs".
---

# figma-ds-init — Design System docs & workflow scaffolding

Establishes two layers of DS knowledge in a project, with a clear boundary:

- **UNIVERSAL** (ships from this package, same in every project, improve once → propagates):
  methodology + gotchas + audits → skill `figma-design-workflow`; paste-in helpers → `figma-build-kit.md`.
- **PER-PROJECT** (collected as you build): `figma-registry.json` (Node IDs), `components.md`
  (use cases), `canonical-patterns.md` (what to clone), token names/scale, navigation rules.

This skill scaffolds the per-project files (empty/templated) and drops the universal build kit in,
so a new project starts with universal rules pre-filled and per-project slots ready to fill.

Load **with** `figma-design-workflow` (the methodology) — this skill only sets up the files.

---

## When to run
- New project that will involve Figma/DS work.
- Existing project with ad-hoc DS docs to standardize.
- Run once per project. Re-running is safe — never overwrite a populated file (see Step 0).

## Step 0 — detect & don't clobber
```
ls docs/design-system/ 2>/dev/null
```
- For each target file: if it exists AND is non-trivial (registry has entries / catalog has components) → **skip it, report "kept"**. Only create what's missing. Never overwrite collected per-project knowledge.

## Step 1 — create the structure

```
docs/design-system/
  figma-build-kit.md            ← UNIVERSAL (write verbatim from "Build kit template" below)
  figma-registry.json           ← per-project skeleton (Step 2)
  components.md                 ← per-project template (Step 3)
  01-foundations/
    ux-writing.md               ← per-project CONTENT canon (Step 4b) — content is part of the DS
  03-patterns/
    navigation-shell.md         ← per-project (create empty stub with heading)
    ux-writing-audit-playbook.md ← per-project (stub: harvest→register→fix; fill on first audit)
  04-page-blueprints/
    canonical-patterns.md       ← per-project template (Step 4)
```

## Step 2 — figma-registry.json skeleton
```json
{
  "_meta": {
    "purpose": "Machine-readable Figma component registry. Read BEFORE figma_search_components each session.",
    "figmaFileKey": "<fill once known>",
    "updatePolicy": "New DS component → add entry in the SAME commit. Update on rename / new prop.",
    "lastSync": "<date>"
  }
}
```
Then (optional, recommended) run the catalog pass from `figma-design-workflow` ("How to catalog a new
design system") to populate real Node IDs + the spacing scale (record actual px values — see build kit).

## Step 3 — components.md template
Human-readable catalog. Seed with the canonical section structure (adjust per project):
```
# Component Catalog
> Read this before figma_search_components. Machine IDs live in figma-registry.json.

## 01 – Foundations   (Typography, Colors, Spacing, Icons, Radius)
## 02 – Core           (Buttons, Badges, Chips, Dividers)
## 03 – Forms          (Input, Select, Checkbox, Field, …)
## 04 – Navigation     (TopBar, NavRail, Breadcrumb, Tabs, …)
## 05 – Layout         (Cards, Panels, SplitLayout)
## 06 – Feedback       (Toasts, Alerts, Empty states, Loading)
## 07 – Patterns       (Composite patterns, wizards)
```

## Step 4 — canonical-patterns.md template
```
# Canonical Patterns — clone, don't reinvent
> For repeating composites (filter bar, table header, screen shells): CLONE the existing canon
> and override content. Don't build a bespoke variation. Clone = consistency + free instance-ratio.
> Mechanic: `const x = (await figma.getNodeByIdAsync(ID)).clone(); parent.appendChild(x);`

## (fill as you go) filter-bar — `<node id>`
## (fill as you go) table-header-row — `<node id>`
## (fill as you go) list / wizard / drawer shells — `<node id>`
```

## Step 4b — `01-foundations/ux-writing.md` (content canon — content is part of the DS)
Content is a first-class DS layer, not an afterthought. Scaffold this file with the UNIVERSAL rules
(from `figma-design-workflow` → "Content / UX-writing") pre-filled, and PER-PROJECT slots to fill as you build.
Template:
````md
# UX writing — <project>

> Content layer of the DS. Read before writing any user-facing string. Audit copy like tokens (`copyAudit`).

## Voice registers (PER-PROJECT — pick by AUDIENCE, not screen)
- <register A, e.g. internal/admin> — operational, scannable.
- <register B, e.g. consumer funnel> — warm, benefit-first, low-friction, plain/ESL.
- <register C, e.g. returning-user dashboard> — status + next-action + "no action needed".
- AI layer — advisory (attribution→finding→action, hedged, never blocks); brand exposure per audience (often white-label for end-users).

## Capitalization by surface (UNIVERSAL)
sentence-case default · UPPERCASE-via-style only for eyebrow + table-header · Title Case only for proper nouns +
formal data-field labels. Descriptive categories/filters = sentence case. (full table → figma-design-workflow)

## Action-label canon (PER-PROJECT) — one base label per action
| Action | Canonical | Variants | Kill |

## Status / badge lexicon (PER-PROJECT) — one label per state

## Glossary (PER-PROJECT) — one canonical string per concept; list ghost/forbidden terms
| Use | Avoid | Note |

## Mechanics
buttons verb-first/sentence/no-period/no-glyph · helper fragment→no period, sentence→period · errors full sentence+period, supportive · year `2026/27` · `…` ellipsis · locale (pick one) · no placeholders ship.
````
Per-experience audit findings live OUTSIDE the repo if the project uses a vault (e.g. Obsidian `Design Guidelines/Audits/`); otherwise under `docs/design-system/_audit/`.

## Step 5 — wire into CLAUDE.md
Append a **DS rules** block to the project `CLAUDE.md` (or confirm it exists). Minimum:

```
## Design System — workflow rules
- Pre-flight (MANDATORY) before any screen-building figma_execute:
  - Krok 0: paste the helper kit from docs/design-system/figma-build-kit.md; for lists/wizards/
    drawers — clone the canonical shell from 04-page-blueprints/canonical-patterns.md (don't reinvent).
  - Krok 1: read docs/design-system/figma-registry.json (replaces figma_search_components).
  - Krok 2: emit the UI-atom → DS-component mapping table before writing the script (incl. a copy column —
    each string's register×surface per 01-foundations/ux-writing.md).
- Token compliance: every fill/stroke bound (setBoundVariableForPaint), every text → setTextStyleIdAsync
  + fill bound separately, every padding/gap/radius bound (map spacing by VALUE — names ≠ px).
- Copy compliance (content = part of the DS): capitalization by surface, verb-first buttons, no glyph/placeholder,
  register by audience, one canonical term per concept — per 01-foundations/ux-writing.md.
- After each screen: run tokenAudit + instanceRatioAudit + copyAudit (instance = opaque) from the build kit.
  issueCount:0, pass:true (≥95%), copy count:0 before "done".
- Collection rules: new DS component → figma-registry.json + components.md in the same commit;
  new clonable composite → canonical-patterns.md; project-specific gotcha → memory.
- **Definition of Done — a new DS component is NOT "done" until all of:**
  1. token-compliant (tokenAudit issueCount:0);
  2. **placed on its DS page wrapped in a spec-card** (specCard() — title + 1-line desc + the master), in
     the page's master container, NOT loose on the canvas; Foundations = token-gallery, not spec-card;
  3. **scaleY = +1** (`relativeTransform[1][1] > 0` — not flipped); section at abs (0,0);
  4. registry entry (id, type, variants, props, use);
  5. components.md entry (Kiedy / Nie używaj gdy);
  6. WCAG checklist if interactive.
- **Naming canon:** the registry/components.md key MUST equal the exact Figma node name. Drift
  (`next-steps-card` vs `NextStepsCard`, `Divider/CloseButton` vs `CloseButton`) is a bug — fix in Figma.
- **Tombstones, not deletes:** a removed/merged component keeps a marker in both files (`_deprecated:true`
  + 🗑️ in registry, `~~Name~~` in components.md). Never delete a component before A4 (0 instances) — see figma-ds-tools.
```

---

## Build kit template — write VERBATIM to `docs/design-system/figma-build-kit.md`

> Universal + **auto-discovering**: spacing/radius mapped by VALUE (handles rem/Tailwind naming),
> color tokens discovered by semantic role with fallbacks (works before token names are known).
> Tighten the discovery patterns once the project's token names are recorded in the registry.

````markdown
# Figma Build Kit — paste-in helpers

> Paste at the top of EVERY screen/component-building `figma_execute`. Encodes token-binding
> gotchas so they can't be gotten wrong. After build → run the audits (instance = opaque).

## Why (recurring traps)
1. `spacing/N` often = N×4 px (rem scale) → `spacing/16` = 64px, not 16. Map by VALUE.
2. `setTextStyleIdAsync` sets typography only — fill stays unbound black. Always bind fill after.
3. FILL / `layoutGrow=1` won't expand if parent hugs its primary axis → set parent `primaryAxisSizingMode='FIXED'`.
4. `figma_execute` is NOT transactional — on error/timeout partial nodes persist; read state before retry.

## KIT
```javascript
const _vars = await figma.variables.getLocalVariablesAsync();
const _styles = await figma.getLocalTextStylesAsync();
const _val = v => v.valuesByMode[Object.keys(v.valuesByMode)[0]];

// spacing & radius — BY VALUE (px), never by name
const _sp  = _vars.filter(v => v.resolvedType === 'FLOAT' && /spac|gap/i.test(v.name)).map(v => ({ v, val: _val(v) }));
const spPx = px => _sp.find(s => s.val === px)?.v;
const setSp = (n, p, px) => { n[p] = px; const v = spPx(px); if (v) n.setBoundVariable(p, v); };
const _rad  = _vars.filter(v => v.resolvedType === 'FLOAT' && /rad|corner/i.test(v.name)).map(v => ({ v, val: _val(v) }));
const radPx = px => _rad.find(r => r.val === px)?.v;
const setRadius = (n, px) => { const v = radPx(px); if (v) n.setBoundVariable('cornerRadius', v); };

// color tokens — discovered by semantic role (first match wins; tighten per project)
const _color = res => { for (const re of res) { const v = _vars.find(x => x.resolvedType === 'COLOR' && re.test(x.name)); if (v) return v; } return null; };
const TOK = {
  textBody:  _color([/text\/(body|default|primary|fg)/i, /(^|\/)foreground$/i, /(^|\/)text$/i]),
  textMuted: _color([/text\/(muted|secondary|subtle|tertiary)/i, /muted/i]),
  surface:   _color([/surface\/(default|card|base)/i, /background\/(default|base)/i, /(^|\/)card$/i, /(^|\/)background$/i]),
  border:    _color([/border\/(subtle|default)/i, /(^|\/)border$/i]),
};

function bindFill(node, tokenVar, baseHex = { r: 0, g: 0, b: 0 }) {
  if (!tokenVar) return;
  const base = (node.fills?.[0]?.type === 'SOLID') ? node.fills[0] : { type: 'SOLID', color: baseHex, opacity: 1 };
  node.fills = [figma.variables.setBoundVariableForPaint(base, 'color', tokenVar)];
}
function bindStroke(node, tokenVar, w = 1) { if (!tokenVar) return; node.strokes = [figma.variables.setBoundVariableForPaint({ type: 'SOLID', color: { r: .85, g: .85, b: .85 }, opacity: 1 }, 'color', tokenVar)]; node.strokeWeight = w; }

const styleId = names => { for (const n of [].concat(names)) { const s = _styles.find(x => x.name === n || x.name.endsWith('/' + n)); if (s) return s.id; } return _styles[0]?.id; };
async function txt(parent, styleName, chars, tokenVar = TOK.textBody) {
  const t = figma.createText(); parent.appendChild(t);
  await t.setTextStyleIdAsync(styleId(styleName));
  await figma.loadFontAsync(t.fontName);   // load AFTER the style sets the font
  t.characters = chars;
  bindFill(t, tokenVar);                    // the step everyone forgets
  return t;
}

// DS-PAGE DOC LAYOUT — every component on a component-doc page (02–07) lives in a titled spec-card.
// Readable, consistent, self-labelling. (Foundations uses a swatch grid bound to live vars, not spec-cards.)
async function specCard(master, title, desc) {        // master = COMPONENT / COMPONENT_SET node
  const c = figma.createFrame(); c.name = 'spec-card/' + title; c.layoutMode = 'VERTICAL';
  setSp(c, 'itemSpacing', 16); ['paddingTop','paddingBottom','paddingLeft','paddingRight'].forEach(p => setSp(c, p, 24));
  setRadius(c, 12); bindFill(c, TOK.surface, { r: 1, g: 1, b: 1 }); bindStroke(c, TOK.border, 1);
  c.layoutSizingHorizontal = 'HUG'; c.layoutSizingVertical = 'HUG';
  const head = figma.createFrame(); head.name = 'head'; head.layoutMode = 'VERTICAL'; head.fills = [];
  setSp(head, 'itemSpacing', 2); head.layoutSizingHorizontal = 'HUG'; head.layoutSizingVertical = 'HUG'; c.appendChild(head);
  await txt(head, 'label/lg', title, TOK.textBody);
  if (desc) await txt(head, ['body/sm','body'], desc, TOK.textMuted);
  c.appendChild(master);   // reparent master INTO the card — instances are unaffected by master position
  return c;
}
// Page master = one VERTICAL auto-layout frame per DS page ("DS-<Name>", gap 48, padding 48, fill surface),
// living inside the page's SECTION at abs (0,0). Append each specCard() to it, then resize the SECTION to
// master.width+48 / master.height+48. Audit before "done": every component sits in a spec-card; scaleY=+1.
```

## Audits (instance = OPAQUE — do NOT recurse into instances)
```javascript
function tokenAudit(screen) {
  const SP = new Set([4,8,12,16,20,24,32,40,48,64]); const issues = [];
  (function walk(n, inInst){ for (const c of (n.children || [])) { const inside = inInst || n.type === 'INSTANCE';
    if (!inside) {
      ['fills','strokes'].forEach(k => { const p = c[k]; if (!p || p === figma.mixed || !p.length) return;
        p.forEach((pt,i) => { if (pt.type === 'SOLID' && pt.opacity !== 0 && c.boundVariables?.[k]?.[i]?.type !== 'VARIABLE_ALIAS' && c.type !== 'INSTANCE') issues.push(`${c.name}: ${k}`); }); });
      if (c.type === 'TEXT' && !(c.textStyleId && c.textStyleId !== figma.mixed)) issues.push(`${c.name}: no text style`);
      if (c.type === 'FRAME') ['paddingTop','paddingBottom','paddingLeft','paddingRight','itemSpacing'].forEach(p => { const v = c[p]; if (typeof v === 'number' && v > 0 && c.boundVariables?.[p]?.type !== 'VARIABLE_ALIAS') issues.push(`${c.name}: ${p}=${v}${SP.has(v) ? '' : '(off-scale)'}`); });
    }
    if (c.type !== 'INSTANCE') walk(c, inside);
  } })(screen, false);
  return { count: issues.length, issues: [...new Set(issues)] };
}
function instanceRatioAudit(screen) {
  const LAYOUT = /section|row|col|cols|container|content|wrapper|wrap|group|stack|list|grid|scroll|panel|bar$|spacer|footer|filter|head|header|body|main|kpi|table|card|drawer/i;
  const violations = []; let instances = 0, layoutFrames = 0;
  (function walk(n){ for (const c of (n.children || [])) {
    if (c.type === 'INSTANCE') { instances++; continue; }
    if (['TEXT','VECTOR','RECTANGLE','SLOT'].includes(c.type)) continue;
    if (c.type === 'FRAME') { if (LAYOUT.test(c.name)) layoutFrames++;
      else { const tc = c.findOne?.(x => x.type === 'TEXT'), hf = Array.isArray(c.fills) && c.fills.some(f => f.visible !== false && f.opacity !== 0), hs = Array.isArray(c.strokes) && c.strokes.length > 0;
        if ((c.width < 240 && c.height < 80) || tc || hf || hs) violations.push(c.name); }
      walk(c); }
  } })(screen);
  const total = instances + violations.length;
  return { ratio: (total ? Math.round(instances / total * 100) : 100) + '%', pass: total ? instances / total >= 0.95 : true, instances, layoutFrames, violations };
}
// Copy audit — content is part of the DS. Mechanical UX-writing violations only (register/tone = human, per
// ux-writing.md). count:0 = ok. Flags: placeholders, Title-Case CTAs, year en-dash/hyphen, glyph-in-label.
function copyAudit(root){
  const PH = /^(Button|Helper text|Option|Placeholder text|Lorem|Description goes here)/i;
  const YEAR = /\b\d{4}[–-]\d{2,4}\b/;                 // 2026–27 / 2026-2027 → UI should be 2026/27
  const issues = [];
  const btnish = t => { let p = t.parent, h = 0; while (p && h < 5) { if (/Button|WizardFooter|BackButton|Pagination|Tab\b/.test(p.name)) return true; p = p.parent; h++; } return false; };
  (function walk(n){ for (const c of (n.children || [])) { if (c.visible === false) continue;
    if (c.type === 'TEXT') { const s = (c.characters || '').trim(); if (s) {
      if (PH.test(s)) issues.push({ t: s.slice(0,40), why: 'placeholder/dev-leftover' });
      else { if (/^[A-Z][a-z]+ [A-Z][a-z]/.test(s) && s.length < 40 && btnish(c)) issues.push({ t: s, why: 'Title-Case CTA → sentence case' });
        if (YEAR.test(s)) issues.push({ t: s.slice(0,40), why: 'year → 2026/27' });
        if (/[+→↗✓✕]\s*$/.test(s) && btnish(c)) issues.push({ t: s, why: 'glyph in label → icon slot' }); } } }
    walk(c); } })(root);
  const seen = new Set(); const uniq = issues.filter(i => { const k = i.why + i.t; return seen.has(k) ? false : (seen.add(k), true); });
  return { count: uniq.length, issues: uniq };
}
const screen = await figma.getNodeByIdAsync('SCREEN_ID');
return { token: tokenAudit(screen), ratio: instanceRatioAudit(screen), copy: copyAudit(screen) };
```
````

---

## After scaffolding — report
One line: which files were created vs kept, and the next action (catalog the Figma file → populate
registry). Remind the collection rules: registry + catalog entry in the same commit as any new component.

## Relation to other skills
- `figma-design-workflow` — the methodology (load alongside). This skill only sets up files.
- `figma-console` / `figma-cli` — execution mechanics.
- `workflow-toolkit:init-project` — general project bootstrap; can call this skill for the DS layer.
