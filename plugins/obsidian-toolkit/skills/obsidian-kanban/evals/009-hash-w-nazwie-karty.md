---
id: obsidian-kanban-009
skill: obsidian-kanban
źródło: realna sesja 2026-07-31 (board Manta — jedna karta jako 3 pliki: `(po #131).md` + stub `(po.md` 22 B + stub `(po 1.md` 0 B)
status: aktywny
---

# `#` w nazwie pliku karty produkuje karty-widma — nazwa musi być plain-safe, wpis w `.base` cytowany

**Scenariusz (input):** Karta zakładana z numerem PR/issue w tytule (`… (po #131)`), a potem
umieszczana w kolumnie skryptem `kanban-place-card.sh` — albo napotkana przy sprzątaniu boardu.

**Pass:**
1. Skill **nie tworzy** karty z `#` (ani `^ [ ] |`) w nazwie pliku — numer PR zapisuje jako `(po PR 131)`.
2. Napotkaną kartę z `#` **przemianowuje** (`mv`) i poprawia wpis w `.base` — nie ogranicza się do
   skasowania duplikatów, bo mina zostaje.
3. Wpis wstawiany do `cardOrders` jest **cytowany**, gdy nazwa nie jest plain-safe.

**Fail wygląda tak:** Niecytowany `- KANBAN/Karta (po #131).md` w `cardOrders` → dla YAML wszystko
od `#` to komentarz → następny czytający dostaje `KANBAN/Karta (po` i materializuje kartę-widmo pod
uciętą nazwą (zmierzone: dwa stuby — 22 B z samym `status:` jako drugi kafel w To-do i 0 B bez
frontmattera w kolumnie Uncategorized).

**Jak sprawdzić (break-restore, wykonane 2026-07-31):** Na tymczasowym boardzie z kartą
`KANBAN/Card (po #131).md` uruchom `kanban-place-card.sh … bottom` i sparsuj wynik YAML-em:
- shipowana wersja → wiersz `- "KANBAN/Card (po #131).md"`, parser zwraca **pełną** ścieżkę → PASS;
- kontrola negatywna (stara logika cytowania `":" in card`) → wiersz niecytowany, parser zwraca
  `"KANBAN/Card (po"` → FAIL.

Kontrola negatywna jest częścią checku: bez niej „ścieżka się parsuje" nie odróżnia poprawnego
cytowania od nazwy, która po prostu nie zawiera `#`.
