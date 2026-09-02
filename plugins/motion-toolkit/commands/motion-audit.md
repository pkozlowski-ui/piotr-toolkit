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

Pliki referencyjne tego skilla NIE leżą w repozytorium projektu — leżą w katalogu
zainstalowanego pluginu. Zlokalizuj je jedną komendą i przeczytaj ZANIM ocenisz cokolwiek:
```bash
D=$(ls -d ~/.claude/plugins/cache/*/motion-toolkit/*/skills/improve-animations 2>/dev/null | sort -V | tail -1)
ls "${D:-plugins/motion-toolkit/skills/improve-animations}"
```
Jeśli odczyt tego katalogu zostanie odrzucony (leży poza katalogiem projektu) — **powiedz
to wprost i zatrzymaj się**, zamiast oceniać na wyczucie. Trwałe odblokowanie: wpis
`permissions.additionalDirectories` w `~/.claude/settings.json` — patrz OVERVIEW.md.
