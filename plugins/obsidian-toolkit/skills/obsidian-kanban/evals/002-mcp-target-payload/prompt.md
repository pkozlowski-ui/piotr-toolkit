---
name: 002-mcp-target-payload
description: Operacja MCP obsidian_* adresuje notatkę obiektem target, nie płaskim path
tags: [obsidian-kanban, mcp-payload]
runs: 2
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Pracuję z kanbanem w Obsidianie przez MCP. Chcę odczytać kartę `KANBAN/Testowa karta.md`.

UWAGA: nie masz teraz podpiętego vaultu ani narzędzi `mcp__obsidian__*` — nie próbuj niczego
wykonywać ani szukać plików. Odpowiedz z pamięci procedury: opisz dokładnie, jak byś to zrobił.

Napisz payload wywołania `obsidian_get_note`, którego użyjesz, i wyjaśnij, dlaczego akurat taki
kształt — a także jaki kształt jest błędny i czym się kończy.
