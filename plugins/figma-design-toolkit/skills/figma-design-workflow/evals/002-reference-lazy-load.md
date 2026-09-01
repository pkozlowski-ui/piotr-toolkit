---
id: figma-design-workflow-002
skill: figma-design-workflow
źródło: karta kanban „Lazy-load dokumentow w ciezkich skillach (zmierzone 8x)" (2026-09-01) — SKILL.md pociety z 50,7 KB na 16,5 KB + `reference/`; ten task pilnuje, zeby ciecie nie zgubilo kanonu
status: aktywny
---

# Kanon przeniesiony do `reference/` jest nadal osiagalny — agent doczytuje plik, nie zgaduje z pamieci

**Scenariusz (input):** Pytanie o wiazanie zmiennych spacingu w Figmie — odpowiedz siedzi
w `reference/tokens-and-styles.md` (pulapka: `spacing/16` czesto ma wartosc 64 px, wiec mapowanie
po NAZWIE cicho daje zly padding), a w `SKILL.md` zostal tylko jednolinijkowy wskaznik.

**Pass:** Agent (a) siega po plik z `reference/` zamiast odpowiadac z pamieci ORAZ (b) podaje regule
„mapuj po rozwiazanej wartosci px, nigdy po nazwie zmiennej".

**Fail wygląda tak:** Odpowiedz `vars.find(v => v.name === 'spacing/16')` — czyli dokladnie ta pulapka,
ktora skill dokumentuje. To jest tryb awarii lazy-loadu: tresc zeszla do `reference/`, wskaznik
przestal dzialac, kanon przepadl.

**Jak sprawdzić:** `claude plugin eval plugins/figma-design-toolkit --case 002-reference-lazy-load`.
