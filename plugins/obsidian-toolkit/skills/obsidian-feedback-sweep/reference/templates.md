# Feedback Sweep — szablony copy-paste

## Wiersz triage (tabela rejestru)
```
| F## | Flow X · Ekran | 🎨 | Owner | Do now — <one-liner> |
```

## Blok detalu (per item)
```
### F## · <krótki tytuł>
- **Lokalizacja:** `node-id` · Flow X · Ekran · **Autor:** Imię · YYYY-MM-DD
- **Komentarz:** "<verbatim>"
- **Reakcja:** <Typ> + <Dyspozycja> — <uzasadnienie oparte na regułach projektu>
- **Owner / Consulted:** <Owner> / <consulted>
- **Status:** New → Routed → Decided → Done
- **Odpowiedź:** "<draft odpowiedzi do zgłaszającego>"
```

## Decision Ask (dla itemów Needs-decision — do wręczenia Ownerowi)
```
**Decyzja potrzebna — <temat>** (Owner: <imię>)
- Kontekst: <1–2 linie + które ID feedbacku>
- Pytanie: <pojedyncza decyzja>
- Rekomendacja: <Twój wybór + dlaczego>
- Opcje: A) … B) … C) …
- Blokuje: <co czeka na tę decyzję>
```

## Nagłówek żywego rejestru (frontmatter notatki)
```
---
type: feedback-log
status: open            # open | active | done
collected: YYYY-MM-DD
source: <plik/board + file_key>
scope: <co sweep objął — np. incremental since previous>
previous: "[[poprzedni rejestr]]"
last-swept: <ISO>       # punkt odcięcia następnego sweepu
created: YYYY-MM-DDTHH:MM
# closed: YYYY-MM-DD     # dopisz gdy status: done
---
```
