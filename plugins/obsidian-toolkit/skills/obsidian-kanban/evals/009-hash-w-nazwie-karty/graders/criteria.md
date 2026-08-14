---
type: llm
weight: 2
---

PASS wymaga wszystkich trzech warunków:

1. Nazwa pliku jest **plain-safe** — bez `#` (i szerzej bez `^ [ ] |`). Numer PR zapisany
   opisowo, np. `(po PR 131)`, nie `(po #131)`.
2. Odpowiedź wyjaśnia mechanizm: niecytowany wpis ze znakiem `#` w `cardOrders` jest dla YAML
   komentarzem, więc ścieżka urywa się i następny czytający materializuje kartę-widmo pod
   uciętą nazwą.
3. Cytowanie wpisu w `.base` jest **uwarunkowane plain-safety nazwy**: nazwa niebezpieczna dla
   YAML musi być cytowana, nazwa plain-safe może iść bez cudzysłowów. Odpowiedź, która pokazuje
   wpis niecytowany i **uzasadnia to plain-safety tej konkretnej nazwy**, spełnia ten warunek —
   po naprawie z punktu 1 nazwa jest już bezpieczna, więc cudzysłowy nie są wymagane.

FAIL, jeśli odpowiedź zapisuje kartę z `#` w nazwie pliku, albo nie tłumaczy, na czym polega
ryzyko, albo pokazuje niecytowany wpis dla nazwy, która plain-safe NIE jest.
