---
name: session-retro
description: Retrospektywa sesji — podsumowanie co zrobiono, aktualizacja memory projektu, wyłapanie cross-project lessons learned. Uruchamia się gdy użytkownik mówi "zakończ sesję", "kończymy", "tyle na dziś".
---

# Skill: session-retro

## Cel
Na koniec sesji: zapisać to co warto zapamiętać do memory, wyłapać cross-project lessons,
zasugerować commit jeśli są zmiany. Nie pozwolić żeby wiedza z sesji przepadła.

## Auto-trigger
Uruchamia się gdy użytkownik mówi:
- "zakończ sesję" / "kończymy" / "tyle na dziś"
- "skończmy" / "kończę na dziś" / "koniec"
- "zrób retro" / "podsumuj sesję"

## Protokół (5 kroków)

Jesteś wykonawcą doktryny pamięci — schemat wpisu, typy i reguła promocji są w `memory-discipline`.
Zastosuj je tutaj; nie wymyślaj własnego formatu.

### 1 — Podsumuj sesję
2–4 zdania: co zrobiono, co zostało otwarte. Bez lania wody.

### 2 — Wyłap kandydatów do zapamiętania
Przejrzyj sesję pod kątem wiedzy, która przepadnie jeśli jej nie zapiszesz: nowe konwencje,
gotchy, decyzje „dlaczego tak", preferencje usera, nieoczywiste ścieżki/URL-e. Pomiń to, co repo
już zapisuje (struktura kodu, historia git, treść CLAUDE.md).

### 3 — Promuj każdy kandydat do WŁAŚCIWEJ warstwy (reguła promocji z `memory-discipline`)
- **stabilna reguła / konwencja projektu** → `CLAUDE.md` projektu
- **decyzja „dlaczego tak"** → nowy ADR w `docs/decisions/` (jeśli projekt go ma)
- **cross-project lesson / preferencja / dane wrażliwe** → warstwa 3 (prywatny `claude-memory`)
- **ulotny kontekst projektu** → `.claude/memory/` (wpis wg schematu `metadata.type`, linia w `MEMORY.md`)

Aktualizuj istniejący wpis zamiast tworzyć duplikat; usuń wpis, który okazał się błędny.

### 4 — Zaproponuj commit
Jeśli są zmiany w repo (`git status`) — pokaż skrót i **zaproponuj** commit (nie commituj sam, chyba że
user prosił). Pamięć w `.claude/memory/` i ADR-y też idą do commita (są git-trwałe).

### 5 — Krótki raport
Wypunktuj: co zapisano i gdzie (warstwa), co zaproponowano do commita, co zostaje otwarte na następną sesję.
