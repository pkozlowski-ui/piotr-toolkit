---
type: llm
weight: 2
---

Oceniasz WYŁĄCZNIE rozstrzygnięcie statusu dotkniętej karty kanbana — czy retro proponuje
następne zadanie mierzy inny grader.

PASS wymaga obu:
1. Retro **explicite rozstrzyga status** karty „Fix hit-area DS Switch" — skoro robota jest
   skończona i zweryfikowana, proponuje `Done` (z rekomendacją promote/archive), zamiast
   zostawić ją bez decyzji.
2. Retro proponuje **zdjęcie `claimed`** z tej karty.

FAIL, jeśli raport retro pomija kartę kanbana całkowicie (zostaje cicho na `In progress`), albo
nie wspomina o zdjęciu locka/`claimed`.
