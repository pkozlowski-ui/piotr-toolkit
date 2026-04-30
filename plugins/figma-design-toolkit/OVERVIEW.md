# figma-design-toolkit — Overview

A bundle of skills for bidirectional work with Figma. Designed to **steer execution toward the fastest local path** (Desktop Bridge) and only fall back to cloud MCP when necessary.

> This file is documentation, not an auto-loaded skill. Read it when you want a map of the plugin.

## Skills in this plugin

| Skill | When to load | What it covers |
|---|---|---|
| `figma-design-workflow` | Designing any screen/UI in Figma | Methodology — component-first decision tree, pre-flight audit, variable binding, common pitfalls. **File-agnostic.** |
| `figma-cli` | JSX render, shadcn/tailwind tokens, UI blocks via `var:` syntax | Reference for the local `figma-ds-cli` (custom CLI, daemon-connected) |
| `figma-console` | `figma_execute` calls, variants, programmatic variable binding | Plugin API mechanics — script format, error recovery, placement |
| `figjam-diagrams` | Generating diagrams in FigJam (flows, scenarios, decision trees) | Two modes: Mermaid (`generate_diagram`) and Plugin API (`use_figma`) |

## Decision: which path?

Two execution paths, with very different speed and capability:

### Desktop Bridge (preferred — local, fast)
Requires Figma Desktop open with the Desktop Bridge plugin running.

- **figma-cli** — JSX render, design tokens, UI blocks. Fastest.
- **figma-console** — full Plugin API via `figma_execute`. Use when JSX falls short.

### Cloud (fallback — slower, network-bound)
Use when Desktop Bridge isn't available (no Figma Desktop, restricted env, or just a URL with no local file open).

- claude.ai Figma MCP (`use_figma`, `generate_diagram`) — provided by the official Figma MCP server.

## Tool selection cheat sheet

| Task | First choice |
|---|---|
| Render a card/component from JSX | `figma-cli render` |
| Set up shadcn or tailwind tokens | `figma-cli tokens preset shadcn` |
| Insert a pre-made UI block (dashboard etc.) | `figma-cli blocks create` |
| Variants, programmatic binding, multi-page ops | `figma-console figma_execute` |
| Read design context for code generation | Figma desktop MCP read tools |
| FigJam diagram with pros/cons / scenario | `figjam-diagrams` (MODE B) |
| Quick Mermaid diagram | `figjam-diagrams` (MODE A) |

## Setup

**figma-cli** lives outside this plugin. Resolve its path via `$FIGMA_CLI_PATH`, the project's `CLAUDE.md`, or common locations (`~/figma-cli`, `~/code/figma-cli`). See `figma-cli` skill for details.

**figma-console** requires the Desktop Bridge plugin running inside Figma Desktop. Check connection with `figma_get_status`.

**figjam-diagrams** uses the Figma MCP server (typically `mcp__claude_ai_Figma__*`). Exact tool prefix depends on your MCP server registration.

## File map

```
figma-design-toolkit/
├── OVERVIEW.md                       # this file
├── .claude-plugin/plugin.json
└── skills/
    ├── figma-design-workflow/SKILL.md
    ├── figma-cli/SKILL.md
    ├── figma-console/SKILL.md
    └── figjam-diagrams/
        ├── SKILL.md
        └── references/
            ├── helpers.js            # verified FigJam helper library
            ├── plugin-api-guide.md
            └── visual-patterns.md
```
