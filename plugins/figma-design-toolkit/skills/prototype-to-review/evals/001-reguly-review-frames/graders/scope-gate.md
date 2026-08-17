---
type: llm
weight: 1
---

Oceniasz WYŁĄCZNIE bramkę zakresu — nie karz tutaj za nic innego.

PASS: scenariusz ma 4 stany interakcji (≥3), więc odpowiedź pokazuje zwięzły plan (ile klatek,
jakie stany) i **czeka na wybór usera co do zakresu**, zanim zadeklaruje budowę wszystkich klatek.

FAIL, jeśli odpowiedź od razu buduje/planuje zbudować komplet klatek bez zatrzymania się i
zapytania o zakres.
