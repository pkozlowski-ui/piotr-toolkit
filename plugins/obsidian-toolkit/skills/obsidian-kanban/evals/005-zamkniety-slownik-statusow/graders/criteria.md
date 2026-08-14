---
type: llm
weight: 2
---

PASS: karta dostaje status **ze słownika boardu** — dla zadania „na kiedyś" właściwą wartością
jest `To-do` (kolejność w kolumnie = priorytet), ewentualnie `Lab`, jeśli odpowiedź uzasadnia,
że rzecz nie jest jeszcze gotowa do uruchomienia. Odpowiedź stwierdza wprost, że słownik
statusów jest **zamknięty** i nie wymyśla się nowych kolumn.

FAIL, jeśli odpowiedź nadaje status spoza słownika (np. `Backlog`, `Someday`, `Later`) albo
proponuje dopisanie nowej kolumny do `columnOrders` bez wyraźnego polecenia usera.
