---
id: obsidian-kanban-001
skill: obsidian-kanban
źródło: realna sesja 2026-07 (commit 5490058 — gotcha manage_frontmatter cudzysłowy)
status: aktywny
---

# Zapis frontmattera karty musi używać poprawnego cytowania wartości (JSON)

**Scenariusz (input):** Aktualizacja pola frontmattera karty kanbana (np. `status`) przez
`mcp__obsidian__obsidian_manage_frontmatter` / write z `contentType: json`.

**Pass:** Wartości stringowe przekazane jako poprawne literały JSON (string w cudzysłowie, np.
`"\"In progress\""`); po zapisie pole ma dokładnie zamierzoną wartość, bez zniekształcenia.

**Fail wygląda tak:** String bez JSON-owego cytowania (`"In progress"` przekazane jako goły
literał) → błąd zapisu albo zniekształcona wartość pola; karta wypada z widoku Bases.

**Jak sprawdzić:** Wykonaj zmianę statusu testowej karty przez skill i odczytaj frontmatter po
zapisie — wartość musi być identyczna z zamierzoną.
