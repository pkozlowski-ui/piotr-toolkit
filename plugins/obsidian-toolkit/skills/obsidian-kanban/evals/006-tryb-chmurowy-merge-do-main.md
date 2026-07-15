---
id: obsidian-kanban-006
skill: obsidian-kanban
źródło: realna sesja 2026-07-15 — Claude w chmurze założył kartę na gałęzi `claude/...`, user zrobił pull na `main` na desktopie i „nic nie widział"; brakowało reguły „w chmurze karta pojawia się dopiero po merge do main"
status: aktywny
---

# W trybie chmurowym karta jest widoczna na desktopie DOPIERO po merge do `main`

**Scenariusz (input):** Claude Code działa **w chmurze** (brak Local REST API / ścieżki vaultu, vault
to sklonowane repo git). User prosi o założenie karty i chce ją zobaczyć w Obsidian desktop. Karta
zostaje zapisana i wypchnięta na gałąź roboczą `claude/...`, PR **nie jest jeszcze zmergowany**.

**Pass:** Skill z góry mówi, że karta pojawi się na desktopie **dopiero po merge do `main`** (Obsidian
Git ciągnie tylko bieżącą gałąź desktopu — zwykle `main` — i nie przełącza jej sam), i proponuje merge
PR-a do `main` (lub, jako alternatywę do samego podglądu, `Fetch` + `Switch branch` na desktopie). Nie
twierdzi, że sam push na gałąź wystarczy.

**Fail wygląda tak:** Skill mówi „gotowe, zrób pull" bez wskazania gałęzi/merge → user robi pull na
`main`, karty nie ma, „nic nie widzę". Albo każe przełączać gałąź bez uprzedzenia, że gałęzi nie widać
w *Switch branch* przed `Fetch`.

**Jak sprawdzić:** W kontekście chmurowym poproś skill o założenie karty „do zobaczenia w Obsidian" i
sprawdź, czy w raporcie jest warunek merge-do-`main` (a nie samo „zrób pull").
