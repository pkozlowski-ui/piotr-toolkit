---
id: obsidian-kanban-007
skill: obsidian-kanban
źródło: realna kolizja 2026-07-20 (dwie sesje zrobiły ten sam task MAN-516 date-picker — doradczy claimed: z 004 nie zapobiegł, bo jedna sesja pracowała 10 min NIE ustawiając claima)
status: aktywny
---

# Wzięcie karty przechodzi przez ATOMOWY lock (kanban-claim.sh), a kolizja z żywą sesją = twardy STOP

**Scenariusz (input):** Dwie sesje na tej samej maszynie chcą wziąć tę samą kartę. Sesja A już
trzyma lock (`kanban-claim.sh claim` zwróciło 0). Sesja B — startowana handoffem z nazwą tej karty
w promptcie — próbuje ją wziąć.

**Pass:** Sesja B uruchamia `kanban-claim.sh claim` (nie polega na samej edycji frontmattera),
dostaje **exit 3 (TAKEN)** i **zatrzymuje się** — nie robi zadania, mówi userowi „karta zajęta przez
inną sesję". (Enforcement: UserPromptSubmit guard robi to na 1. turze automatycznie.) Przy domknięciu
karty sesja A woła `kanban-claim.sh release`.

**Fail wygląda tak:** Sesja pracuje nad kartą BEZ założenia locka (sam `claimed:` w YAML lub nic) →
druga sesja nie ma jak wykryć kolizji → obie robią ten sam task (duplikat, zmarnowany kontekst).
Albo: skill traktuje `claimed:` jako źródło prawdy zamiast locka (nieatomowy read-then-write race).

**Jak sprawdzić:** `kanban-claim.sh claim <dir> <karta> sessA` (0) → `… claim <dir> <karta> sessB`
musi zwrócić 3. Guard: `printf '{"session_id":"sessB","prompt":"Zadanie z kanban: \"<karta>\""}' |
kanban-claim-guard.sh` → exit 2 (STOP). Po `release` przez sessA → sessB claim zwraca 0.
