---
name: 002-mcp-target-payload
description: Operacja MCP obsidian_* adresuje notatkę obiektem target, nie płaskim path
tags: [obsidian-kanban, mcp-payload]
runs: 2
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Chcę odczytać kartę `KANBAN/Testowa karta.md` z mojego vaultu Obsidiana przez MCP.

Nie wykonuj odczytu — napisz mi dokładny payload wywołania `obsidian_get_note`, który wyślesz,
i wyjaśnij, dlaczego akurat taki kształt.

Rationale i rodowód tego case'a: `../002-mcp-target-payload.md`.
