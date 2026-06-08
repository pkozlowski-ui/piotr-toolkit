---
name: figma-router
description: >
  Entry point for all Figma and design work. Load for any request involving Figma files,
  FigJam boards, design systems, accessibility specs, component audits, or UI design.
  Routes to the right skill automatically — no manual skill selection needed.
---

# figma-router

Detect the domain → load the matching skill → follow its instructions entirely.
Do not act before routing is complete.

## Routing table

| Domain | Trigger signals | Action |
|---|---|---|
| **Design / screens** | designing UI, new screen/layout, component, variables, token, auto layout, frame, build in Figma, "zaprojektuj", "zbuduj ekran" | Read `figma-design-workflow/SKILL.md` |
| **FigJam / diagrams** | diagram, flow, FigJam, flowchart, scenariusz, schemat, board URL (`figma.com/board/…`) | Read `figjam-diagrams/SKILL.md` |
| **Accessibility** | accessibility, dostępność, WCAG, ARIA, screen reader, kontrast, a11y, VoiceOver, TalkBack, focus order | Read `figma-accessibility/SKILL.md` |
| **DS audit / repair** | drift, audit DS, hardcoded colors, odeszło od DS, podepnij do DS, token audit, detached instances | Read `figma-ds-tools/SKILL.md` |
| **DS scaffold / init** | "załóż design system", zainicjalizuj DS, ustaw design system, scaffold DS docs, bootstrap figma docs, registry/build-kit | Read `figma-ds-init/SKILL.md` |
| **Prototype / interakcje** | prototyp, prototype mode, połącz ekrany, tranzycje, overlay, back navigation, interactions | Read `figma-prototype/SKILL.md` |

## Rules

1. **Route first, act second** — read the matched skill before touching Figma
2. **Load exactly one skill** per request — do not combine skills simultaneously
3. **Cross-domain request** (e.g. "build accessible screen") → route to PRIMARY domain; that skill references the secondary where needed
4. **Ambiguous request** → ask one clarifying question before routing

## Extension pattern

Adding a new skill = 2 steps, no other changes:
1. Create `skills/<new-skill-name>/SKILL.md`
2. Add one row to the routing table above
