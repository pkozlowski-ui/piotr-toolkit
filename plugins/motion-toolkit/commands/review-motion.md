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

Pliki referencyjne tego skilla NIE leżą w repozytorium projektu — leżą w katalogu
zainstalowanego pluginu. Zlokalizuj je jedną komendą i przeczytaj ZANIM ocenisz cokolwiek:
```bash
ls ~/.claude/plugins/cache/*/motion-toolkit/*/skills/review-animations/ 2>/dev/null || ls plugins/motion-toolkit/skills/review-animations/
```
