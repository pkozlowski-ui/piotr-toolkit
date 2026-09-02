# Upstream — emilkowalski/skills

Skille w `skills/` są **vendorowane 1:1** (bez zmian w treści) z:

- repo: https://github.com/emilkowalski/skills
- licencja: MIT © 2026 Emil Kowalski (kopia: `LICENSE.upstream`)
- commit: `d23d7f88a2e21c9e4b1418c7abe420f5c1052ba7` (2026-08-21)

## Vendorowany subset (6 z 13)

| Skill | Po co |
|---|---|
| `animate` (+ `RECIPES.md`) | budowa animacji od zera, 14 receptur komponentowych |
| `review-animations` (+ `STANDARDS.md`) | strict review ruchu; STANDARDS to tabele liczbowe (easing, durations, spring, GPU) |
| `improve-animations` (+ `AUDIT.md`, `PLAN-TEMPLATE.md`) | audyt codebase'u → plany wykonywalne przez tańsze modele |
| `find-animation-opportunities` | gdzie warto dodać ruch — z obowiązkową listą odrzuconych |
| `animation-vocabulary` | opis efektu → jego nazwa (do ticketów i komentarzy) |
| `apple-design` | WWDC *Designing Fluid Interfaces* przełożone na web |

## Świadomie pominięte

`write-swift`, `animate-expo` (React Native), `ask-sonner` (biblioteka autora),
`pick-ui-library` (opinie o zależnościach — nasze decyzje techniczne mamy własne),
`emil-design-eng` (nadzbiór treści z `animate` + `review-animations` — dublowałby kontekst),
`prototype` (nakłada się na `workflow-toolkit:claude-artifact-prototype`; jego picker wariantów
to osobna karta, nie doklejka).

## Aktualizacja

```bash
bash plugins/motion-toolkit/scripts/sync-upstream.sh
```

Skrypt podmienia subset na najnowszy upstream i wypisuje diff. **Nie edytuj plików w `skills/`
ręcznie** — własne reguły trzymamy w `commands/` i w skillach `design-toolkit`, żeby sync
pozostał bezkonfliktowy.
