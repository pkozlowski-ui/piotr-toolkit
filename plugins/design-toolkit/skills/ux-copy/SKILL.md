---
name: ux-copy
description: >
  Write interface copy — CTAs, error messages, empty states, confirmation dialogs, loading and
  success states, onboarding, tooltips, permission prompts. Grounded in the project's own copy
  lexicon and voice register, delivered as one recommended string plus alternates with rationale.
  Triggers EN+PL — "write copy for", "what should this button say", "microcopy", "empty state copy",
  "error message for", "name this CTA", "wording for the confirm dialog"; PL "napisz copy",
  "co ma być na przycisku", "treść empty state", "komunikat błędu", "nazwij CTA", "wording do
  modala" — and on the intent even when unnamed: a screen being built that needs strings, or a
  placeholder (`Button`, `Lorem`, `TODO`) standing where a real string belongs.
  NOT for: auditing copy already in a design or build (→ design-toolkit:design-tweaker lens 3/7 for
  a screen, design-toolkit:code-design-audit copy layer for a whole flow), marketing/landing
  headlines, docs, or external messages (→ Slack/Linear drafting rules).
---

# ux-copy — write the strings, don't audit them

This skill **produces** copy. The audit direction is owned elsewhere and duplicating it here
produces two competing verdicts on the same string:

| Task | Owner |
|---|---|
| Write a new string (this file) | `design-toolkit:ux-copy` |
| Judge copy on one screen, among other lenses | `design-toolkit:design-tweaker` (copy lens) |
| Sweep copy across a whole built flow (mechanical: `copyAudit`) | `design-toolkit:code-design-audit` |
| Put the approved string into Figma / code | the build skill that owns that artefact |

**Never write a string and declare the screen done.** Copy lands in an artefact; the string in chat
is a draft until the artefact carries it.

---

## 0. Ground before you write (this is the whole difference)

Copy written from taste alone reads like every other product. Three inputs, in this order:

1. **The project lexicon.** Read `01-foundations/ux-writing.md` if the project has one, plus the
   `copy` block of the project's audit config (acronyms, ghost/retired terms, placeholders,
   canonical year/number formats, Title-Case stopwords). One canonical term per concept — if the
   product says "seat", never silently switch to "spot" or "slot".
2. **The surface and its register.** Same product, different voice:
   - **admin / operational** — operational and flat; state facts, no cheer.
   - **consumer funnel / onboarding** — warm and plain; short sentences, second person.
   - **returning dashboard** — status first, then the next action; no welcome theatre.
   - **destructive / billing** — precise and consequence-first; warmth here reads as evasion.
3. **The container.** Ask for (or measure) the character budget from the design before writing, not
   after. A string that truncates at the designed width is not a string — it is a bug you wrote.

**Missing lexicon → propose-first.** Say the lexicon is missing, offer to start one from the strings
you are about to write, and proceed under a named assumption. Do not invent house style silently.

---

## 1. HARD rules (these are the ones that actually get caught in review)

1. **American English, never British.** `color`, `canceled`, `judgment`, `labeled`, `center`,
   `organize / analyze / customize / personalize`, `enrollment`, `license` (noun and verb),
   `toward`, `catalog`. **Mirror-back is the live trap**: when the user's own prompt (or a client
   brief, or existing copy in the file) says "personalise your dashboard", you still write
   *personalize*. Only an explicitly UK-based client flips this, and then you say so out loud.
   Applies to every string you emit, including copy embedded in code, base64/JS blobs, prototype
   fixtures, and alt text — not just visible HTML.
2. **Sentence case by default.** Title Case only for proper nouns and formal data-field labels
   (`Open seats only`, not `Open Seats Only`).
3. **No invented product facts.** If a string asserts behavior that is not built or not decided
   ("we'll email you when it's ready"), it goes to **Open questions**, not into the recommended
   copy. Copy is the cheapest place to promise something nobody implemented.
4. **CTAs are verb-first and name the outcome.** `Send reminders`, not `Submit`; `Delete 3 files`,
   not `OK`. The button label and the thing that happens are the same words.
5. **No placeholders shipped.** `Button`, `Lorem`, `Text here`, `TODO` never leave this skill.
6. **No glyphs or emoji in labels**, no `!` inflation, no "Oops", no "Whoops", no apologizing for
   the product, no blaming the user ("you entered an invalid…" → "that code has expired").
7. **Same words for the same thing everywhere.** Before inventing a term, grep the project for the
   concept — a synonym is a new concept in the user's head.

---

## 2. Patterns (the structures, not the wording)

| Surface | Structure | Failure it prevents |
|---|---|---|
| **CTA** | verb + object, outcome-matched | mystery-meat buttons |
| **Error** | what happened → why → what to do next | dead ends |
| **Inline validation** | what is wrong with *this field* + the accepted format | scroll-hunting |
| **Empty state** | what this is → why it's empty → the one action to start | abandoned screens |
| **Zero-results** (≠ empty state) | what was searched → what to relax | user blames themself |
| **Confirm / destructive** | name the scope + the consequence; buttons labeled with the actions | `Are you sure?` / `OK`–`Cancel` |
| **Loading** | set the expectation (what, roughly how long) | anxiety, refresh-spam |
| **Success** | confirm what changed + where it went | "did that save?" |
| **Tooltip** | the non-obvious part only | restating the label |
| **Permission / paywall** | the value first, the ask second, the out visible | feels like a trap |
| **Onboarding** | one concept per step, in the user's words | tutorial fatigue |

**Errors carry a recovery the user can actually perform.** "Contact support" is a recovery only when
nothing the user controls can fix it.

---

## 3. Output

```markdown
## Copy: [surface / screen]
**Register:** [admin / funnel / dashboard / destructive] · **Budget:** [N chars, source: design node or "unmeasured"]

### Recommended
| Element | Copy | Chars |
|---|---|---|
| [Heading] | [string] | [n] |
| [Body] | [string] | [n] |
| [Primary CTA] | [string] | [n] |
| [Secondary] | [string] | [n] |

### Alternates
| # | Copy | Register shift | Pick this when |
|---|---|---|---|
| A | [string] | [warmer / flatter / shorter] | [condition] |
| B | [string] | [...] | [condition] |

### Why this one
[2–3 lines: user state, what the string has to do, which lexicon term it reuses]

### Localization notes
[Character expansion (DE/PL ≈ +30% — does the budget survive it?), idioms to avoid, anything that
breaks on plural rules or interpolated numbers]

### Open questions
[Product facts the copy would have to assert but nobody has decided — one line each]
```

Deliver **one** recommendation, not a menu. Alternates exist to show the register axis, not to push
the choice back to the reader.

---

## 4. Before you call it done

- Every string re-read against §1 rule 1 (the British-spelling class is the one that keeps landing
  in client feedback — check it actively, not only when asked to proofread).
- Longest string fits the measured container; if the container was never measured, say so.
- No string asserts unbuilt behavior.
- Terms match the lexicon; new terms are flagged as new, with the concept they cover.
- Copy is only "in" when the artefact carries it — otherwise report it as a draft.

## 5. Self-improvement

A string that came back in review is a lexicon entry waiting to be written. Add it to the project's
`01-foundations/ux-writing.md` (term, why, the rejected form) rather than remembering it for one
session. Recurring cross-project classes belong in §1 of this file, and only after they have burned
twice — one incident is a case, not a rule.
