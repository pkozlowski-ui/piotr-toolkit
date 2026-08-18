---
id: ux-copy-001
skill: ux-copy
źródło: MAN-809 (KIPP National, 2026-08-06/07 — "colour"/"judgements" złapane w prototypie na dwóch rundach feedbacku)
status: aktywny (eval Δ +0.50 zmierzone 2026-08-18; criteria poprawione po fałszywych FAIL-ach; held-out gate nadal otwarty)
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

### 2026-08-18 — ablacja `with-without`: **Δ +0.50**, i trzy fałszywe FAIL-e w arm `with`

- **Komenda:** j.w. z `--ablation with-without`. Wynik: `with 0.50 · without 0.00 · Δ +0.50`,
  4 runy, 332s, $1.00.
- **Wkład skilla zmierzony i duży.** Arm `without` przegrał **6/6 głosami** — bazowy model nie tylko
  mirroruje pisownię z promptu, on **jawnie deklaruje en-GB** („skoro używasz *personalise /
  organise / colour*, trzymam en-GB"). To znaczy, że klasa błędu z MAN-809 jest realna i
  reprodukowalna, a reguła §1/1 jest nośna, nie ozdobna.
- **Ale arm `with` dał 0.50 — i to był błąd GRADERA, nie skilla.** Odczytane z outputów obu runów:
  **wszystkie** stringi interfejsowe były amerykańskie (`Customize view`, `Configure view`, `color`,
  `Retry save`) — zero brytyjskiej formy. FAIL-e (3 głosy z 6) padły za zdanie „piszę US; jeśli
  klient jest UK-based, powiedz i przerzucę całość", które sędzia przeczytał jako *pytanie
  UK-vs-US*. Tymczasem to zachowanie **wymagane** przez `SKILL.md` (§1 rule 1: przy kliencie
  UK-based mówisz o tym na głos).
- **Poprawka (2026-08-18):** `graders/criteria.md` przepisane — definiuje, co jest *stringiem
  interfejsowym* (a co prozą i cytatem z promptu), i zawęża klauzulę FAIL do sytuacji, w której
  odpowiedź **wstrzymuje copy** czekając na odpowiedź UK/US. Rozstrzygające pytanie: czy stringi
  już są w odpowiedzi. **SKILL.md nietknięty — nie rozluźniaj skilla pod graderem, który mierzył
  nie to, co trzeba.**
- **Świadomie BEZ darmowego gradera `regex`** na brytyjskie formy: odpowiedź zgodnie z prawdą
  **cytuje** `personalise / organise / colour` z promptu, żeby nazwać flip — regex na trace albo
  na `last_message` karałby ją za poprawne zachowanie (dokładnie wpadka case 009 obsidian-kanban).
- **Stan po poprawce:** `with` niezmierzone na nowym kryterium — re-run jest warunkiem, żeby
  cokolwiek deklarować. Δ +0.50 zostaje jako zmierzony fakt o wkładzie skilla.

