---
description: Audyt całego motion w projekcie → priorytetyzowane znaleziska i samodzielne plany do wykonania
argument-hint: [obszar, np. onboarding / cały app]
---

Zadanie: zaudytuj animacje w projekcie i wyprodukuj plany naprawcze.

Obszar: **$ARGUMENTS** (puste = cały codebase).

1. Załaduj Skill `motion-toolkit:improve-animations`; rubryka ośmiu wymiarów siedzi w `AUDIT.md`,
   format planu w `PLAN-TEMPLATE.md`. Oba leżą obok `SKILL.md` w katalogu pluginu
   (`${CLAUDE_PLUGIN_ROOT}/skills/improve-animations/`) — czytaj je stamtąd, nie z repo projektu.
   Wartości liczbowe bierz z `${CLAUDE_PLUGIN_ROOT}/skills/review-animations/STANDARDS.md`.
2. Trzymaj podział pracy zgodny z moją regułą doboru modelu: **osąd i priorytetyzacja tutaj
   (Opus), rekonesans i mechaniczne przeszukiwanie delegowane do tańszych subagentów**, a plany
   pisz tak, żeby wykonał je Sonnet/Haiku bez tej rozmowy w kontekście.
3. Read-only na kodzie źródłowym — audyt planuje, nie naprawia. Zanim cokolwiek zostanie
   wykonane, pokaż mi ranking i poczekaj na decyzję, co wchodzi.
