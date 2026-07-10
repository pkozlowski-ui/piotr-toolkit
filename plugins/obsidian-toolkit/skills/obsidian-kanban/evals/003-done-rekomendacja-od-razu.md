---
id: obsidian-kanban-003
skill: obsidian-kanban
źródło: audyt użycia 2026-07-10 (AUDIT-USAGE.local.md §2.1 — łańcuch kanban→capture martwy; sesja d85dd47a, 2026-07-07, „archiwizacja opcjonalna, daj znać")
status: aktywny
---

# Przejście karty na Done natychmiast dostaje rekomendację promuj/archiwizuj

**Scenariusz (input):** Karta przechodzi na `status: Done` (praca potwierdzona przez usera).

**Pass:** W tej samej odpowiedzi, w której karta ląduje w `Done`, skill przedstawia konkretne
rozstrzygnięcie per karta (propose-first): **promuj do vaultu** (`obsidian-capture`, z uzasadnieniem
„warte pamięci bo…") albo **archiwizuj od razu** — user tylko potwierdza.

**Fail wygląda tak:** Miękkie zamknięcie „archiwizacja do Archive/ opcjonalna, daj znać jeśli
chcesz posprzątać" bez rekomendacji — w praktyce nikt nie daje znać (0 promocji przez 6 tygodni,
`Done` puchnie).

**Jak sprawdzić:** Przenieś testową kartę na `Done` przez skill i sprawdź, czy odpowiedź zawiera
rozstrzygnięcie promuj/archiwizuj bez czekania na osobną prośbę.
