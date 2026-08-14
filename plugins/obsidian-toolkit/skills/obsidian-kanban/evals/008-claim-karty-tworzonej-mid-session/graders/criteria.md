---
type: llm
weight: 2
---

PASS wymaga obu gałęzi rozgałęzienia:

1. **Biorę teraz:** przed pierwszą linią pracy nad nową kartą sesja woła
   `kanban-claim.sh claim <dir> "<karta>" <session_id>`, dostaje exit 0 i ustawia
   `status: In progress` + `claimed:` — dzięki temu druga sesja dostaje exit 3 i karta jest
   dla niej nietykalna. Utworzenie karty NIE jest traktowane jako „autorstwo" zwalniające
   z protokołu claim.
2. **Parkuję:** karta zostaje w `To-do` **bez** locka i bez `In progress` — brak locka jest
   poprawnym sygnałem „wolne, bierzcie".

Bonus (nie wymagany do PASS): odpowiedź zauważa, że hook `kanban-claim-guard.sh` tej ścieżki
nie pokryje, bo wyprowadza nazwę karty z promptu usera, a tej karty żaden prompt nie nazwał.

FAIL, jeśli odpowiedź zaczyna pracę nad nową kartą bez locka, albo zakłada lock również
w wariancie parkowania.
