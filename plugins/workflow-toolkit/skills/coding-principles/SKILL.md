---
name: coding-principles
description: Behavioral guidelines for writing code — think before coding, minimal intervention, no speculative features, define success criteria upfront. Auto-triggers before any coding task. Based on Karpathy's LLM coding pitfalls, adapted for design-to-code and frontend prototype workflows.
---

# Skill: coding-principles

## Purpose

Counteract common LLM coding mistakes: blind interpretation, over-engineering, scope creep, and undefined success criteria. These guidelines apply to every coding task — they are not a checklist to run once, but a behavioral baseline.

## Auto-trigger

Before any coding task — writing new code, editing existing files, or refactoring.

Also invoke explicitly when:
- The task description is vague or has multiple interpretations
- The change touches >3 files
- You're about to modify working code that wasn't part of the original request

---

## Core Principles

### 1. Think Before Coding

Surface ambiguity before writing a single line.

- If the request has multiple valid interpretations — name them and ask which to pursue
- If you see a simpler solution than what was asked for — mention it before proceeding
- If something is unclear, say so explicitly: "I'm not sure if you mean X or Y"

**Never:** proceed with an assumption when the cost of asking is one message.

---

### 2. Minimal Intervention — Touch Only What You Must

When editing existing code, the blast radius of a change should match its intent exactly.

- Do not reformat sections unrelated to the task
- Do not refactor working code "while you're at it"
- Do not remove dead code unless explicitly asked
- Do not rename variables, restructure imports, or adjust whitespace outside the changed area

Every unrelated change is a potential regression and adds noise to the diff.

---

### 3. No Speculative Features

Write exactly the code the task requires — nothing more.

- No "while I'm here, let me also add…" additions
- No abstractions or helpers for hypothetical future use
- No error handling for scenarios that cannot happen given the current codebase
- No configurability that wasn't requested

Three similar lines of code are better than a premature abstraction.

---

### 4. Define Success Before Executing

For any non-trivial task (>3 files, unclear requirements, or significant logic change): state in 1–2 sentences what "done" looks like before starting.

- **UI task:** "Done = screenshot showing X at 1440px and 375px with no visual regressions"
- **Logic task:** "Done = function returns Y for input Z, existing tests pass"
- **Refactor:** "Done = behavior identical, diff shows only structural changes"

This creates a shared checkpoint. If the success criteria are wrong, the user can correct before any code is written.

---

### 5. Second-Opinion Before High-Stakes Moves

Before an **irreversible or high-stakes** action — deleting/overwriting, a data/schema migration, an architectural commit, executing a multi-step plan, or declaring "done" on shared state — consider spawning a **read-only adversarial advisor** to pressure-test it first.

- Gate on cost-of-being-wrong, not on every task — cheap-to-undo work doesn't need it.
- Advisor must be read-only (`Explore` / `Plan`) — never `general-purpose` with a "don't touch files" prompt (the instruction isn't a guardrail).
- Frame it to refute, not to agree.

→ Mechanics + trigger test: `workflow-toolkit:second-opinion`.

---

## Tradeoff Statement

These guidelines bias toward **caution over speed**. On simple, clearly-scoped tasks a single file, unambiguous request, no existing code touched — apply them lightly. On larger or ambiguous tasks, apply them strictly.

The goal is not to slow down work, but to avoid the most expensive mistakes: building the wrong thing, breaking things "at no extra cost", and delivering code that nobody confirmed was the right direction.
