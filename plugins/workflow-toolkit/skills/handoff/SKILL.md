---
name: handoff
description: Kompaktuje bieżącą rozmowę do dokumentu handoff dla świeżego agenta. Uruchamia się gdy user mówi "handoff", "zrób handoff", "kompaktuj kontekst", "przekaż kontekst", lub gdy kontekst sesji jest kompresowany.
argument-hint: "Na czym skupi się następna sesja?"
---

# Skill: handoff

## Cel

Stworzyć krótki dokument briefingowy w temp OS, który świeży agent może wczytać żeby natychmiast podjąć pracę — bez potrzeby rekonstruowania kontekstu z historii rozmowy.

Różnica od `session-retro`: handoff nie aktualizuje memory, nie commituje, nie robi retro. To jednorazowy transfer kontekstu do nowego agenta.

## Auto-trigger

Uruchamia się gdy:
- User mówi "handoff" / "zrób handoff" / "kompaktuj kontekst" / "przekaż kontekst"
- Widoczny jest system message o kompresji kontekstu sesji
- User pyta jak kontynuować pracę w nowej sesji

## Protokół (5 kroków)

### Krok 1 — Stan bieżącego zadania

Zbierz z przebiegu rozmowy:
- **Co zostało ukończone** w tej sesji (konkretnie — pliki, funkcje, decyzje)
- **Co jest w toku** — ostatni krok który nie został dokończony
- **Co blokuje** — błędy, pytania bez odpowiedzi, zależności

Jeśli user podał argument do skilla → użyj go jako focus scope (np. "kontynuuj implementację X") i dostosuj dokument pod ten scope.

### Krok 2 — Referencje

Zbierz wskaźniki do istniejących artefaktów (ścieżki plików, URL PR, linie kodu).
**Nie duplikuj treści** — tylko odsyłaj.

Przykłady:
- Pliki zmienione: `src/app/apply/guardian/page.tsx`
- Otwarte PR: `gh pr list` jeśli nie wiesz
- Plan mode file jeśli był użyty: `~/.claude/plans/*.md`
- Memory projektu: `.claude/memory/MEMORY.md` (w repo; lokalny katalog Claude Code to symlink — patrz `memory-discipline`)

### Krok 3 — Suggested skills dla następnej sesji

Na podstawie tego co jest w toku, zaproponuj które skille powinien załadować świeży agent:

Dostępne w workflow-toolkit:
- `workflow-toolkit:session-retro` — jeśli następna sesja będzie ostatnią
- `workflow-toolkit:browser-verify` — jeśli są zmiany UI do weryfikacji
- `workflow-toolkit:design-system-lookup` — jeśli będą nowe komponenty
- `workflow-toolkit:coding-principles` — jeśli następna sesja to coding

Inne skille (jeśli dotyczy):
- `figma-design-toolkit:figma-design-workflow` — jeśli jest praca z Figmą
- `figma-design-toolkit:figma-console` — jeśli figma_execute
- `vercel:deploy` — jeśli jest deployment

### Krok 4 — Zapisz plik handoff

Zapisz do temp OS:
```
$TMPDIR/claude-handoff-<YYYYMMDD-HHMMSS>.md
```
(Fallback: `/tmp/claude-handoff-<timestamp>.md`)

Format dokumentu:
```markdown
# Handoff — <data i godzina>

## Projekt
<nazwa projektu, ścieżka, krótki kontekst>

## Stan zadania
### Ukończone
- ...

### W toku
- ...

### Blokery / otwarte pytania
- ...

## Referencje
- Pliki: ...
- PR: ...
- Memory: ~/.claude/projects/.../memory/MEMORY.md

## Suggested skills dla następnej sesji
- workflow-toolkit:X
- ...

## Scope następnej sesji
<jeśli user podał argument — tu wpisz; jeśli nie — "kontynuacja bieżącego zadania">
```

### Krok 5 — Poinformuj użytkownika

Podaj:
1. Pełną ścieżkę do pliku handoff
2. Jak go użyć: "W nowej sesji powiedz: 'Wczytaj kontekst z `<ścieżka>`'"

## Zasady

- **Nie aktualizuj memory.** To jest zadanie `session-retro`, nie `handoff`.
- **Nie commituj.** Handoff nie dotyka gita.
- **Redaguj dane wrażliwe** — tokeny, klucze API, dane osobowe nie trafiają do pliku.
- **Bądź konkretny.** Plik ma być przeczytany przez model, nie człowieka — nie ozdabiaj, pisz precyzyjnie.
- **Scope argument ma priorytet.** Jeśli user napisał `/handoff kontynuuj X` → cały dokument zorientuj na X, pomiń niezwiązane zadania.
