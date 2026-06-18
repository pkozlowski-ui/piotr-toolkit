---
name: design-system-lookup
description: Find existing patterns before creating new components. Prevents reinventing what already exists. Auto-triggers when creating components, asking about patterns, or starting a redesign.
---

# Skill: design-system-lookup

## Core principle
Before writing any new UI code — check what already exists. Reuse > extend > create new.

## Auto-trigger
- Creating a new component or section
- "What pattern should I use for..."
- Not sure if something already exists
- Starting a redesign or new UI block

## Protocol

### 0 — Check the component catalog first

If `docs/design-system/components.md` exists → **read it before any grep or Figma search.**

This file is the source of truth for "when to use which component" — semantic context that filesystem search can't provide. It answers:
- Which component covers this use case?
- When NOT to use a component (and what to use instead)?
- Which variants/props are available?

If you found the component: jump to step 3 (decide). Skip steps 1–2.  
If the component isn't in the catalog or the catalog doesn't exist: continue with steps 1–2.

**After using a component:** if you discover a new nuance not in the catalog (a gotcha, a "don't use when", a project-specific pattern) → add it to the entry.

### 1 — Locate the design system

Check in order until you find something:

```
docs/design-system/     # layered design system documentation
docs/components/        # component documentation
src/components/         # component implementations
src/app/components/     # Next.js app router structure
app/components/
components/
```

Also check for token files:
```
tailwind.config.js / tailwind.config.ts
theme.css / tokens.css / variables.css
```

**If nothing exists** — tell the user the project has no formal design system and ask how they want to work.

### 2 — Search for what you need

Match the request to a category, then search:

| Looking for | Search for |
|---|---|
| Colors, spacing, typography, motion | Token files, `tailwind.config`, CSS variables |
| Atomic elements (button, input, badge, card) | `components/ui/` or `components/primitives/` |
| Composed blocks (hero, CTA, metrics, timeline) | `components/` or `components/v2/` or design system patterns docs |
| Full page structure | Page blueprints docs, existing page files |

Use Grep/Glob to find matches:
```
Grep "Card" src/components/
Glob **/Hero*.tsx
Grep "Button" components/ui/
```

Read the first 2–3 results to understand what's available.

### 3 — Decide

| Found | Action |
|---|---|
| Exact match | Use it — don't rewrite |
| Partial match | Extend it (add variant/prop) — don't create a parallel component |
| Nothing | Ask user before creating — don't assume |

When asking: "I don't see a pattern for X. Should I create one in the component library, or handle it ad hoc?"

### 4 — Token check before writing code

- Colors → use project CSS variables or Tailwind tokens, not inline hex
- Spacing → use the project scale, not arbitrary `mt-[37px]`
- Font sizes → use the project scale, not `text-[17px]`

If you need a value not in the tokens — ask before adding it.

## Rules

**Pages are compositions, not inventions.**
Page files (`pages/`, `app/`, routes) use managed components only. No inline anonymous divs, one-off wrappers, or hardcoded values in page files.

**Content is part of the DS — reuse copy patterns too, don't reinvent labels.**
Before writing a new label/CTA/status/error, check the project's content canon (`docs/design-system/01-foundations/ux-writing.md`): action-label canon (one base label per action), status/badge lexicon (one label per state), voice register by audience, glossary (one canonical term per concept). Match the existing pattern — a new synonym reads as a new concept.

**If the component doesn't exist yet:**
1. Create it in the component directory (not inside a page file)
2. Document it if the project has design system docs
3. Then use it in the page
