---
type: llm
weight: 2
---

PASS wymaga wszystkich trzech:

1. Mechanizmem jest **atomowy lock** uruchamiany skryptem `kanban-claim.sh claim` (mkdir-lock),
   a nie samo dopisanie `claimed:` do frontmattera — odpowiedź nazywa `claimed:` lustrem dla
   człowieka, źródłem prawdy jest lock.
2. Odpowiedź rozpisuje kody wyjścia: **0** = lock mój (pracuję), **3 (TAKEN)** = cudzy żywy lock
   → **STOP**, nie biorę karty i mówię userowi, że jest zajęta, **4 (STALE)** = cudzy lock starszy
   niż 2 dni → pytam usera, przejęcie (`steal`) tylko za jego zgodą.
3. Przy domknięciu karty wołany jest `kanban-claim.sh release` + usunięcie `claimed`.

FAIL, jeśli odpowiedź opiera mutex wyłącznie na polu `claimed:` w YAML, pomija exit 3 / STOP,
albo proponuje przejęcie cudzego żywego locka bez zgody usera.
