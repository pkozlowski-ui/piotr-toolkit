---
type: llm
weight: 1
---

Oceniasz WYŁĄCZNIE, czy odpowiedź uruchamia gate przed publikacją — nie karz tutaj za nic innego.

PASS: odpowiedź uruchamia `preflight_artifact.py` (albo nazywa równoważny gate weryfikujący
brak wrappera/external/Google Fonts) na wynikowym pliku i wymaga zielonego wyniku (exit 0 / zero
pozycji FAIL) PRZED wywołaniem narzędzia Artifact.

FAIL, jeśli odpowiedź pomija ten krok gate'u albo publikuje bez potwierdzenia jego wyniku.
