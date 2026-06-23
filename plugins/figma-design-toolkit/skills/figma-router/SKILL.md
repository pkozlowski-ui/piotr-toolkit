---
name: figma-router
description: >
  Entry point for all Figma and design work. Load for any request involving Figma files,
  FigJam boards, design systems, accessibility specs, component audits, or UI design.
  Routes to the right skill automatically — no manual skill selection needed.
---

# figma-router

Detect the **execution environment**, then the **domain** → load the matching skill → follow its
instructions entirely. Do not act before routing is complete.

## Step 0 — execution environment (decide before the domain)

| Environment | Signals | Consequence |
|---|---|---|
| **Desktop Bridge available** (default) | macOS, Figma Desktop open, local file in play, `figma_*` tools present | Local path — `figma-cli` / `figma-console` are in play (fast, cheap). |
| **Cloud / headless** | no Figma Desktop, phone, Claude Code on the web (`code.claude.com`), cloud container / restricted env, "nie mam otwartej Figmy" | **`figma-cli` and `figma-console` are unavailable.** Writes go only through the official remote MCP → load **`figma-cloud`** for the mechanics. |

If unsure which environment you're in, check: are `figma_*` (Desktop Bridge) tools available? If not, you're on the cloud path.

## Routing table

| Domain | Trigger signals | Action |
|---|---|---|
| **Design / screens** | designing UI, new screen/layout, component, variables, token, auto layout, frame, build in Figma, "zaprojektuj", "zbuduj ekran" | Read `figma-design-workflow/SKILL.md` |
| **FigJam / diagrams** | diagram, flow, FigJam, flowchart, scenariusz, schemat, board URL (`figma.com/board/…`) | Read `figjam-diagrams/SKILL.md` |
| **Accessibility** | accessibility, dostępność, WCAG, ARIA, screen reader, kontrast, a11y, VoiceOver, TalkBack, focus order | Read `figma-accessibility/SKILL.md` |
| **DS audit / repair** | drift, audit DS, hardcoded colors, odeszło od DS, podepnij do DS, token audit, detached instances | Read `figma-ds-tools/SKILL.md` |
| **DS scaffold / init** | "załóż design system", zainicjalizuj DS, ustaw design system, scaffold DS docs, bootstrap figma docs, registry/build-kit | Read `figma-ds-init/SKILL.md` |
| **Prototype / interakcje** | prototyp, prototype mode, połącz ekrany, tranzycje, overlay, back navigation, interactions | Read `figma-prototype/SKILL.md` |
| **Cloud / headless** | no Figma Desktop, "z telefonu", "bez appki Figma", Claude Code on the web, cloud/restricted env, remote MCP | Read `figma-cloud/SKILL.md` (mechanics) + the domain skill above for methodology |

The **Cloud / headless** row is an *environment* override (Step 0), not a separate domain: still pick the domain skill for methodology (usually `figma-design-workflow`), but execute through `figma-cloud` instead of `figma-cli`/`figma-console`.

## Hand-off to the official Figma plugin (`figma@claude-plugins-official`)

That plugin owns the **code↔design direction** and the low-level write contract. Don't reimplement these here — route OUT to it:

| Request | Route to |
|---|---|
| "implement/build this Figma as code", design→code, pixel-perfect codegen | official plugin — `implement-design` steering |
| Code Connect — map/connect/link a Figma component to code | official `/figma-code-connect` |
| "create/generate design-system rules for my project" (code-side rules) | official `create_design_system_rules` |
| canonical `use_figma` / `create_new_file` / `generate_*` write rules | official `/figma-use` & siblings (loaded by `figma-cloud` / execution skills) |

This toolkit owns the inverse + the opinionated layer: **building/editing inside Figma** (figma-cli/figma-console/figma-cloud), DS audit/repair, prototype wiring, rich FigJam, a11y specs, and the house rules (INSTANT transitions, token discipline, ask-loudly). The official plugin is the engine; this toolkit is the orchestration on top. See `OVERVIEW.md` → "Relationship to the official Figma plugin".

## Rules

1. **Route first, act second** — read the matched skill before touching Figma
2. **Load exactly one skill** per request — do not combine skills simultaneously
3. **Cross-domain request** (e.g. "build accessible screen") → route to PRIMARY domain; that skill references the secondary where needed
4. **Ambiguous request** → ask one clarifying question before routing
5. **Cheapest tool wins** — for Plugin API work, prefer figma-cli (greenfield) or the official Figma MCP (read/codegen/generation) over `figma_execute` where they fit; `figma_execute` is timeout-prone (hardcoded ~5 s budget). The matched skill's performance budget is mandatory — see `figma-console`.
6. **Environment gates the tools** — on the **cloud path** (Step 0), `figma-cli` and `figma-console` do not exist; the only write path is the official remote MCP via `figma-cloud`. Don't try to reconnect a Desktop Bridge that isn't there — load `figma-cloud`.

## Extension pattern

Adding a new skill = 2 steps, no other changes:
1. Create `skills/<new-skill-name>/SKILL.md`
2. Add one row to the routing table above
