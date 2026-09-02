---
description: Audyt całego motion w projekcie → priorytetyzowane znaleziska i samodzielne plany do wykonania
argument-hint: [obszar, np. onboarding / cały app]
---

Zadanie: zaudytuj animacje w projekcie i wyprodukuj plany naprawcze.

Obszar: **$ARGUMENTS** (puste = cały codebase).

1. Załaduj Skill `motion-toolkit:improve-animations`; rubryka ośmiu wymiarów siedzi w `AUDIT.md`,
   format planu w `PLAN-TEMPLATE.md`; wartości liczbowe w `STANDARDS.md` skilla
   `review-animations`.
2. Trzymaj podział pracy zgodny z moją regułą doboru modelu: **osąd i priorytetyzacja tutaj
   (Opus), rekonesans i mechaniczne przeszukiwanie delegowane do tańszych subagentów**, a plany
   pisz tak, żeby wykonał je Sonnet/Haiku bez tej rozmowy w kontekście.
3. Read-only na kodzie źródłowym — audyt planuje, nie naprawia. Zanim cokolwiek zostanie
   wykonane, pokaż mi ranking i poczekaj na decyzję, co wchodzi.

---

Pliki referencyjne tego skilla (`STANDARDS.md`, `RECIPES.md`, `AUDIT.md`, `PLAN-TEMPLATE.md`)
leżą **w katalogu zainstalowanego pluginu**, NIE w repozytorium projektu:
`~/.claude/plugins/cache/*/motion-toolkit/*/skills/improve-animations/` (weź najwyższą wersję).
W repo toolkitu ta sama treść leży pod `plugins/motion-toolkit/skills/improve-animations/`.
Zlokalizuj je i przeczytaj **dowolnym narzędziem, które masz w tej sesji** — Read wprost,
Glob, albo `ls`/`cat` w Bashu. Żadne z nich nie jest zakazane; liczy się, żeby treść
referencji faktycznie trafiła do kontekstu ZANIM ocenisz lub zbudujesz cokolwiek.
Jeśli wszystkie drogi zawiodą — **powiedz to wprost i zatrzymaj się**, zamiast pracować
na wyczucie.
