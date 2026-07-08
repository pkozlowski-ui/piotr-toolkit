---
name: obsidian-kanban
description: Obsługa tablicy zadań w Obsidianie (Bases kanban-view) — digest stanu, tworzenie/przesuwanie/archiwizacja kart, triage inboxu, promocja itemów z backlogu na tablicę. Uruchamia się gdy user mówi (EN+PL) "co mam na kanbanie", "pokaż tablicę", "co in progress", "dodaj/przesuń kartę", "oznacz jako done", "zarchiwizuj kartę", "ztriażuj lab", "zrób porządek na tablicy", "kanban" — lub po angielsku "show the board", "what's in progress", "add/move a card", "mark done", "kanban".
---

# Skill: obsidian-kanban

## Cel
Pracować z tablicą zadań w Obsidianie (Obsidian **Bases**, `kanban-view`) tak, by Claude mógł ją czytać i
aktualizować: pokazać stan, założyć kartę, przesunąć ją między kolumnami, ztriażować inbox pomysłów,
podlinkować artefakty i **promować itemy z backlogu** (np. otwarte itemy z feedback-sweepu) na tablicę.

## Auto-trigger
- "co mam na kanbanie" / "pokaż tablicę" / "stan tablicy" / "co in progress"
- "dodaj zadanie" / "nowa karta" / "przesuń kartę" / "oznacz jako done"
- "ztriażuj lab" / "zrób porządek na tablicy" / "ogarnij inbox"
- "wrzuć te itemy na kanban" / promocja z backlogu/feedbacku

## Wymagania
- **MCP `obsidian`** (`mcp__obsidian__*`) do treści + **dostęp do plików vaultu** (`mv`/`bash` na lokalnej ścieżce) do przenoszenia kart. Brak `mcp__obsidian__*` → najpierw skill `obsidian-setup`.
- **Tablica = plik `.base`** z `kanban-view`. Skill **odkrywa strukturę z `.base`** — nie zakłada wcześniej kolumn. Brak `.base` w projekcie → nie zgaduj; powiedz userowi i zaproponuj utworzenie boardu (propose-first).

## Krok 0 — odczytaj board z `.base` (NIE hardcoduj kolumn)
Tablice różnią się per-projekt. Zanim cokolwiek zrobisz, przeczytaj plik `.base` i ustal:
- **folder kart** (`filters: file.folder == "…"`) i co jest wykluczone (sam plik `.base`),
- **property grupujące** (`groupByProperty`, zwykle `note.status`),
- **słownik i kolejność kolumn** (`columnOrders.<prop>`) + kolory (`columnColors`).

Przykład (Manta): `KANBAN/-Kanban Board.base` · grupa `note.status` · kolumny `Lab → To-do → In progress → To confirm → Done`.
**Karta = notatka w folderze** z property grupującym we frontmatter. Brak property → karta wpada do „Uncategorized".

## Semantyka kolumn (czytaj z configu boardu — nie zakładaj)
Każdy board ma swoje znaczenia; dla danego boardu czytaj je z notatki semantyki / `CLAUDE.md`. Wzorzec (Manta):
- **Lab** — lodówka/inbox: *do zbadania* · *przemyślenie* · *możliwy projekt* (3 różne cykle życia).
- **To-do** — backlog rzeczy do zrobienia. Tagi: `blocked` (ktoś/coś blokuje — dopisz *co* w karcie) · `high-priority`.
- **In progress** — **tylko to, nad czym realnie pracujesz.** „Zaraz zacznę" ≠ in-progress → trzymaj na **górze `To-do`** (kolejność = priorytet), żeby WIP był prawdziwy.
- **To confirm** — **coś wisi na kimś / spodziewamy się lub chcemy follow-up**: nasza część gotowa, czekamy na czyjąś decyzję/odpowiedź, feedback zespołu, wysłane pytanie lub zewnętrzną blokadę. Rozróżnienie: **`In progress` = aktywnie robimy** · **`To confirm` = zrobione co po naszej stronie, czekamy na potwierdzenie/odpowiedź z zewnątrz.** Ustawiaj **odruchowo** przy domykaniu rundy, gdy zostaje open item na kimś (nie zostawiaj takiej karty na `In progress`). Dwa wyjścia: potwierdzenie/feedback OK → `Done`; „zmień X" → wraca do `To-do`/`In progress`.
- **Done** — zrobione i **warte pamięci dla zespołu**. To kandydat do **promocji do vaultu** (`obsidian-capture`). Po domknięciu kartę **archiwizuj** (przenieś do folderu archiwum boardu) — **nie kasuj**: zachowujemy zapis tego, co zrobione.

## Operacje

### A) Digest stanu (read-only, token-safe)
Czytaj **tylko frontmatter** kart (status, tags, tytuł) — nie całe treści (oszczędność tokenów).
Zbuduj podsumowanie **per kolumna** w kolejności z `.base`. Wyróżnij:
- **In progress** (realny WIP) i **To confirm** (kolejka usera — czeka na omówienie/feedback),
- karty z tagiem `high-priority` oraz **`blocked`** (te ostatnie wypisz osobno — co je blokuje),
- **Lab** = inbox (policz ile czeka na triage), **Done** = ilu kandydatów do promocji/archiwizacji.

### B) Utwórz kartę (propose-first)
Nowa notatka w folderze tablicy, frontmatter `status: <kolumna>` (+ opcjonalne `tags`). Tytuł = nazwa pliku.
Jeśli nadajesz **nowy** status (spoza słownika) — dopisz go do `columnOrders` w `.base`, inaczej nie pojawi się w kolejności.

### C) Przesuń kartę (propose-first)
Zmień **wartość property grupującego** we frontmatter (np. `status: To-do` → `In progress`).
**Nie zmieniaj nazwy pliku** do sygnalizacji stanu — stan żyje w property (rename psuje `[[linki]]`).

### D) Triage inboxu „Lab" (3 kubełki)
Dla każdej wrzutki (często goły link) w jednej linii **co to jest** → przypisz kubełek + rekomendacja:
- *do zbadania* → akcjonowalne: **promuj do `To-do`** (z 1-liniowym „po co"),
- *przemyślenie* → referencja: **zostaw w Lab** (ewentualnie → vault, jeśli warte zapamiętania),
- *możliwy projekt* → kandydat na decyzję: **zostaw + oznacz do omówienia**, albo **odrzuć**.
Wzbogać kartę o 1-liniowy opis. Wszystko propose-first.

### E) Podlinkuj artefakty
Dodaj do karty backlinki: vault doc, plik/board Figma (URL), repo/PR. Wikilinki we frontmatter **tylko listą i w cudzysłowach** (patrz gotcha).

### F) Promuj z backlogu/feedbacku → tablica
Most między skillami: weź itemy z notatki backlogu (np. `Open items …` z feedback-sweepu) i załóż z nich karty
(`status: To-do`, tag jeśli priorytet), z backlinkiem do źródła. Propose-first; pokaż listę kart przed zapisem.

### G) Domknięcie karty „Done" → promote/archive (hook do `obsidian-capture`)
Gdy karta trafia/jest w `Done` i jest potwierdzona, zaproponuj rozstrzygnięcie (propose-first):
- **warte pamięci dla zespołu** (decyzja / spec / koncept) → **promuj do vaultu** (`obsidian-capture`) jako trwały dok we właściwym folderze, **potem zarchiwizuj kartę**;
- **pozostałe** → **zarchiwizuj kartę** od razu.

**Archiwizacja = przenieś plik karty do folderu archiwum boardu** (per-board config, np. `<folder boardu>/Archive`) — **nigdy nie kasuj do Trash ani nie usuwaj pliku**. Zasada: *archiwizuj, nie kasuj* — nie tracimy zapisu tego, co zrobione (karty Done często mają w treści cenny status realizacji).
- **Mechanizm:** board filtruje po **dokładnym** folderze (`file.folder == "<folder>"`), więc karta w podfolderze archiwum **automatycznie wypada z tablicy**, a notatka żyje. Status we frontmatter staje się wtedy martwy — ustaw go na `Done` (czytelny ślad), nie zostawiaj `Trash`.
- **⚠️ Jak przenieść — `mv` na filesystemie, NIE „write nowej ścieżki + delete starej".** MCP `obsidian` **nie ma operacji move/rename**; emulacja przez `write_note(nowa ścieżka)` + `delete_note(stara)` to dwa kroki i ryzyko **osieroconego duplikatu**, gdy destrukcyjny `delete` zostanie anulowany. Zamiast tego: najpierw ustaw `status: Done` przez MCP (`manage_frontmatter`), **potem** `mv "<vault>/<folder>/Karta.md" "<vault>/<folder>/Archive/"` — jeden atomowy ruch (Google Drive/iCloud zsynchronizuje). Mechanika dwóch kanałów: skill `obsidian-setup`.
- **Brak folderu archiwum** w configu boardu → zaproponuj jego utworzenie (propose-first), nie improwizuj.
- **Brak kolumny „Trash"** na boardzie — to relikt; domknięcie idzie do folderu archiwum, nie do kolumny.

Cel: `Done` nie puchnie, a żaden zapis nie ginie.

**Promocja `Open items` z feedback-sweepu (opcjonalna, inicjowana z kanbana — NIE automatyczna):** feedback-sweep nie tworzy żadnych kart na tablicy. Jeśli chcesz, możesz **ręcznie** wziąć leftovers z notatki `Open items …` (`type: concept-backlog`) i wypromować je na board operacją F.

## Propose-first (dyscyplina zapisu)
To wspólny vault pracy — **każdy zapis pokazuj najpierw jako propozycję**, czekaj na OK:
- tworzenie/przesuwanie kart, triage, edycja `.base` — diff/lista przed zapisem,
- przy wielu kartach naraz pokaż zbiorczą listę „co powstanie / co się przesunie".

## Karta — schemat
```
---
status: <kolumna ze słownika boardu>
tags: [high-priority]        # opcjonalnie; wikilinki we frontmatter → lista w cudzysłowach
---

<treść: 1-liniowy opis + linki do artefaktów ([[doc]], Figma URL, repo)>
```

## Gotchas
- **Odkryj kolumny z `.base`** — nie hardcoduj; boardy różnią się słownikiem (Manta: Lab/To-do/In progress/To confirm/Done).
- **Status = frontmatter, nie nazwa pliku.** Rename do sygnalizacji stanu psuje linki.
- **Nowy status musi trafić do `columnOrders`** w `.base`, inaczej kolumna nie pojawi się w kolejności.
- **Wikilinki w YAML** — `klucz: [[A]], [[B]]` to niepoprawny YAML → notatka traci property → wypada z boardu.
  Zawsze listą: `klucz:\n  - "[[A]]"`.
- **Karta bez property grupującego** → „Uncategorized". Na create zawsze ustaw status.
- **Digest stosuje filtry z `.base`** (np. `file.name != "…"`) — nie listuj folderu na ślepo, bo pokażesz wykluczone notatki jako fałszywe „Uncategorized".
- **Notatka nie-karta w folderze boardu** (np. referencyjna „jak pracuję") → **wyklucz w filtrze `.base`** (`file.name != "…"`, bez rozszerzenia), nie zostawiaj jako Uncategorized.
- **Archiwizacja przenosi plik — `mv` na filesystemie, nie REST copy+delete** (MCP nie ma move; copy+delete grozi osieroconym duplikatem — patrz sekcja archiwizacji + `obsidian-setup`). `mv` nie aktualizuje `[[backlinków]]` do karty (Obsidian robi to tylko przy move w UI). Karty Done zwykle są liśćmi (nikt do nich nie linkuje) — wtedy OK; jeśli karta jest celem linków, przenieś ją w UI Obsidiana.
- **Token-safety:** do digestu czytaj frontmatter, nie pełne treści kart.
- **Bases bywa wrażliwe** — po zmianach strukturalnych w `.base` zweryfikuj render w UI.
- **`manage_frontmatter set` na stringu potrafi zapisać nadmiarowe cudzysłowy** (`status: '"To confirm"'` zamiast `status: To confirm`) → wartość nie matchuje słownika kolumny, karta wypada z grupy. Po secie zweryfikuj (`get_note format:section` na froncie) i popraw `obsidian_replace_in_note` na czysty `status: <kolumna>` (bez cudzysłowów, jak reszta kart).

## Raport
Po operacji: co się zmieniło (utworzone/przesunięte karty, ztriażowane wrzutki), nowy rozkład kolumn,
co czeka na Twoją decyzję (kolumna „To confirm" / itemy wymagające inputu).
