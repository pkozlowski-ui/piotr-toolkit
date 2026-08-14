---
type: llm
weight: 2
---

PASS wymaga obu warunków:

1. Właściwym zakresem jest **smoke check jednej zmiany**, oddany do `browser-verify` — czyli
   tańszy tier POD audytem zgodności.
2. Odpowiedź **odmawia pełnej pętli audytu** na jednej edycji paddingu i mówi dlaczego:
   jedna zmiana nie uzasadnia sekwencji audytowej.

FAIL, jeśli odpowiedź uruchamia pełną pętlę audytu zgodności, albo proponuje przechwytywanie
baseline'ów / warstwy parity dla jednej zmiany paddingu, albo nie nazywa właściwego właściciela
zadania.
