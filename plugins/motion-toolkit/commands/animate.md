---
description: Zbuduj animację od zera na bieżącym kodzie — z właściwą krzywą, czasem, właściwościami i przerywalnością
argument-hint: <co animować, np. drawer zamykany gestem / toast / wskaźnik zakładek>
---

Zadanie: zbuduj animację dla **$ARGUMENTS**.

1. Załaduj Skill `motion-toolkit:animate` — to jest kanon dla tej roboty; jego sekwencja decyzji
   (czy w ogóle animować → cel → narzędzie → właściwości → krzywa/czas lub sprężyna → przerwanie
   i wyjście → reduced-motion) jest obowiązkowa, nie orientacyjna. Receptury komponentowe siedzą
   w `RECIPES.md` — sprawdź recepturę, zanim napiszesz cokolwiek od zera.
2. Rozpoznaj kontekst PRZED implementacją: jakiego stacku używa ten projekt (CSS / Tailwind /
   Motion / WAAPI), jakie ma już tokeny ruchu (`--ease-*`, `--duration-*`) i czy istnieje podobna
   animacja, z którą nowa ma być spójna. Nie wprowadzaj nowej biblioteki bez pytania.
3. Zaimplementuj tak, żeby przeszło `motion-toolkit:review-animations` za pierwszym razem.
4. Zweryfikuj przed deklaracją „gotowe" — realny stan, nie pamięć: `workflow-toolkit:browser-verify`
   albo równoważny dowód. Przy ruchu sprawdzaj też, czy krzywa nie urywa się nagle i czy
   `transform-origin` jest właściwy (podbij czas ×3 na czas sprawdzenia).

Jeśli nie podano czego animować, zapytaj o to jednym zdaniem i czekaj — nie zgaduj.

---

Pliki referencyjne tego skilla (`STANDARDS.md`, `RECIPES.md`, `AUDIT.md`, `PLAN-TEMPLATE.md`)
leżą **w katalogu samego skilla, obok jego `SKILL.md`** — NIE w repozytorium projektu.
Zainstalowany plugin trzyma je pod:
`<katalog domowy>/.claude/plugins/cache/*/motion-toolkit/<najwyższa wersja>/skills/animate/`
Znajdź je narzędziem **Glob** (wzorzec `**/motion-toolkit/*/skills/animate/*.md` z `path`
ustawionym na katalog cache pluginów), a potem przeczytaj **Read**. Nie używaj Basha —
w zakresie jest odczyt plików, nie wywołanie shella. W repo toolkitu ta sama treść leży
pod `plugins/motion-toolkit/skills/animate/`.
Jeśli odczyt zostanie odrzucony — **powiedz to wprost i zatrzymaj się**, zamiast oceniać
na wyczucie. Trwałe odblokowanie: `permissions.additionalDirectories` w
`~/.claude/settings.json` (katalog cache pluginów) — patrz OVERVIEW.md.
