---
type: llm
weight: 2
---

PASS wymaga obu warunków:

1. Nazwa pliku jest **plain-safe** — bez `#` (i szerzej bez `^ [ ] |`). Numer PR zapisany
   opisowo, np. `(po PR 131)`, nie `(po #131)`.
2. Odpowiedź wyjaśnia mechanizm: niecytowany wpis ze znakiem `#` w `cardOrders` jest dla YAML
   komentarzem, więc ścieżka urywa się i następny czytający materializuje kartę-widmo pod
   uciętą nazwą. Wpis w `.base` ma być **cytowany**, gdy nazwa nie jest plain-safe.

FAIL, jeśli odpowiedź zapisuje kartę z `#` w nazwie pliku, albo pokazuje niecytowany wpis
w `cardOrders`, albo nie tłumaczy, na czym polega ryzyko.
