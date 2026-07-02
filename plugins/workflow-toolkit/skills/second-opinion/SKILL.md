---
name: second-opinion
description: Spawn a read-only advisor agent to adversarially review a high-stakes decision, plan, or diff before you commit to it. Use when the cost of being wrong is high (irreversible actions, architecture, multi-step plans, declaring "done" on shared state). Triggers on "second opinion", "sanity-check this", "double-check my plan", "advisor", "zweryfikuj plan", "drugi rzut oka".
argument-hint: "What decision/plan should the advisor pressure-test?"
---

# Skill: second-opinion

## Purpose

Get an independent, adversarial review of a decision *before* acting on it. A fresh agent with no tunnel-vision from the current context catches what the primary agent misses: stale assumptions, contradictions, overlooked edge cases, a simpler path.

This is a **thinking aid, not an executor.** The advisor only reads and reports — it never touches files.

## When to use (trigger, not default)

Spawn an advisor only when **importance × uncertainty × irreversibility** is high. Rough test — reach for it when the task is any of:
- **Irreversible / destructive** — deleting, overwriting, merging memory, force-push, schema/data migration.
- **Architectural** — a decision that's expensive to unwind later.
- **A multi-step plan** — before executing a plan whose early steps are hard to reverse.
- **Declaring "done" on shared state** — Figma, production, data — where a wrong call propagates.

Do **not** spawn one for trivial, clearly-scoped, easily-reversible work. A ritual advisor on every task just burns tokens and time. When in doubt, ask yourself: "if this is wrong, how much does it cost to undo?" Low cost → skip.

## Protocol

### 1 — Frame the question
State, in the prompt to the advisor, exactly what to pressure-test and what "wrong" would look like. Give it the concrete material (the plan, the diff, the decision + rationale) and the file paths / context it needs to verify against. Vague framing → vague verdict.

### 2 — Spawn a READ-ONLY agent (hard rule)
Use the Agent tool with **`subagent_type: 'Explore'`** (broad read/verify) or **`'Plan'`** (design/architecture judgement). Both exclude Edit/Write/Bash-mutation by construction.

**Never** use `general-purpose` (or any full-tools agent) with a prompt that says "don't modify files." The instruction is not a guardrail — a capability that's present eventually gets used. (Real case 2026-07-02: a `general-purpose` advisor told "verdict only" instead executed half a memory consolidation, archiving files and rewriting the index; untangling it cost more than the review saved.)

### 3 — Adversarial framing
Prompt the advisor to **refute, not summarize.** Default stance = "this decision is wrong; find the hole." A cooperative "looks good" verdict is near-worthless; the value is in what it tries to break.

Prompt shape:
> Adversarially review [decision/plan]. Default assumption: it's flawed — find the strongest reason it fails. Verify claims against [files/context], don't take them on faith. Return: verdict (SOUND / FLAWED), specific divergences or risks (with file:line / evidence), and anything the plan overlooked. Do NOT modify any files.

### 4 — Panel for the highest stakes (optional)
For genuinely important, wide-open decisions, spawn **2–3 advisors with distinct lenses** (e.g. correctness / risk / simplicity), not three identical reviewers — diversity catches failure modes redundancy can't. Run them in one message (parallel). Keep the divergences; reconcile before acting.

### 5 — Reconcile, then act
The advisor's verdict is **input, not a verdict on you.** Weigh it, correct course where it's right, note where you disagree and why. Then proceed — and surface to the user anything the advisor flagged that changes the plan.

## Rules

- **Read-only, always.** `Explore` / `Plan` only. If you catch yourself reaching for `general-purpose` to "also let it fix things," that's a separate, explicit step — not a review.
- **Trigger-gated.** Match the ceremony to the stakes. Cheap-to-undo → don't spawn.
- **Adversarial by default.** An advisor that agrees with you taught you nothing.
- **The user's fresh-perspective trick generalizes** beyond design review (cf. `method_multiagent_design_audit` in cross-project memory) — same move, any high-stakes decision, always read-only.
