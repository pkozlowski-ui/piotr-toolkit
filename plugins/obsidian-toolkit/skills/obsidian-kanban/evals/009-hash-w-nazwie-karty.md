---
id: obsidian-kanban-009
skill: obsidian-kanban
źródło: realna sesja 2026-07-31 (board Manta — jedna karta jako 3 pliki: `(po #131).md` + stub `(po.md` 22 B + stub `(po 1.md` 0 B); NAWRÓT 2026-08-25 (`Ogon po #488 …` — cytowany wpis w `.base`, a mimo to widmo `Ogon po.md` 0 B + wikilink czytany jako anchor)
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

## Nawrót 2026-08-25 — cytowanie nie wystarcza, bramka przeniesiona na NAZWĘ

Reguła (pkt 1 wyżej) istniała i została **złamana ponownie**: karta `Ogon po #488 — resztki
sales-demo w Staff Experience.md` powstała z **poprawnie cytowanym** wpisem w `.base` — czyli
soczewka z eval-a przechodziła — a i tak dała dwa pozostałe objawy: **0-bajtową kartę-widmo**
`Ogon po.md` (kafel w Uncategorized) i **wikilink** `[[Ogon po #488 …]]`, który Obsidian czyta
jako notatkę „Ogon po " + anchor „488 …". Wniosek: cytowanie ratuje `.base`, nie nazwę — dwa
z trzech objawów siedzą poza tym plikiem, więc reguła bez mechanizmu jest nieodróżnialna od
braku reguły.

**Domknięcie (mechanizm, nie apel):**
- `kanban-card-name.sh sanitize|check` — jedno miejsce, które **posiada** regułę nazwy
  (`#<cyfry>` → `PR <cyfry>`, resztę `# ^ [ ] |` i padding usuwa).
- `kanban-place-card.sh` **odmawia** umieszczenia karty o niebezpiecznej nazwie (exit 1 +
  gotowa komenda `mv`), zamiast obejść problem cytowaniem.

**Pass (dodatkowe do 3 punktów wyżej):**
4. `sanitize` na realnym tytule zwraca dokładnie nazwę, którą człowiek wybrałby ręcznie.
5. `place-card` na karcie z `#` **kończy się exit 1** i nie tyka `.base`.
6. Ta odmowa jest **jedyną** rzeczą, która to zatrzymuje (kontrola negatywna).

**Break-restore (wykonane 2026-08-25):**
- `sanitize "Ogon po #488 — resztki sales-demo w Staff Experience"` → `Ogon po PR 488 — resztki
  sales-demo w Staff Experience` (identyczne z nazwą wybraną ręcznie w tej samej sesji) ✅
- `sanitize "Karta (po #131).md"` → `Karta (po PR 131)`; `sanitize "  Karta ^x [y] |z  "` →
  `Karta x y z` ✅
- `check` na nazwie z `#` → **exit 2**; na `Ogon po PR 488 …` → **exit 0**; na `Zwykla karta bez
  niczego.md` → **exit 0** (kontrola negatywna: bezpieczna nazwa nie może strzelić) ✅
- `place-card` na `KANBAN/Karta (po #131).md` → **exit 1**, komunikat z gotowym `mv`; po
  `chmod -x kanban-card-name.sh` ta sama komenda **przechodzi** (exit 0) → guard jest jedynym
  hamulcem; po `chmod +x` znów exit 1 ✅
- Happy path nietknięty: z zaślepką na `pgrep` (Obsidian „zamknięty") `place-card` dopisuje
  `- KANBAN/Druga bezpieczna.md` i `yaml.safe_load` zwraca **2 pełne ścieżki** ✅
