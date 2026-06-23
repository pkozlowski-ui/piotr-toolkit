---
name: figma-cloud
description: Headless / cloud Figma work via the official remote MCP (https://mcp.figma.com/mcp) — create and modify designs WITHOUT Figma Desktop open. Load when working from phone, Claude Code on the web, a restricted/cloud container, or any "change the design, I don't have the app open" request. The only verified path that writes to the Figma canvas headless.
---

# figma-cloud — headless write via the official remote MCP

The mechanics layer for the **cloud / headless** path, parallel to `figma-console` (which is the
Desktop-Bridge mechanics layer). Use this when there is **no Figma Desktop** to bridge to.

> **Secondary path by design.** When Figma Desktop is open on a Mac, the local tools are faster and
> cheaper — prefer `figma-cli` (greenfield JSX) or `figma-console` (`figma_execute`). Reach for this
> skill specifically when desktop isn't available: phone, Claude Code on the web, cloud container,
> restricted env, or the user explicitly has no app open.

> **Methodology lives in `figma-design-workflow`** (component-first decision tree, pre-flight audit of
> existing pages, variable/token binding). It is file- and path-agnostic — load it alongside this skill
> when designing screens. This skill only covers the **cloud-specific mechanics and footguns**; it does
> not duplicate the methodology.

## When to load this skill

- No Figma Desktop running (so `figma-console` / Desktop Bridge is unavailable)
- Working from a **phone** or **Claude Code on the web** (`code.claude.com` cloud session)
- A cloud container / CI / restricted environment with no localhost and no desktop app
- The user says things like "zmień coś w designie, nie mam otwartej Figmy", "I'm on my phone", "edit this from the cloud"

## The one path that works headless: official remote MCP

`https://mcp.figma.com/mcp` (HTTP transport, OAuth). Hosted by Figma — **needs no desktop app**. It can
**write to the canvas**: create/modify frames, components, **variables**, auto layout. This is the only
fully headless write path (verified live for this account).

What does **not** work headless (don't waste time):
- **Figma Console MCP (Southleft)** — every write mode (Cloud/Local) requires the **Desktop Bridge plugin = Figma Desktop running**. Its remote mode is 9 read-only tools. Not headless for writes.
- **REST API** — narrow: Variables (Enterprise-only), comments, dev resources, webhooks. **Cannot create frames/layout/components.** Manta is on `org` tier (not confirmed Enterprise) → from the cloud, do variables through `use_figma`, **not** REST.
- **A headless Plugin API runner does not exist.** The Plugin API only runs inside the Figma app.

## Setup (one-time, per environment)

```bash
claude mcp add --transport http figma https://mcp.figma.com/mcp
```
Then `/mcp` → `figma` → **Authenticate** (OAuth in browser) → "Authentication successful. Connected to figma".

Or via `.mcp.json` (project- or user-scoped):
```json
{
  "mcpServers": {
    "figma": { "type": "http", "url": "https://mcp.figma.com/mcp" }
  }
}
```

**Verify:** call `whoami`. You need a **Dev or Full seat** on a paid plan.
- Starter / View / Collab seat → **6 tool calls / month** (effectively unusable agentically).
- Dev / Full seat (Professional / Org / Enterprise) → per-minute limits like REST Tier 1.
- **Write-to-canvas tools are exempt from limits and free during the beta.**
- This account: **Full / org** → qualifies. ✅

## Tool surface (remote MCP)

Tool names appear with a server prefix that depends on registration (e.g. `mcp__figma__use_figma` or a
hashed prefix). Match by the logical name:

| Need | Tool |
|---|---|
| **Write to canvas** (frames, components, variables, auto layout) | `use_figma` |
| Create a brand-new file | `create_new_file` |
| Generate a design from intent / a rendered page | `generate_figma_design` |
| Upload images / assets into the file | `upload_assets` |
| Read code/context for a selection | `get_design_context` |
| Cheap structural skeleton (IDs, names, types, positions) | `get_metadata` |
| Render a node to verify visually | `get_screenshot` |
| Variables + styles used in a selection | `get_variable_defs` |
| Search the design system / libraries | `search_design_system`, `get_libraries` |
| Read FigJam | `get_figjam` |

## MANDATORY before `use_figma`

Load the Figma server's own skill **`/figma-use`** before any `use_figma` call (it ships the canonical
write rules). Fallback if the plugin skill isn't present: `skill://figma/figma-use/SKILL.md`.

## Token-budget discipline (same spirit as figma-console)

- **Never `get_design_context` on a whole page** — it blows the **25 000-token** MCP response limit → truncation/error. Always `get_metadata` first (cheap skeleton) → pick node IDs → `get_design_context` only on those.
- Read with `get_metadata` / `get_screenshot` before writing; build incrementally.

## Cloud write footguns (`use_figma` / Plugin API)

1. **Inspect read-only first.** Learn the file's pages, components, variables, naming — and match them. Don't invent token/layer names.
2. **Build incrementally — ~10 operations per call**, skeleton-then-fill, and **return node IDs** to thread into the next call.
3. **`use_figma` scripts ARE atomic** — a script that throws leaves the file **unchanged**. This is the *opposite* of the Desktop-Bridge (`figma_execute`), which is **not** atomic and can leave partial artifacts. So on the cloud path you can retry a failed script cleanly; you do **not** need the desktop "clean up partial artifacts" dance.
4. **Colors are 0–1**, not 0–255.
5. **Paint arrays are read-only** — clone → modify → reassign (`const p = node.fills.map(...); node.fills = p`).
6. **Switch page** via `await figma.setCurrentPageAsync(page)` (sync setter throws).
7. **Text** = `await figma.loadFontAsync({family, style})` BEFORE setting `characters`.
8. **`resize()` BEFORE** setting sizing modes — `resize()` resets layout sizing to FIXED.
9. **Top-level nodes default to (0,0)** — find free space so you don't stack on existing content.
10. **`createPage()` only in Design files** (not FigJam/Slides).
11. **Remote ≠ desktop-bridge runtime — don't port dynamic-page patterns.** The remote MCP runs with
    **full document access**, not `documentAccess: dynamic-page`. So `figma.loadAllPagesAsync()` is **not a
    supported API here** (throws) and the dynamic-page async-getter dance (`getMainComponentAsync`,
    `getNodeByIdAsync` after a load, etc.) isn't required the same way. Just traverse `figma.root.children`
    / `currentPage` directly. (Verified live 2026-06-23.) The `…Async` *page-switch* setter is still
    correct: `await figma.setCurrentPageAsync(page)`.

## Images headless

Use the official **`upload_assets`** — the server ingests the asset directly. This is the clean cloud
path and avoids the broken Desktop-Bridge base64 route (documented as unreliable in `figma-console`:
manifest `allowedDomains` blocks, base64 corrupts at real sizes, `set_image_fill` times out). On the
cloud path, prefer `upload_assets`.

## Report the result — ALWAYS give the deep link

On the cloud path the user usually has **no Figma open** (phone, web) — the chat is their only handle on
the result. So after **every write**, and again when a task is done:

**The deep link is mandatory — never omit it:**
`https://www.figma.com/design/<fileKey>/<fileName>?node-id=<nodeId>`
**Convert the nodeId `:` → `-`** (e.g. node `208:1568` → `node-id=208-1568`). Point it at the node you
created/changed, not the file root, so the user lands on it.

**In-chat screenshot = best-effort, not required.** Rendering the canvas inline in the user's chat is
unreliable across clients: `Read`-ing a PNG or a tool's inline image shows it **to the model, not in the
user's chat**, and a `get_screenshot` URL in a widget `<img>` is **CSP-blocked** (`figma.com` isn't on the
allowlist; only a base64 data-URI via `show_widget` renders, and even that varies by client). Don't burn a
loop forcing it — **the link is the deliverable.** If a screenshot is genuinely wanted, the base64-data-URI-
in-`show_widget` path is the only one that can work; otherwise just confirm in words + link. (Mobile app
rendering still being evaluated — revisit if it proves reliable there.)

## Which file to work on

The user normally **pastes the file URL** (on mobile, straight from the Figma app) — extract the
`fileKey` from it. If they give only a rough name and you're not certain which file it is, **ask for the
URL** — don't guess a `fileKey`. Watch for ambiguous names that map to different files (e.g. a "family
portal" that could be a standalone file or a context inside another file) and confirm before writing.

## Cloud vs desktop — decision

| Situation | Path |
|---|---|
| Mac, Figma Desktop open, greenfield component from JSX | `figma-cli` (fastest) |
| Mac, Figma Desktop open, variants / variable binding / prototype reactions / DS audit | `figma-console` (`figma_execute`, keep small) |
| **No desktop** (phone, web, container) — any write | **`figma-cloud` → remote MCP `use_figma`** |
| Read context / screenshot / generate-from-intent, anywhere | official Figma MCP read tools (`get_metadata` → `get_design_context`) |
| Variables from the cloud | `use_figma` (NOT REST — REST Variables is Enterprise-only) |

## Strategic framing (from the research)

Headless access isn't only one-shot code-gen. High-leverage cloud workflows that don't need the app open:
component audits, documentation generation, acceptance criteria, design QA, DS governance
("flag components with inconsistent naming", "find missing states") — the model reads the real component
tree, tokens, variant matrix and layer hierarchy at full fidelity. Largest fidelity lever remains
**Code Connect** (without it ~85–90% style mismatch); `code-connect publish` runs headless in CI.
