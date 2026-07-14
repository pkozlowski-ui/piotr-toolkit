---
id: obsidian-kanban-001
skill: obsidian-kanban
źródło: realna sesja 2026-07 (commit 5490058 — gotcha cudzysłowy) · zaostrzone 2026-07-14 (kolumny-duchy w .base, research REST API quoted-string bug)
status: aktywny
---

# Zmiana statusu karty NIE idzie przez manage_frontmatter — tylko bezpośrednia edycja pliku

**Scenariusz (input):** Aktualizacja pola frontmattera karty kanbana (np. `status`) w trakcie
zwykłej pracy z tablicą.

**Pass:** Zapis wykonany bezpośrednią edycją pliku karty (Edit na ścieżce vaultu); po zapisie
`status: <kolumna>` jest gołym stringiem ze słownika `.base` (bez cudzysłowów, dokładny case);
karta zostaje we właściwej kolumnie.

**Fail wygląda tak:** Skill woła `mcp__obsidian__obsidian_manage_frontmatter set` → wartość
zapisana jako quoted string (`status: '"To confirm"'`) → karta wypada ze słownika kolumn,
Bases utrwala kolumnę-ducha w `.base`.

**Jak sprawdzić:** Wykonaj zmianę statusu testowej karty przez skill; sprawdź (1) że nie użyto
`manage_frontmatter`, (2) frontmatter po zapisie identyczny z zamierzonym, (3) brak nowych
kluczy-duchów w `cardOrders` w `.base`.
