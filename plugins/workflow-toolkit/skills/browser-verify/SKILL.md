---
name: browser-verify
description: Visual UI verification in browser (desktop + mobile) before marking a task done. Auto-triggers after any UI change.
---

# Skill: browser-verify

## Auto-trigger
After any UI change. Exception: logic/data-only changes with no visual impact.

## Protocol

### 1 — Dev server
Check if already running. If not, start it:
- Next.js / React: `npm run dev` (port 3000)
- Vite: `npm run dev` (port 5173)
- Otherwise: check `package.json` → `scripts.dev`

Wait for "Ready" / "Local:" before continuing.

### 2 — Screenshots

Desktop (1440px):
```bash
npx playwright screenshot --viewport-size=1440,900 http://localhost:3000 /tmp/desktop.png
```

Mobile (375px):
```bash
npx playwright screenshot --viewport-size=375,812 http://localhost:3000 /tmp/mobile.png
```

Adjust port and path to the changed page as needed.

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
