# Kanban — config per-projekt + przepis na digest

## Config per-projekt
Skill odkrywa strukturę z `.base`, ale projekt może wskazać domyślną tablicę w `CLAUDE.md`:
- **Plik tablicy:** `<folder>/<nazwa>.base`
- **Property grupujące:** zwykle `note.status`
- **Słownik kolumn:** lista wartości w kolejności

### Przykład — Manta Vault (board cross-project Piotra)
- Tablica: `KANBAN/-Kanban Board.base` · grupa `note.status`
- Kolumny: `Lab` → `To-do` → `In progress` → `To confirm` → `Done`
- Kolory: `To confirm: yellow`, `In progress: cyan`
- Tagi: `high-priority` (wyjątkowo ważne) · `blocked` (ktoś/coś blokuje — *co* w karcie)
- **Semantyka** (kanon — patrz też vault `Kanban — jak pracuję.md`):
  - `Lab` = lodówka: do zbadania · przemyślenia · możliwe projekty (3 kubełki przy triage).
  - `To-do` = backlog; „następne" trzymane na górze (kolejność = priorytet).
  - `In progress` = **tylko realnie aktywne** (nie „zaraz zacznę").
  - `To confirm` = zrobione, czeka na feedback zespołu (wejście dla feedback-sweep); 2 wyjścia: Done / wraca do To-do.
  - `Done` = warte pamięci dla zespołu → **kandydat do promocji do vaultu** (`obsidian-capture`); osobiste/małe → kasować.

## Przepis na digest (token-safe)
1. Odczytaj `.base`: `groupByProperty`, `columnOrders.<prop>`, `filters` (folder + wykluczenia).
2. Wylistuj notatki w folderze (pomiń sam `.base` i wykluczone).
3. Czytaj **tylko frontmatter** każdej karty (status, tags) — nie pełne treści.
4. Pogrupuj per kolumna w kolejności z `.base`. Dla każdej: liczba + tytuły kart.
5. Wyróżnij: `In progress`, `To confirm` (kolejka usera), karty z tagiem priorytetu, licznik `Lab`.

## Wzorce zapisu (propose-first)
- **Move:** edytuj tylko linię `status:` we frontmatter. Nie ruszaj nazwy pliku.
- **Create:** nowa notatka z `status: <kolumna>`; jeśli status nowy → dopisz do `columnOrders` w `.base`.
- **Promote z backlogu:** dla każdego itemu karta `status: To-do` + backlink `[[źródło]]` (lista w cudzysłowach).
