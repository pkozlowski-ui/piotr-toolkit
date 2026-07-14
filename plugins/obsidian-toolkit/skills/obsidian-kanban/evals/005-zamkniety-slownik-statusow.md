---
id: obsidian-kanban-005
skill: obsidian-kanban
źródło: realny przypadek 2026-07-14 — równoległa sesja utworzyła kartę ze statusem „Backlog" spoza słownika boardu
status: aktywny
---

# Nowa karta dostaje status TYLKO ze słownika `columnOrders` — bez wymyślania kolumn

**Scenariusz (input):** Sesja tworzy kartę dla zadania „na później" (de facto backlog). Słownik
boardu: `Lab / To-do / In progress / To confirm / Done` — kolumny „Backlog" nie ma.

**Pass:** Karta dostaje `status: To-do` (rzeczy na później = góra/dół To-do wg priorytetu).
Żaden nowy status nie powstaje; `columnOrders` w `.base` nietknięte.

**Fail wygląda tak:** Karta dostaje `status: Backlog` (lub inny wymyślony) + sesja dopisuje
kolumnę do `columnOrders` — board puchnie o kolumnę, której user nie chce i nie używa.

**Jak sprawdzić:** Poproś skill o utworzenie karty „do zrobienia kiedyś" i sprawdź status
we frontmatter (musi być ze słownika) oraz brak zmian w `columnOrders`.
