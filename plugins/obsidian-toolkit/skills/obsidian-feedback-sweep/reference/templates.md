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

## Delight — wpis (dopisywany do żywej kolekcji)
```
### ✨ <YYYY-MM-DD> · <osoba> — <jednoliniowy tytuł>
- **Kto:** #<osoba>
- **Co się spodobało:** "<verbatim z żywego fetcha>" — lub zwięzły opis sygnału
- **Na czym:** <ekran / decyzja / element / deliverable> (`node-id` jeśli jest)
- **Dlaczego zadziałało:** <interpretacja — sedno, nie cytat>
- **Jak reużyć:** <konkretny pattern do powtórzenia>
- **Źródło:** <link Figma / "Slack #kanał" / "call"> · <YYYY-MM-DD>
```

## Delight — nagłówek żywej kolekcji (frontmatter, wieczny — bez statusu)
```
---
type: delight-log
scope: <projekt — np. "antisis — internal team">
updated: <ISO>          # ostatni dopisany wpis
created: YYYY-MM-DDTHH:MM
---
```
Uwaga: `#<osoba>` w treści + property `person:` na wpisie (jeśli rozbijasz wpisy na osobne notatki)
napędza `groupByProperty: person` w `*.base`. W jednej żywej notatce grupuj sekcjami per-osoba (`## #tom`).

## Delight — widok Bases (`Delight.base`, grupowanie per-osoba)
```yaml
filters:
  and:
    - file.hasProperty("type")
    - note.type == "delight-log"
views:
  - type: table
    name: Delight
    groupByProperty: person
    order: [person, "Co się spodobało", "Jak reużyć", updated]
```
(Gdy trzymasz wszystko w jednej notatce zamiast wpis-per-plik: pomiń `.base`, grupuj nagłówkami `## #osoba`
w samej notatce — profile i tak się czytają. `.base` opłaca się dopiero przy wpisach jako osobne pliki.)
