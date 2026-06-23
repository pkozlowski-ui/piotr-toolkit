# figma-design-toolkit — Overview

A bundle of skills for bidirectional work with Figma. Designed to **steer execution toward the fastest local path** (Desktop Bridge) and only fall back to cloud MCP when necessary.

> This file is documentation, not an auto-loaded skill. Read it when you want a map of the plugin.

## Relationship to the official Figma plugin (`figma@claude-plugins-official`)

This toolkit is built **on top of** the official Figma plugin, not instead of it.

- **The official plugin is the engine + the code↔design direction.** It provides the **MCP server**
  (`https://mcp.figma.com/mcp` — install the plugin, don't `claude mcp add` the same URL twice) and the
  **canonical write-contract skills** (`figma-use`, `figma-create-new-file`, `figma-generate-design`,
  `figma-generate-diagram`, `figma-generate-library`, `figma-use-figjam`, `figma-use-slides`,
  `figma-code-connect`). It owns: design→code, **Code Connect**, `create_design_system_rules`, and the
  low-level `use_figma` rules.
- **This toolkit is the orchestration + building/editing inside Figma.** It owns: routing
  (`figma-router`), opinionated methodology (`figma-design-workflow`), **Desktop Bridge** mechanics the
  official plugin doesn't cover (`figma-cli`, `figma-console`), cloud routing (`figma-cloud` — *when/where*
  + seat/limits + remote-vs-desktop gotcha + link-first, deferring the write contract to `figma-use`),
  DS audit/repair (`figma-ds-tools`), prototype wiring (`figma-prototype`), rich FigJam
  (`figjam-diagrams`), a11y specs (`figma-accessibility`), DS scaffolding (`figma-ds-init`), and the house
  rules (INSTANT transitions, token discipline, ask-loudly).

Rule of thumb: code↔design / Code Connect / canonical write rules → **official plugin**; everything about
*how* to build, audit, and orchestrate in Figma → **this toolkit**.

## Skills in this plugin

| Skill | When to load | What it covers |
|---|---|---|
| `figma-design-workflow` | Designing any screen/UI in Figma | Methodology — component-first decision tree, pre-flight audit, variable binding, common pitfalls. **File-agnostic.** |
| `figma-cli` | JSX render, shadcn/tailwind tokens, UI blocks via `var:` syntax | Reference for the local `figma-ds-cli` (custom CLI, daemon-connected) |
| `figma-console` | `figma_execute` calls, variants, programmatic variable binding | Plugin API mechanics — script format, error recovery, placement |
| `figma-cloud` | **No Figma Desktop** — phone, Claude Code on the web, cloud/restricted env | Headless write via the official remote MCP (`mcp.figma.com`) — setup, tool surface, cloud footguns |
| `figjam-diagrams` | Generating diagrams in FigJam (flows, scenarios, decision trees) | Two modes: Mermaid (`generate_diagram`) and Plugin API (`use_figma`) |

## Decision: which path?

First pick the **environment** (is Figma Desktop open?), then the tool. Three execution paths:

### Desktop Bridge (preferred — local, fast)
Requires Figma Desktop open with the Desktop Bridge plugin running.

- **figma-cli** — JSX render, design tokens, UI blocks. Fastest.
- **figma-console** — full Plugin API via `figma_execute`. Use when JSX falls short.

### Cloud / headless (no Figma Desktop — phone, web, container)
The official **remote MCP** (`https://mcp.figma.com/mcp`, OAuth) — the only verified headless write path
(needs a Dev/Full seat). Use when there's no desktop to bridge to.

- **figma-cloud** — `use_figma` / `create_new_file` / `generate_figma_design` + read tools. See the skill for setup + footguns.

### Read / codegen (any environment)
The official Figma MCP read tools (`get_metadata` → `get_design_context`, `get_screenshot`,
`get_variable_defs`) work alongside either path.

## Tool selection cheat sheet

| Task | First choice |
|---|---|
| Render a card/component from JSX | `figma-cli render` |
| Set up shadcn or tailwind tokens | `figma-cli tokens preset shadcn` |
| Insert a pre-made UI block (dashboard etc.) | `figma-cli blocks create` |
| Variants, programmatic binding, multi-page ops | `figma-console figma_execute` |
| Build/edit a design with **no Figma Desktop** (phone/web/cloud) | `figma-cloud` → remote MCP `use_figma` |
| Read design context for code generation | Figma MCP read tools (desktop or remote) |
| FigJam diagram with pros/cons / scenario | `figjam-diagrams` (MODE B) |
| Quick Mermaid diagram | `figjam-diagrams` (MODE A) |

## Setup

**figma-cli** lives outside this plugin. Resolve its path via `$FIGMA_CLI_PATH`, the project's `CLAUDE.md`, or common locations (`~/figma-cli`, `~/code/figma-cli`). See `figma-cli` skill for details.

**figma-console** requires the Desktop Bridge plugin running inside Figma Desktop. Check connection with `figma_get_status`.

**figjam-diagrams** uses the Figma MCP server (typically `mcp__claude_ai_Figma__*`). Exact tool prefix depends on your MCP server registration.

**figma-cloud** uses the official **remote** Figma MCP. Register it with
`claude mcp add --transport http figma https://mcp.figma.com/mcp` → `/mcp` → Authenticate (OAuth).
Verify with `whoami` (needs a Dev/Full seat). See the `figma-cloud` skill for the full setup + tool surface.

## File map

```
figma-design-toolkit/
├── OVERVIEW.md                       # this file
├── .claude-plugin/plugin.json
└── skills/
    ├── figma-router/SKILL.md         # entry point — routes by environment + domain
    ├── figma-design-workflow/SKILL.md
    ├── figma-cli/SKILL.md            # Desktop Bridge — JSX render
    ├── figma-console/SKILL.md        # Desktop Bridge — figma_execute
    ├── figma-cloud/SKILL.md          # headless — official remote MCP (mcp.figma.com)
    ├── figma-accessibility/SKILL.md
    ├── figma-ds-tools/SKILL.md
    ├── figma-ds-init/SKILL.md
    ├── figma-prototype/SKILL.md
    └── figjam-diagrams/
        ├── SKILL.md
        └── references/
            ├── helpers.js            # verified FigJam helper library
            ├── plugin-api-guide.md
            └── visual-patterns.md
```
