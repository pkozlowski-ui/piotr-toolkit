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
leżą **w katalogu zainstalowanego pluginu**, NIE w repozytorium projektu:
`~/.claude/plugins/cache/*/motion-toolkit/*/skills/animate/` (weź najwyższą wersję).
W repo toolkitu ta sama treść leży pod `plugins/motion-toolkit/skills/animate/`.
Zlokalizuj je i przeczytaj **dowolnym narzędziem, które masz w tej sesji** — Read wprost,
Glob, albo `ls`/`cat` w Bashu. Żadne z nich nie jest zakazane; liczy się, żeby treść
referencji faktycznie trafiła do kontekstu ZANIM ocenisz lub zbudujesz cokolwiek.
Jeśli wszystkie drogi zawiodą — **powiedz to wprost i zatrzymaj się**, zamiast pracować
na wyczucie.
