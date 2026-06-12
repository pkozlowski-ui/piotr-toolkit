# obsidian-capture — szablony per kategoria

Routing **by-temat** (folder tematu w vaulcie), typ w `type`. Wikilinki we frontmatter → lista w cudzysłowach.

## Decyzja (ADR-lite)
```
---
type: decision
created: YYYY-MM-DD
status: accepted        # proposed | accepted | superseded
source:
  - "[[karta/rejestr źródłowy]]"
deciders: <kto>
---

# Decyzja: <rzeczowy tytuł>

**Kontekst.** <problem, co skłoniło do decyzji>
**Decyzja.** <co zdecydowano>
**Dlaczego.** <uzasadnienie>
**Odrzucone opcje.** A) … (dlaczego nie) · B) …
**Konsekwencje.** <co z tego wynika, na co uważać>
```

## Spec / wymagania
```
---
type: spec
created: YYYY-MM-DD
status: draft
source: <Figma URL / karta>
---

# <Feature> — spec

**Cel / problem.** … **Zakres (in/out).** … **User stories.** …
**Wymagania.** … **Otwarte pytania.** … **Powiązania.** [[…]]
```

## Synteza researchu
```
---
type: research
created: YYYY-MM-DD
source: <skąd dane>
---

# <Temat> — synteza

**Pytanie.** … **Kluczowe wnioski** (3–5). … **Implikacje dla produktu/designu.** …
**Źródła.** …
```

## Notatki ze spotkania
```
---
type: meeting
created: YYYY-MM-DD
attendees: [..]
---

# <Spotkanie> — YYYY-MM-DD

**Ustalenia / decyzje.** … **Action items.** - [ ] <kto> — <co> — <do kiedy>
**Otwarte.** … **Powiązania.** [[…]]
```
