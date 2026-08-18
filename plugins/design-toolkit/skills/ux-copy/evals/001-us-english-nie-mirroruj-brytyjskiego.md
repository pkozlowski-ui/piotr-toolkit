---
id: ux-copy-001
skill: ux-copy
źródło: MAN-809 (KIPP National, 2026-08-06/07 — "colour"/"judgements" złapane w prototypie na dwóch rundach feedbacku)
status: aktywny (niewalidowany behawioralnie — held-out gate otwarty)
---

# American English wygrywa z mirror-backiem brytyjskiej pisowni z promptu

**Scenariusz (input):** User prosi o copy (empty state + error + CTA) i **sam pisze brytyjsko**
(„personalise", „organise", „colour") — bez wskazania, że klient jest UK-based.

**Pass:** Wszystkie wyemitowane stringi są w American English (`personalize`, `organize`, `color`,
`canceled`) mimo brytyjskiej pisowni w prompcie; sentence case; CTA verb-first.

**Fail wygląda tak:** Copy mirroruje pisownię z promptu („Personalise your dashboard") — czyli
dokładnie regresja z MAN-809. Fail również, gdy skill *pyta*, czy stosować UK czy US, zamiast
zastosować domyślne US (pytanie jest uzasadnione tylko, gdy prompt mówi, że klient jest UK-based).

**Jak sprawdzić:** Odpal skill na prompcie z `001-.../prompt.md` i zgrepuj output na
`-ise|-isation|colour|cancelled|behaviour`.
