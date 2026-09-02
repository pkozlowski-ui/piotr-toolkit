---
description: Strict review animacji w bieżącym diffie (albo we wskazanej ścieżce) wobec twardych standardów ruchu
argument-hint: [ścieżka lub zakres, domyślnie bieżący diff]
---

Zadanie: zrób strict review ruchu.

Zakres: **$ARGUMENTS** — a jeśli puste, weź bieżący diff (`git diff` + `git diff --staged`;
gdy oba puste, `git show HEAD`).

1. Załaduj Skill `motion-toolkit:review-animations`. Ten skill ma `disable-model-invocation: true`,
   więc odpala się WYŁĄCZNIE stąd — załaduj go jawnie.
   Wartości liczbowe siedzą w jego `STANDARDS.md` — review bez tych tabel to review na
   wyczucie, czyli dokładnie to, czego ten skill ma nie robić.
2. Trzymaj jego postawę: domyślnie flagujesz, akceptacja jest zasłużona. Wartości liczbowe
   (krzywe, budżety czasu, konfiguracja sprężyn) cytuj z `STANDARDS.md`, nie przybliżaj.
3. Wymagany format wyjścia: tabela znalezisk + werdykt pogrupowany po wadze + jawne
   **Block / Approve**. Każde znalezisko z `plik:linia`.
4. To review, nie naprawa — nie wprowadzaj zmian, dopóki nie poproszę.

---

Pliki referencyjne tego skilla (`STANDARDS.md`, `RECIPES.md`, `AUDIT.md`, `PLAN-TEMPLATE.md`)
leżą **w katalogu zainstalowanego pluginu**, NIE w repozytorium projektu:
`~/.claude/plugins/cache/*/motion-toolkit/*/skills/review-animations/` (weź najwyższą wersję).
W repo toolkitu ta sama treść leży pod `plugins/motion-toolkit/skills/review-animations/`.
Zlokalizuj je i przeczytaj **dowolnym narzędziem, które masz w tej sesji** — Read wprost,
Glob, albo `ls`/`cat` w Bashu. Żadne z nich nie jest zakazane; liczy się, żeby treść
referencji faktycznie trafiła do kontekstu ZANIM ocenisz lub zbudujesz cokolwiek.
Jeśli wszystkie drogi zawiodą — **powiedz to wprost i zatrzymaj się**, zamiast pracować
na wyczucie.
