# Content / UX-writing rules — figma-design-workflow

> **Load when:** the screen you are building or auditing contains copy.

## Content / UX-writing — copy is PART of the design system

Every string you write IS a design-system decision — audit it like tokens, not as an afterthought. These are
UNIVERSAL rules (file-agnostic); the project's actual glossary, voice registers, and per-surface specifics live
in `docs/design-system/01-foundations/ux-writing.md` (scaffolded by `figma-ds-init`) — read it before writing copy.

**Capitalization by SURFACE (the one rule to internalize):** sentence case is the default. The only exceptions:
eyebrows + table-column headers (UPPERCASE *via style*, never typed caps) and proper nouns + formal data-field
labels (Title Case). Descriptive categories/filters are NOT proper nouns → sentence case (`Open seats only`, not
`Open Seats Only`; `Middle school`, not `Middle School`). Real proper nouns stay (`LaGuardia High School`).

**Buttons / CTAs:** verb-first, sentence case, no terminal period, **no glyph in the label** (icon = separate slot).
One base label per action across the flow (don't let "Save" wear five labels).

**Helpers / errors / descriptions:** helper = fragment→no period, full sentence→period, carry the *why* when stakes
are real; errors = full sentence + period, supportive (never blaming), name the fix; page descriptions = full
sentence. No placeholders ship (`Button`, `Helper text`, `Lorem`, `Description goes here` = pre-ship fail).

**Register by AUDIENCE, not by screen** — pick the voice from who reads it (define the project's registers in
`ux-writing.md`; typical split: internal/admin tooling = operational & scannable; consumer funnel = warm,
benefit-first, low-friction, plain/ESL; returning-user dashboard = status + next-action + "no action needed").
An **AI layer** is advisory (attribution → finding → action, hedged, never blocks, human decides); decide its
**brand exposure per audience** (often white-label / unbranded for end-users, branded for internal).

**Terminology = one canonical string per concept** (a glossary in `ux-writing.md`). Synonyms read as new concepts.
Watch for **ghost terms** (renamed/removed features still in copy) and **keys ≠ display** (typed enum/filter keys
live in code/types/fixtures — never rename them for copy; render a display label-map instead).

**Pre-flight + audit:** when the screen has copy, run `copyAudit()` from `figma-build-kit.md` (mechanical: Title-Case
CTAs, placeholders, year format, glyph-in-label, ghost terms) → `count:0` before done. For a new experience or a big
copy change, run the full **harvest → register → fix** playbook (see the project's `03-patterns/ux-writing-audit-playbook.md`).
`copyAudit` is mechanical only — register/tone is a human judgment against `ux-writing.md`.

---
