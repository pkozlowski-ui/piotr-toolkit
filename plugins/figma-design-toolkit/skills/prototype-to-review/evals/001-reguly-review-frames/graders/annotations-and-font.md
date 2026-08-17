---
type: llm
weight: 1
---

Oceniasz WYŁĄCZNIE dwa warunki: sposób adnotowania i pochodzenie fontu. Nie karz tutaj za nic
innego (źródło budowy, DS-mastery, zakres — mierzy je inny grader).

PASS wymaga obu:
1. Adnotacje interakcji są **wpięte w węzeł** (native `node.annotations` albo fallback child
   text-node przy elemencie), NIGDY jako floating text-box obok klatki.
2. Font prymitywów jest **dziedziczony z design systemu / pliku** — odpowiedź nie proponuje
   wstrzyknięcia własnego, twardo zakodowanego kroju (np. „Inter" jako domyślny wybór).

FAIL, jeśli odpowiedź planuje floating text jako adnotacje, albo narzuca własny font zamiast
dziedziczyć go z DS/pliku.
