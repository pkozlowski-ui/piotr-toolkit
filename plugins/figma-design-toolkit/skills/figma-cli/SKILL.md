---
name: figma-cli
description: Custom Figma Desktop CLI (`figma-ds-cli`). Use when creating components with JSX syntax, adding design tokens (shadcn/tailwind), building pre-made UI blocks, or using `var:` variable binding syntax. Faster than MCP because it connects directly to Figma Desktop via daemon.
---

# figma-cli — figma-ds-cli

CLI that controls Figma Desktop directly. Faster than MCP, runs via a local daemon.

## When to load
- User wants to render JSX directly into Figma
- Need shadcn/tailwind tokens preset
- Building pre-made UI blocks (`blocks create`)
- Variable binding via `var:` syntax

## Setup

The CLI lives outside this plugin. Resolve its path in this order:

1. `$FIGMA_CLI_PATH` environment variable (preferred — set per machine)
2. Project's `CLAUDE.md` may declare the path
3. Common locations: `~/figma-cli`, `~/code/figma-cli`, `~/Documents/figma-cli`

Once resolved, the base command is `node $FIGMA_CLI_PATH/src/index.js <command>`. All examples below use `figma-cli` as shorthand — substitute the real path.

If you can't find the CLI — tell the user and ask for the path. Don't guess.

## Pre-flight (each session)

- Figma Desktop is open
- Daemon is running: `figma-cli daemon status` — if not, run `figma-cli connect`
- Check canvas before creating: `figma-cli canvas info`
- Never delete existing nodes

## When to use figma-cli vs figma-console

| Task | Tool |
|---|---|
| Creating components via JSX | **figma-cli** (`render`) |
| Design tokens shadcn/tailwind | **figma-cli** (`tokens preset shadcn`) |
| Pre-made UI blocks (dashboard etc.) | **figma-cli** (`blocks create`) |
| Complex component variants | figma-console (`figma_execute`) |
| Binding variables to existing nodes | figma-console or figma-cli (`set fill "var:x"`) |
| Operations across multiple pages | figma-console |

## Key commands

### Connection
```bash
figma-cli connect          # Yolo mode (recommended) — patch + daemon
figma-cli connect --safe   # Safe mode — requires manual plugin launch
figma-cli daemon status    # Check daemon
```

### Render
```bash
# Simple frame
figma-cli render '<Frame name="Card" w={320} flex="col" bg="#18181b" rounded={12} p={24} gap={12}>
  <Text size={18} weight="bold" color="#fff" w="fill">Title</Text>
  <Text size={14} color="#a1a1aa" w="fill">Description</Text>
</Frame>'

# With design tokens (shadcn)
figma-cli render '<Frame bg="var:card" stroke="var:border" rounded={12} p={24}>
  <Text color="var:foreground" size={18} w="fill">Title</Text>
</Frame>'
```

### Tokens
```bash
figma-cli tokens preset shadcn   # 244 primitives + 32 semantic (Light/Dark)
figma-cli tokens tailwind        # 242 primitive colors
figma-cli var list               # Show existing variables
figma-cli var visualize          # Swatch on canvas
```

### UI Blocks
```bash
figma-cli blocks list                   # Available blocks
figma-cli blocks create dashboard-01    # Dashboard with sidebar, stats, chart
```

### Verification (REQUIRED after every create)
```bash
figma-cli verify                 # Screenshot of selected node
figma-cli verify "123:456"       # Screenshot of specific node
```

### Convert to component
```bash
figma-cli node to-component "NODE_ID"
```

## JSX syntax — key rules

### Text MUST have `w="fill"` to wrap
```jsx
// BAD — text gets clipped
<Text size={16} color="#fff">Long title that gets cut off</Text>

// GOOD — text wraps properly
<Text size={16} color="#fff" w="fill">Long title that wraps properly</Text>
```
EVERY `<Text>` inside an auto-layout frame needs `w="fill"`. No exceptions.

### Layout — `justify="between"` doesn't work
Use `grow={1}` spacer instead:
```jsx
<Frame flex="row" items="center">
  <Frame>Logo</Frame>
  <Frame grow={1} />   {/* spacer */}
  <Frame>Buttons</Frame>
</Frame>
```

### `var:` syntax for variables (shadcn)
```jsx
bg="var:card"              // background fill
stroke="var:border"        // stroke
color="var:foreground"     // text color (in <Text>)
bg="var:primary"
bg="var:muted"
```

### Icons (Lucide, real SVG)
```jsx
<Icon name="lucide:settings" size={20} color="#fff" />
<Icon name="lucide:chevron-right" size={16} color="var:muted-foreground" />
```

## Common errors (silently fail — no error thrown)

| You wrote | Should be |
|-----------|-------------|
| `layout="horizontal"` | `flex="row"` |
| `padding={24}` | `p={24}` |
| `fill="#fff"` | `bg="#fff"` |
| `cornerRadius={12}` | `rounded={12}` |
| `fontSize={18}` | `size={18}` |
| `fontWeight="bold"` | `weight="bold"` |
| `justify="between"` | `grow={1}` spacer |

## Yolo Mode vs Safe Mode

`figma-cli connect` (Yolo): patches Figma Desktop and starts the daemon. Faster, single command, works for everything below.

`figma-cli connect --safe` (Safe): no patching — you launch the Desktop Bridge plugin manually each session. Use when Yolo mode breaks (Figma update incompatibility, restricted environment).

**Critical Safe Mode limitation:** `render-batch` does NOT render text correctly. For text-heavy components in Safe Mode, fall back to `eval` with native Figma Plugin API:

```bash
figma-cli eval "(async () => {
  await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
  const frame = figma.createFrame();
  // ... rest of the code
  return { id: frame.id };
})()"
```

## Workflow methodology

For component-first decision tree, pre-flight audit, and binding tokens — see `figma-design-workflow` skill. This skill is just the CLI reference.

## Full documentation

Find `CLAUDE.md` and `REFERENCE.md` in the figma-cli repo (resolved via `$FIGMA_CLI_PATH`).
