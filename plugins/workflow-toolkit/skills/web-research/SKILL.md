---
name: web-research
description: Deep, multi-source web research turned into a structured, citation-dense report — for business/market intelligence, technology trends, and UX/product research. Engine is native Claude Code (WebSearch + WebFetch with Opus synthesis): free, zero-setup, works in any project, no API keys or Docker. HARD RULE — prioritize authoritative sources (consulting/analyst reports, primary data, recognized practitioner authorities) and verify claims across sources. Auto-triggers EN+PL — "web research", "research X", "market report", "competitive landscape", "trends in X", "state of X", "best practices for X", "UX patterns for X"; PL "zrób research", "researchuj", "raport rynkowy", "rozeznanie rynku", "trendy w X", "wzorce UX dla", "dobre praktyki dla" — and on /web-research. NOT for single-fact lookups, codebase/internal research, or news-of-the-day digests.
argument-hint: "<temat> + kąt (biznes/tech/UX) + zakres czasowy + głębokość (quick/standard/deep)"
---

# Skill: web-research

## Purpose

Turn a research question into a **rigorous, well-sourced, structured report**. Default engine is
**native Claude Code** — `WebSearch` to find sources, `WebFetch` to read them, Opus to synthesize.
No API keys, no Docker, no external MCP server, no cost. Works identically in every project.

The value of this skill is **not** "search the web" — it is **discipline**: decompose the question,
pull from *authoritative* sources, cross-check claims, separate fact from inference, and deliver a
report a decision-maker can trust and trace back to sources.

## When to use / Auto-trigger

Fire on these intents (EN+PL):

- **Business / market intelligence** — "market report", "competitive landscape", "market size for X",
  "raport rynkowy", "rozeznanie rynku", "analiza konkurencji", "ile wart jest rynek X".
- **Technology trends** — "trends in X", "state of X", "is X production-ready", "X vs Y comparison",
  "trendy w X", "co się dzieje w X", "czy warto wchodzić w X".
- **UX / product research** — "UX patterns for X", "best practices for X", "how do top apps do X",
  "wzorce UX dla", "dobre praktyki dla", "jak rozwiązują to najlepsi".
- Explicit: `/web-research <…>`.

**Do NOT use for:**
- A single fact you can answer in one search → just call `WebSearch` directly, no report.
- Code/internal research → use `Explore` / `Grep` / file tools.
- "What happened today" news digests → out of scope.

## Engine

1. **Default (this skill): native.** `WebSearch` + `WebFetch`, synthesis by the session model (Opus).
2. **Deep mode accelerator:** if the built-in **`deep-research`** skill is available, you MAY delegate
   the fan-out + adversarial-verification loop to it for a `deep` request, then re-shape its output
   into this skill's format and source rules. Never hard-depend on it — this skill is self-sufficient.
3. **Optional heavy-mode (appendix):** GPT Researcher / Perplexica MCP — only if the user has set them
   up. See the appendix. Not the default and never required.

## Depth modes

Pick from the request; honor an explicit keyword. State which mode you're running.

| Mode | When | Rough budget | Output |
|---|---|---|---|
| `quick` | "quick take", "tl;dr", scoping | 3–6 searches, fetch 3–5 top sources | ~½–1 page, key findings + sources |
| `standard` *(default)* | most requests | 8–15 searches over sub-questions, fetch 8–12 sources | full structured report |
| `deep` | "deep dive", high-stakes, "be thorough" | broad fan-out, fetch 15+ sources, verification pass | long report + risks + confidence notes |

## Source quality — the MUST-HAVE

This is the core of the skill. A report is only as good as its sources.

**Tier 1 — authoritative (actively seek these):**
- *Business/market:* McKinsey, BCG, Bain, Deloitte, PwC, Gartner, Forrester, IDC, CB Insights,
  Statista, HBR, a16z, Sequoia; primary data — OECD, IMF, World Bank, Eurostat (ec.europa.eu),
  national stat offices, company filings/investor decks.
- *Technology:* official docs & standards (W3C, IETF, MDN), arXiv & ACM/IEEE, ThoughtWorks Tech
  Radar, RedMonk, Stack Overflow Developer Survey, reputable company engineering blogs, primary repos
  (GitHub releases/RFCs).
- *UX/product:* Nielsen Norman Group (nngroup.com), Baymard Institute, Laws of UX, GOV.UK Design,
  established design systems (Material, Carbon, Polaris, Atlassian), web.dev, Interaction Design Foundation.

**Tier 2 — quality industry/journalism:** reputable trade press, established tech media, well-known
practitioner blogs with named authors and dates. Usable; prefer to corroborate with Tier 1.

**Tier 3 — use with caution, corroborate or drop:** anonymous blogs, SEO listicles, vendor marketing,
forums (signal only, not evidence), undated posts.

**Avoid / flag as low-trust:** AI-generated SEO slop, content farms, sites that only re-summarize
others, anything undated, single-source extraordinary claims.

**Rules (non-negotiable):**
- Prefer **primary** over secondary (the original report/dataset, not an article about it).
- **Every quantitative claim needs a date and a source.** Flag undated material explicitly.
- **Cross-check key numbers across ≥2 independent sources.** If only one source supports a claim, say so.
- Respect the requested **timeframe**; note when data is stale ("as of <date>").
- Name the authority in-text ("per Gartner's 2025 …"), don't launder it into anonymous "studies show".
- Use `WebSearch` `allowed_domains` to bias toward Tier-1 and `blocked_domains` to cut known junk.

## Workflow (protocol)

1. **Scope.** Identify topic, angle (business / tech / UX — can be multiple), timeframe, geography/
   industry, depth. If a *critical* dimension is missing and changes the answer, ask 1–2 sharp
   questions; otherwise infer, **state your assumptions at the top**, and proceed.
2. **Decompose.** Break into 4–10 concrete sub-questions. This drives the searches and the structure.
3. **Search.** One+ `WebSearch` per sub-question; bias toward Tier-1 domains; collect candidate URLs
   with publication dates. Run independent searches in parallel.
4. **Fetch & extract.** `WebFetch` the most authoritative/relevant sources; pull claims, numbers,
   dates, and direct quotes. Prefer reading the source over trusting the snippet.
5. **Cross-check & flag.** Verify key claims across sources; surface conflicts instead of averaging
   them away; mark single-source and undated claims.
6. **Synthesize.** Write into the format below. Dense inline citations `[n]`. Keep *what sources say*
   separate from *your analysis/implications* (label the latter).
7. **Sources.** Full reference list: `[n]` Publisher — Title — date — URL — 1-line note + tier.

## Output format

Adapt sections to the angle; drop ones that don't apply. Base template:

```markdown
# <Topic> — <angle> research
*Mode: <quick|standard|deep> · Scope: <timeframe, geography/industry> · Date: <today>*
*Assumptions: <only if you inferred scope>*

## Context / Problem
<what we're answering and why, 2–4 lines>

## Key findings
- <finding, with dense citations [1][3]> — <number + date where relevant>
- <finding> [2]

## Market / Technology trends   ← include the relevant one(s)
- <trend, direction, magnitude> [n]

## UX / Product implications     ← for UX/product or when "so what for us"
- <concrete implication / recommendation grounded in findings> [n]

## Risks / Unknowns / Conflicts
- <gaps, single-source claims, conflicting data, stale figures>

## References
[1] Publisher — "Title" — YYYY-MM-DD — <url> — <note> — Tier 1
[2] …
```

## Quality bar / anti-hallucination

- No claim without a source; no source without a date (or an explicit "undated" flag).
- Don't extrapolate beyond what sources support. Inference is allowed but **labelled** as analysis.
- Numbers: cross-checked, with units and as-of dates.
- Conflicts surfaced, not smoothed over.
- Unknowns named in their own section — a confident gap beats a confident guess.
- Calibrate confidence: in `deep` mode, mark high/medium/low confidence per key finding.

## Using it across projects

- It's **global** via the `workflow-toolkit` plugin — available in every Claude Code project, no
  per-project config.
- Invoke: `/web-research <topic> + <angle> + <timeframe> + <depth>`. Example:
  `/web-research AI coding agents in enterprise B2B SaaS — business + tech angle — 2025–2026 — deep`.
- It also auto-triggers on the phrases above; you don't have to type the command.
- **Phrase requests for best results:** give the *decision behind the question*, the *industry/region*,
  the *timeframe*, and the *depth*. "Research onboarding patterns" → weak; "UX patterns for B2B SaaS
  first-run onboarding, what NN/g & Baymard recommend, 2024+, standard depth" → strong.
- **Verify it's live:** type `/web-research` and check it lists; if not, update the plugin (`/plugin`).

## Appendix — optional heavy-mode (only if you choose to set it up)

The native engine covers the brief. Add an external engine only if you specifically want one of:

- **GPT Researcher MCP** — long autonomous report generation as a single tool call. *Free path:* point
  it at a local **Ollama** model (`OPENAI_BASE_URL`) + a free retriever (DuckDuckGo/SearxNG) instead of
  OpenAI+Tavily. Trade-off: synthesis runs on a local model (weaker than Opus) and needs Python/Ollama
  setup. Docs: https://docs.gptr.dev/docs/gpt-researcher/mcp-server/getting-started
- **Perplexica MCP** — fast "Perplexity-style" answers with sources. *Free path:* Docker Compose with
  bundled SearxNG + local Ollama. Trade-off: a 3-container stack + ~8 GB RAM; great for quick lookups,
  not for deep reports. Docs: self-host Perplexica (Docker + Ollama + SearxNG).

If added, register them in **user scope** so they're available in every project:
`claude mcp add -s user <name> -- <command>` (or the equivalent block in `~/.claude.json`).
Then this skill can route `deep` reports through GPT Researcher and `quick` lookups through Perplexica,
keeping the same source rules and output format. Until then, **native is the default and is enough.**
