---
name: figma-handoff-prep
description: >-
  Prepare a Figma file for developer handoff — annotate screens, map components to the
  target code library, bind design-token code syntax, and produce a handoff-readiness
  checklist — so engineers implement from Figma with minimal guesswork. Two layers: a
  project-agnostic engine (annotation generator, code-syntax pass, component-description
  mapping, verification, capability matrix) + a per-project overlay (target UI library,
  token namespace, component registry). Use when asked to "prepare Figma for handoff",
  "annotate a flow for devs", "add Mantine/shadcn/… mappings", "make screens dev-ready",
  "przygotuj figmę do handoffu". Runs headless via the official Figma MCP `use_figma`
  (no Desktop Bridge needed). Screen-layer prep is an MVP-gate; component-layer is tier-agnostic.
---

> **Cross-project canonical skill** (piotr-toolkit → `figma-design-toolkit`). This file is the
> project-agnostic **engine**: §1–§5 + §7–§9 work against any Figma DS and any target code library.
> The **per-project overlay** (§6 — target UI library, token namespace, component registry, WCAG target,
> DS component names) does **not** live here — it lives in each product repo, typically
> `docs/design-system/figma-handoff-playbook.md` + that repo's `.claude/skills/figma-handoff-prep/`.
> Authored from the Anti-SIS engagement 2026-07-15 (first reference implementation). Promote new
> heuristics back here (§9); keep product specifics in the product repo.

# figma-handoff-prep

Turn a settled Figma flow into a dev-ready handoff: the engineer selects a section/screen, runs the
default Dev Mode prompt ("Implement this design from Figma @url"), and `get_design_context` returns
**real component mappings + accessibility intent + copy-ready tokens** instead of generic markup.

Everything written into Figma is **English** (shared artifact). Polish/other only in conversation.

## 0. Two layers (know which you're doing)

| Layer | What | When | Cost/economics |
|---|---|---|---|
| **Component** | `node.description` on DS **masters** = target-lib mapping + a11y semantics | **Tier-agnostic, always** | Written once on the master; serves every instance (Lighthouse + MVP). Cheap, durable. |
| **Screen** | per-screen a11y annotations, `devStatus` (Ready for dev), code-syntax on shipped tokens, dev-resource links | **MVP sections only, after review** | Expensive per-screen; churns on concept work. Only pays off where implementation happens. |

**Never do screen-layer prep on north-star/concept screens** — they change too often, nobody implements
from them → stale, wasted effort. In a Lighthouse→MVP-style process this is the post-review HANDOFF phase
on the `[MVP]` section only.

## 1. Capability matrix — what's possible headless (cloud/CI/phone) vs desktop-only

All writes go through the official Figma MCP **`use_figma`** (Plugin API, headless by `fileKey`, atomic,
no Desktop Bridge). Load the `figma-use` skill before the first `use_figma` call.

| Task | Headless (`use_figma`)? | Notes |
|---|---|---|
| Enumerate all pages / traverse | ✅ | `figma.root.children` (NOT `get_metadata` w/o node — that lists only the active page on remote). Read multi-page = `page.loadAsync()` in a loop. |
| Read/write `node.description` | ✅ | append-only pattern; skip if already mapped |
| Read/write `node.annotations` | ✅ | **FRAME/most nodes** support it; **SECTION does not** (`no such property`). `{ labelMarkdown }` |
| Set variable `codeSyntax` | ✅ | `variable.setVariableCodeSyntax('WEB', 'var(--…)')` |
| Screenshot | ✅ | `get_screenshot` with `enableBase64Response:true` (asset URL may be 403 behind a proxy) |
| `node.devStatus` (Ready for dev / Changed) | ❌ **desktop only** | get AND set throw `not yet supported` in `use_figma`. **Trap:** `if(n.devStatus)` inside try/catch silently swallows → false "0 statuses". Don't measure it headless. |
| "Changed since marked" signal | ❌ desktop only | app-only |
| Publish library | ❌ manual | must re-publish in desktop after editing descriptions (see §5) |

## 2. Process (run in order)

1. **Scope** — confirm which sections are in scope (screen-layer = MVP only). Read the project overlay (§6).
2. **Component layer** (once per DS): append target-lib mapping to every DS master `node.description`.
   Then **re-publish the library** (§5).
3. **Screen layer** (MVP sections, post-review):
   a. **Code-syntax** on variables → target token namespace.
   b. **A11y annotations** per screen via the generator (§4).
   c. **Ready-for-dev** statuses — hand to the user (desktop; not headless).
   d. **Dev-resource links** (Storybook/repo/Linear) when they exist.
4. **Verify** (§7): 0 non-English, instance-ratio, annotation/mapping counts, no split-brain.
5. **E2E check** — run `get_design_context` on one prepped screen; confirm annotations appear as
   `data-annotations` + "Do not ignore", component descriptions appear under "Component descriptions",
   code-syntax appears as `var(--…, fallback)`.

## 3. Engine — component-description mapping pass (copy-paste)

Append-only; idempotent (skips if `<lib> mapping:` is already present). Run per DS page, batched. Map by
role: primitives → `{Component}` + props; composites → composition; icons → icon-lib; rows/cards →
semantic container. Include the a11y intent the component owns (aria-current, roles, labels).

```js
// per DS page (id): append mapping to each top-level COMPONENT/COMPONENT_SET
const MAP = { /* nodeId: "<lib> mapping: …" */ };
let set = 0; const errors = [];
for (const [id, text] of Object.entries(MAP)) {
  try {
    const n = await figma.getNodeByIdAsync(id);
    const cur = n.description || "";
    if (/mapping:/i.test(cur)) { continue; }              // idempotent
    n.description = cur ? cur.trimEnd() + "\n\n" + text : text;
    set++;
  } catch (e) { errors.push({ id, err: String(e) }); }
}
return { set, errors };
```

Icons can be mapped programmatically (name → icon-lib component). Deprecated masters get a tombstone
line instead of a mapping. Leave a factual, current description — if the base description is stale
(pre-restructure), refresh it to current canon (that's a content change; flag it, don't smuggle it).

## 4. Engine — a11y annotation generator (the core reusable asset)

Generates per-screen annotations from the **real anatomy** (no hand-writing per screen). Detects: nav
instances → landmarks; largest text ≥20px → the h1; field-instance clusters (≥2) → a form group; a
`WizardFooter`/`footer*` → the actions row; a stepper → step semantics. Emits `**A11y — screen**` +
`**A11y — form**` + `**A11y — actions**`. Idempotent (skips screens already annotated). Fan out one
`use_figma` call per page (page.loadAsync inside).

```js
figma.skipInvisibleInstanceChildren = true;
const FIELDS = OVERLAY.fieldComponents;   // e.g. ["Field","Input","Select","Textarea","DateInput","Checkbox","Radio","Switch",…]
const NAVS   = OVERLAY.navComponents;     // { "NavRail":"nav rail (main nav)", "AppTopBar":"app top bar (banner)", "TabBar":"tab bar (primary nav)", … }
const STEPS  = OVERLAY.stepComponents;    // ["ProgressSteps","StageTrack",…]
function annotateScreen(f) {
  if ((f.annotations||[]).some(a => (a.labelMarkdown||"").startsWith("**A11y"))) return { skipped: true };
  const all = f.findAll(() => true);
  const navs = new Set(); let h1 = null, h1Size = 0, footer = null, steps = false;
  const forms = new Map();
  for (const n of all) {
    if (n.type === "INSTANCE" && NAVS[n.name]) navs.add(NAVS[n.name]);
    if (n.type === "INSTANCE" && STEPS.includes(n.name)) steps = true;
    if (n.type === "INSTANCE" && n.name === "WizardFooter") footer = n;
    if (n.type === "FRAME" && /footer/i.test(n.name) && !footer) footer = n;
    if (n.type === "TEXT") { try { const s=n.fontSize; if (typeof s==="number" && s>=20 && s>h1Size && n.characters.length>2){h1Size=s;h1=n.characters.slice(0,50);} } catch(e){} }
    if (n.type === "INSTANCE" && FIELDS.includes(n.name) && n.parent) {
      const e = forms.get(n.parent.id) || { node: n.parent, count: 0 }; e.count++; forms.set(n.parent.id, e);
    }
  }
  const zones = [];
  if ([...navs].some(v=>v.includes("banner"))) zones.push("app bar");
  if (steps) zones.push("steps");
  zones.push("heading","content");
  if (footer) zones.push("actions");
  if ([...navs].some(v=>v.includes("primary nav"))) zones.push("tab bar");
  const landmarks = [...navs].join(", ") || "main only";
  f.annotations = [...(f.annotations||[]), { labelMarkdown:
    `**A11y — screen.** WCAG ${OVERLAY.wcagTarget}. Reading order = visual: ${zones.join(" → ")}. Focus order matches; no traps. Exactly one h1${h1?` = "${h1}"`:" = the page title"}. Landmarks: ${landmarks}; content = <main>. Component semantics (aria-current, tables, fields) → DS component descriptions.` }];
  let written = 1;
  for (const { node, count } of forms.values()) {
    if (count < 2 || !("annotations" in node)) continue;
    if ((node.annotations||[]).some(a => (a.labelMarkdown||"").startsWith("**A11y"))) continue;
    node.annotations = [...(node.annotations||[]), { labelMarkdown:
      `**A11y — form (${count} fields).** Visible persistent labels (3.3.2, never placeholder-only); errors inline + linked to field (aria-invalid + described-by), text explains the fix, focus to first invalid on submit (3.3.1/3.3.3); required is default — mark only optional; nothing color-only (1.4.1).` }];
    written++;
  }
  if (footer && "annotations" in footer && !(footer.annotations||[]).some(a => (a.labelMarkdown||"").startsWith("**A11y"))) {
    footer.annotations = [...(footer.annotations||[]), { labelMarkdown:
      `**A11y — actions.** DOM/focus order = visual (escape left → primary right). Primary = button type="submit". Targets ≥24×24 (2.5.8).` }];
    written++;
  }
  return { written };
}
const page = await figma.getNodeByIdAsync(PAGE_ID);
await page.loadAsync();
let screens=0, ann=0, skipped=0, errs=0;
for (const child of page.children) {
  const frames = child.type==="SECTION" ? child.children.filter(c=>c.type==="FRAME"&&c.width>=OVERLAY.minScreenW)
                : (child.type==="FRAME"&&child.width>=OVERLAY.minScreenW ? [child] : []);
  for (const f of frames) { try { const r=annotateScreen(f); if (r.skipped) skipped++; else { screens++; ann+=r.written; } } catch(e){ errs++; } }
}
return { page: page.name, screens, ann, skipped, errs };
```

Flow-type flavor: add one clause to the screen annotation on auth (3.3.8 accessible auth), multi-step
(3.3.7 redundant entry, focus to new-step h1), results/irreversible (confirm step, outcome not color-only),
upload (dropzone click fallback), AI/assistant (aria-live for new output, actions are buttons).

## 5. Engine — code-syntax pass + the republish rule

Set `codeSyntax.WEB` to the target token namespace. Bind the **semantic** collection + scale collections;
skip raw primitives (consumed via semantic). Map by slug (slash→kebab) OR to the target lib's CSS vars —
see overlay. Watch mode-divergence: bind by **rendered value**, not alias name.

```js
const vars = await figma.variables.getLocalVariablesAsync();
for (const v of vars) {
  if (!OVERLAY.codeSyntaxCollections.includes(v.variableCollectionId)) continue;
  v.setVariableCodeSyntax('WEB', OVERLAY.tokenToCss(v));   // e.g. `var(--${v.name.replace(/\//g,'-')})`
}
```

**HARD RULE — re-publish the library after editing descriptions/components.** Description edits land on the
**local** master; the **published** copy keeps the old text, and instances bound to the published version
resolve the stale description in Dev Mode (the "split-brain": same `key`, `remote:true` mirror). Re-publish
(desktop, manual) so the mapping actually reaches engineers.

## 6. Project overlay — TEMPLATE (fill per project, keep in the product repo)

This block does not live in the toolkit. Each product repo carries its own filled overlay (in
`docs/design-system/figma-handoff-playbook.md` + that repo's `.claude/skills/figma-handoff-prep/`). Copy
this template there and fill the `<…>` placeholders against the project's design system.

```yaml
targetLibrary: <lib + version>          # component + prop vocabulary the mappings speak (e.g. Mantine v9, shadcn/ui)
tokenNamespace: "--<slug>"              # semantic slash → kebab CSS var
wcagTarget: <e.g. "2.1 AA (design to 2.2 AA)">
minScreenW: 350                         # ignore sub-screen frames
fieldComponents: [<DS field-instance names, e.g. Field, Input, Select, Textarea, DateInput, Checkbox, Radio, Switch, …>]
navComponents:  { <NavInstanceName>: "nav rail (main nav)", <TopBarName>: "app top bar (banner)", <TabBarName>: "tab bar (primary nav)" }
stepComponents: [<stepper component names, e.g. "ProgressSteps", "StageTrack">]
codeSyntaxCollections: [<semantic + scale collection ids, e.g. semantic, spacing, width, radius>]   # skip brand/neutral primitives
```

Watch-outs to capture in the filled overlay: token **name skew** (a named step whose value doesn't match
the name → bind by value) and **mode divergence** (same alias resolves differently per mode → bind by
rendered value, not alias name).

## 7. Verify before "done"
- **Language:** 0 non-English in descriptions + annotations (scan diacritics/wordlist per language). Everything shared = English.
- **Annotations:** counts per page, 0 errors; spot-check one screen visually.
- **No split-brain:** if a component shows two descriptions in `get_design_context`, it's a stale published
  mirror (same `key`, `remote:true`) → re-publish.
- **E2E:** `get_design_context` surfaces annotations + descriptions + code-syntax (see §2.5).

## 8. Manual handoff (not headless — give the user a checklist)
- Mark **Ready for dev** on the settled MVP sections (Dev Mode).
- **Re-publish** the DS library.
- Attach **dev-resource links** (repo/Storybook/Linear) on key components.

## 9. Self-improvement
Like the sibling Figma skills: in retro, promote new **engine** heuristics (a new field/nav component
class to detect, a new flow-type clause, a new capability limit) back into §4/§1 here. Keep
**project-specific** facts (component names, token quirks, registry paths) in the product-repo overlay,
not in this file. This engine grows with each run; the overlays stay local.
