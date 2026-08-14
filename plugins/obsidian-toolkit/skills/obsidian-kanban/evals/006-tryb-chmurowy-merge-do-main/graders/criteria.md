---
type: llm
weight: 2
---

PASS wymaga, żeby odpowiedź powiedziała **wprost**, że karta pojawi się na desktopie dopiero
po **merge do `main`** — sam push na gałąź `claude/...` nie wystarczy, bo Obsidian Git ciągnie
tylko bieżącą gałąź desktopu i sam jej nie przełącza. Dopuszczalna alternatywa wymieniona obok:
`Fetch` + `Switch branch` na desktopie (z zastrzeżeniem, że bez `Fetch` gałęzi nie widać).

FAIL, jeśli odpowiedź kończy się na „gotowe, zrób pull" bez warunku merge/gałęzi, albo twierdzi,
że push na gałąź roboczą wystarczy, żeby karta była widoczna.
