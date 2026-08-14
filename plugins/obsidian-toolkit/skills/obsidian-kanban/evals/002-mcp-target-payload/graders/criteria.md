---
type: llm
weight: 2
---

PASS wymaga obu warunków:

1. Payload adresuje notatkę **obiektem** `target`, czyli w kształcie
   `{"target": {"type": "path", "path": "KANBAN/Testowa karta.md"}}`.
2. Odpowiedź wskazuje, że płaski kształt `{"path": "..."}` kończy się błędem
   `MCP error -32602 Input validation error` (pusty przebieg + retry).

FAIL, jeśli payload jest płaski (`{"path": ...}`) albo brakuje uzasadnienia przez błąd -32602.
