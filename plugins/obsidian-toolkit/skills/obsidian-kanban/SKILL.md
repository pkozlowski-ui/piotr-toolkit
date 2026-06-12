---
name: obsidian-kanban
description: Obsługa tablicy zadań w Obsidianie (Bases kanban-view) — digest stanu, tworzenie/przesuwanie kart, triage inboxu, promocja itemów z backlogu na tablicę. Uruchamia się gdy user mówi "co mam na kanbanie", "pokaż tablicę", "dodaj zadanie", "przesuń kartę", "ztriażuj lab", "zrób porządek na tablicy", "kanban".
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
- **MCP `obsidian`** (`mcp__obsidian__*`) lub dostęp do plików vaultu.
- **Tablica = plik `.base`** z `kanban-view`. Skill **odkrywa strukturę z `.base`** — nie zakłada wcześniej kolumn.

## Krok 0 — odczytaj board z `.base` (NIE hardcoduj kolumn)
Tablice różnią się per-projekt. Zanim cokolwiek zrobisz, przeczytaj plik `.base` i ustal:
- **folder kart** (`filters: file.folder == "…"`) i co jest wykluczone (sam plik `.base`),
- **property grupujące** (`groupByProperty`, zwykle `note.status`),
- **słownik i kolejność kolumn** (`columnOrders.<prop>`) + kolory (`columnColors`).

Przykład (Manta): `KANBAN/-Kanban Board.base` · grupa `note.status` · kolumny `Lab → To-do → In progress → To confirm → Done`.
**Karta = notatka w folderze** z property grupującym we frontmatter. Brak property → karta wpada do „Uncategorized".

## Operacje

### A) Digest stanu (read-only, token-safe)
Czytaj **tylko frontmatter** kart (status, tags, tytuł) — nie całe treści (oszczędność tokenów).
Zbuduj podsumowanie **per kolumna** w kolejności z `.base`. Wyróżnij:
- **In progress** (nad czym aktywnie pracujesz) i **To confirm** (czeka na decyzję usera — to Twoja kolejka do akcji),
- karty z tagiem priorytetu (np. `high-priority`),
- **Lab** = inbox pomysłów/linków (kandydaci do triage), policz ile czeka.

### B) Utwórz kartę (propose-first)
Nowa notatka w folderze tablicy, frontmatter `status: <kolumna>` (+ opcjonalne `tags`). Tytuł = nazwa pliku.
Jeśli nadajesz **nowy** status (spoza słownika) — dopisz go do `columnOrders` w `.base`, inaczej nie pojawi się w kolejności.

### C) Przesuń kartę (propose-first)
Zmień **wartość property grupującego** we frontmatter (np. `status: To-do` → `In progress`).
**Nie zmieniaj nazwy pliku** do sygnalizacji stanu — stan żyje w property (rename psuje `[[linki]]`).

### D) Triage inboxu (kolumna „Lab"/idea-dump)
Dla każdej wrzutki (często goły link): w jednej linii **co to jest i czy warto** → rekomendacja:
`promuj do To-do` / `zostaw w Lab` / `odrzuć`. Wzbogać kartę o 1-liniowy opis. Wszystko propose-first.

### E) Podlinkuj artefakty
Dodaj do karty backlinki: vault doc, plik/board Figma (URL), repo/PR. Wikilinki we frontmatter **tylko listą i w cudzysłowach** (patrz gotcha).

### F) Promuj z backlogu/feedbacku → tablica
Most między skillami: weź itemy z notatki backlogu (np. `Open items …` z feedback-sweepu) i załóż z nich karty
(`status: To-do`, tag jeśli priorytet), z backlinkiem do źródła. Propose-first; pokaż listę kart przed zapisem.

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
- **Token-safety:** do digestu czytaj frontmatter, nie pełne treści kart.
- **Bases bywa wrażliwe** — po zmianach strukturalnych w `.base` zweryfikuj render w UI.

## Raport
Po operacji: co się zmieniło (utworzone/przesunięte karty, ztriażowane wrzutki), nowy rozkład kolumn,
co czeka na Twoją decyzję (kolumna „To confirm" / itemy wymagające inputu).
