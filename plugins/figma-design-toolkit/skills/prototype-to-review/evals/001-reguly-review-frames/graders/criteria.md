---
type: llm
weight: 2
---

Oceniasz WYŁĄCZNIE dwa warunki: źródło budowy i traktowanie brakującego komponentu DS.

PASS wymaga obu:
1. Klatki budowane **ze źródła kodu** (czytanie CSS/komponentów React), NIE przez zrzut ekranu /
   browser-capture / HTML-to-design.
2. Custom „status chip" bez odpowiednika w DS → zbudowany jako **prymityw z tokenami +
   adnotacja DS Drift**, NIE jako nowy komponent/master w design systemie.

FAIL, jeśli odpowiedź proponuje odrysowanie ze screenshotu/browser-capture, albo tworzy nowy
komponent DS dla chipa zamiast prymitywu.
