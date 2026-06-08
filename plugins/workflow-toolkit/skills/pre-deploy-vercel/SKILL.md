---
name: pre-deploy-vercel
description: Pre-deploy checklist dla projektów Next.js na Vercel — łapie powtarzalne build-faile ZANIM trafią do CI. Uruchamia się gdy user mówi "deploy", "przed deployem", "wypchnij na Vercel", "czy zbuduje się na Vercel", "vercel build", "gotowe na produkcję".
---

# Skill: pre-deploy-vercel

Vercel buduje inaczej niż `npm run dev` — rzeczy, które działają lokalnie w dev, wywalają build w CI.
Ten skill przechodzi listę powtarzalnych pułapek **zanim** zrobisz push. Cel: zero „czerwonego" deploya
z powodu znanego gotchy.

## Auto-trigger
"deploy" / "przed deployem" / "wypchnij na Vercel" / "czy zbuduje się na Vercel" / "vercel build" / "gotowe na produkcję"

## Krok 0 — Zbuduj lokalnie (najważniejsze)
```bash
npm run build      # lub: next build  (+ --workspace=<app> w monorepo)
```
Lokalny `build` (nie `dev`) wyłapuje większość poniższych sam. Jeśli przechodzi — i tak przejrzyj checklistę.

## Gotchas (Next.js App Router + Vercel)

1. **`useSearchParams` / `usePathname` bez `<Suspense>`** → build fail.
   Komponent czytający search params musi być opakowany w `<Suspense>` (CSR bailout). Sprawdź każde użycie.

2. **Provider z function-props w Server Component** → `Functions cannot be passed directly to Client Components`.
   Provider, który dostaje funkcje (theme, ikony, callbacki) musi żyć w komponencie `'use client'` — nie wstawiaj go
   bezpośrednio w `layout.tsx` (server). Wzorzec: `providers.tsx` z `'use client'`. (Realny przypadek: `<MantineProvider theme={...}>`.)

3. **Niezacommitowane assety z `.gitignore`** → broken CI.
   Jeśli `.gitignore` blokuje np. `public/*.png`, a kod/build ich oczekuje — na Vercel ich nie ma. Sprawdź:
   ```bash
   git status --ignored --short -- public | head
   git ls-files --error-unmatch <ścieżka-do-asseta>   # czy asset jest w gicie?
   ```
   Dodaj wyjątek w `.gitignore` (`!public/**/*.png`) albo zacommituj asset.

4. **Env vars tylko lokalnie (`.env`)** → runtime/build fail na Vercel.
   Każda zmienna używana w buildzie/runtime musi być w Vercel project settings. `NEXT_PUBLIC_*` muszą istnieć w czasie buildu.

5. **Case-sensitivity importów** → działa na macOS (case-insensitive), pada na Vercel (Linux).
   `import Button from './button'` vs plik `Button.tsx` — sprawdź zgodność wielkości liter w importach.

6. **`next.config` `transpilePackages`** dla workspace deps w monorepo — brak → moduł nie zbuduje się.

## Output
Przejdź punkty, raportuj per punkt: ✅ ok / ⚠️ ryzyko (gdzie) / ❌ blocker (plik:linia + fix).
Na końcu jednoznacznie: **gotowe na deploy** albo lista blockerów do naprawy.

> Sam deploy (CLI/promote/rollback) → użyj zewnętrznego `vercel:deploy` / Vercel MCP. Ten skill to tylko bramka jakości PRZED deployem.
