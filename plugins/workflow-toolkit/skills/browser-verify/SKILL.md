---
name: browser-verify
description: Visual UI verification in browser (desktop + mobile) before marking a task done. Auto-triggers after any UI change.
---

# Skill: browser-verify

## Auto-trigger
After any UI change. Exception: logic/data-only changes with no visual impact.

## Protocol

### 1 — Dev server + resolve the URL

**Never assume port 3000.** Resolve the real port/URL in this order:

1. **`.claude/launch.json`** (if present) — declares dev command + port per app. Source of truth in monorepos.
2. **`package.json` → `scripts.dev`** — parse an explicit `-p`/`--port` flag if present.
3. **Framework default** only as last resort: Next.js/React `3000`, Vite `5173`.

Monorepo (npm workspaces): start the right app, e.g. `npm run dev --workspace=<app-name>` — different apps run on different ports (don't collide them).

Check if already running first. Start if needed, then **capture the actual URL the server prints** (`Local: http://localhost:<port>`) — that printed value, not the assumed default, is ground truth:

```bash
BASE="http://localhost:<resolved-port>"   # from server output / launch.json
PAGE="/"                                   # path of the changed page
URL="$BASE$PAGE"
```

Wait for "Ready" / "Local:" before continuing.

### 2 — Screenshots

```bash
# Desktop (1440px)
npx playwright screenshot --viewport-size=1440,900 "$URL" /tmp/desktop.png
# Mobile (375px)
npx playwright screenshot --viewport-size=375,812 "$URL" /tmp/mobile.png
```

`$URL` already points at the resolved port + changed page (step 1).

### 3 — Visual check
Review both screenshots for:
- overlapping elements
- broken grid/flex layout
- spacing inconsistencies
- color/token regressions
- text unchanged (if project has READ-ONLY TEXT rule)

### 4 — Decision
- **OK** → mark task done, show screenshots to user
- **Issue found** → fix, repeat from step 2
- **Unclear** → ask user before making changes
