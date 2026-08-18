---
id: ux-copy-001
skill: ux-copy
źródło: MAN-809 (KIPP National, 2026-08-06/07 — "colour"/"judgements" złapane w prototypie na dwóch rundach feedbacku)
status: aktywny (eval PASS 2/2 — 2026-08-18; held-out gate nadal otwarty)
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

## Werdykty

### 2026-08-18 — pierwszy przebieg, `score 1.00` (2 runy)

- **Komenda:** `claude plugin eval design-toolkit@pkozlowski-ui-marketplace --case '001-us-english*'
  --runs 2 --ablation none --threshold 0.8 --no-publish --judge-model sonnet --max-cost-usd 3`
- **Wynik:** `criteria` PASS PASS PASS w obu runach, `skill-loaded` 1× w obu. `1 case · 217s · $0.75`.
- **Co to dowodzi:** że skill **załadował się** na prośbie o copy (trigger fidelity na tym jednym
  scenariuszu) i że reguła US-English wygrała z brytyjską pisownią w prompcie. Warunek konieczny.
- **Czego to NIE dowodzi:** przebieg poszedł z `--ablation none`, więc **nie zmierzono wkładu
  skilla** — nie wiadomo, czy sam model bez `ux-copy` też by nie zmirrorował. To jest specyfikacja
  napisana z tej samej wpadki (MAN-809), więc przechodzi z definicji; held-out na realnych sesjach
  (H6 w `hipotezy-otwarte.md`) zostaje otwarty.

