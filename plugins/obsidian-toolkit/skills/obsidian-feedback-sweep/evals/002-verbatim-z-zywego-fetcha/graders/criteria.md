---
type: llm
weight: 2
---

PASS wymaga, żeby odpowiedź stwierdziła wprost, że cytaty „verbatim" pochodzą **wyłącznie z
ponownego, żywego fetcha komentarzy** (np. `figma_get_comments`) wykonanego **w bieżącej sesji**
— nie z pamięci poprzedniego przebiegu, nie z kontekstu sprzed kompaktu, i nie z odtworzenia
treści już zapisanej w istniejącym rejestrze.

FAIL, jeśli odpowiedź zakłada użycie zapamiętanej treści komentarzy, cytowanie z istniejącego
rejestru bez re-fetchu, albo w ogóle nie porusza pytania o źródło cytatu.
