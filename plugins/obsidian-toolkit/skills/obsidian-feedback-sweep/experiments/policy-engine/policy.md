# Polityka klasyfikacji feedbacku — źródło prawdy (proza)

Ten plik jest **jedynym miejscem, w którym politykę się pisze i zmienia**. `rules.json`
jest z niego *kompilowany* — nigdy nie edytuj `rules.json` ręcznie, bo rozjedzie się
z uzasadnieniem i przy następnej kompilacji zostanie nadpisany.

Reguły są **uporządkowane w obrębie osi**: pierwsza, która pasuje, wygrywa. Kolejność
jest częścią polityki, nie szczegółem implementacji.

**Logika trójwartościowa.** Przesłanka o nieznanej wartości daje `UNKNOWN`, nie `false`.
Gdy wcześniejsza (wyżej priorytetowa) reguła jest `UNKNOWN`, silnik **nie przyjmuje**
werdyktu reguły późniejszej — bo gdyby ta wcześniejsza była prawdziwa, to ona by wygrała.
Zwraca `undetermined` i nazywa pole, które blokuje. To jest cel, nie awaria.

Wyjątek jest **jawnie deklarowany per reguła** flagą `on_unknown: "false"`: reguła-strażnik
na rzadki wyjątek (A2, B1, B2) traktuje „nie wiem" jak „nie zaszło" i przepuszcza dalej.
Prior jest wtedy zapisany w polityce, a nie ukryty w implementacji. Rozwidlenie
`do-now` / `needs-decision` — czyli miejsce, gdzie stawka jest realna — **blokuje zawsze**.

Każda reguła ma **dowód** — pozycję z historycznego rejestru, która ją ustanawia.
Reguła bez dowodu to hipoteza; nie wchodzi do `rules.json`.

---

## Oś A · Typ (czym jest input)

Kolejność: defekt bije wszystko, potem forma wypowiedzi, potem warstwa zmiany.

### A1 · Defekt → `bug`
Komentarz wskazuje, że coś w istniejącym materiale jest błędne, sprzeczne albo
niespójne — nie „chciałbym inaczej", tylko „to jest źle".
`names_defect = yes` → **bug**

### A2 · Podrzucona referencja → `inspiration`
Komentarz wskazuje zewnętrzny przykład jako wzorzec do naśladowania.
`references_external_example = yes` → **inspiration**

### A3 · Pochwała bez prośby o zmianę → `note`
`positive_valence = yes` AND `asks_change = no` → **note**

### A4 · Pytanie, które o nic nie prosi → `question`
Pytanie jest typem tylko wtedy, gdy nie niesie polecenia. Pytanie retoryczne
z wbudowaną prośbą („Is there a way to indicate X?") to prośba o zmianę, nie pytanie
— o typie decyduje wtedy warstwa (A5/A6).
`speech_act = interrogative` AND `asks_change ≠ yes` → **question**

### A5 · Zmiana w tym, co produkt robi → `product`
Scope, model danych albo proces = produkt, niezależnie od tego, jak drobno
sformułowany jest komentarz.
`change_layer ∈ {scope, data_model, process}` → **product**

### A6 · Zmiana w tym, jak to wygląda albo brzmi → `design`
`change_layer ∈ {presentation, copy}` → **design**

Nic nie pasuje → **undetermined** (wraca do człowieka; NIE zgadujemy `design` tylko
dlatego, że to najczęstsza klasa).

---

## Oś B · Dyspozycja (co dzieje się dalej)

Kolejność: adresat → własne odroczenie → cudza decyzja → determinacja → forma.

### B1 · Nie do nas → `no-action`
**To jest reguła, której nigdy nie zapisano, a rządzi korpusem.** Komentarz, który
jest wymianą między innymi osobami na naszym pliku — nikt nas nie taguje, nikt nas
nie pyta — nie jest naszą pozycją do przerobienia. Logujemy, nie odpowiadamy.
`addressed_to_us = overheard` → **no-action**

> **Dowód:** rejestr `2026-07-22 · FigJam Roadmap`, pozycje K1, K3, K4, K5 —
> „internal Dominique/Kara roadmap chat, not directed at Piotr/Tom (…) we reply only
> where a reviewer tags us". Cztery pozycje w jednym rejestrze, wszystkie merytoryczne
> pytania produktowe, wszystkie `No action` **wyłącznie z powodu adresata**.
> Ślepy klasyfikator zrouował K1/K4 do `needs-decision` — bo z samej treści to
> wyglądało na decyzję produktową. Bez tej reguły luki nie da się zamknąć.

### B3 · Odsyła do kogoś innego → `needs-decision`
Komentarz wymienia inną osobę jako decydenta, prosi o rozmowę, warsztat albo sync.
`invokes_other_party = yes` → **needs-decision**

### B4 · Proposer jest właścicielem tej warstwy → `do-now`
Gdy autor komentarza sam ma ostatnie słowo w warstwie, której komentarz dotyka, jego
zdanie **jest** decyzją, a nie prośbą o decyzję. Nie ma czego routować.
`author_owns_layer = yes` (wyprowadzone z macierzy projektu) AND `asks_change = yes` → **do-now**

> **Dowód:** rejestr `2026-08-14 · Tom` — „Tom sam się odblokował z ostatecznym słowem,
> nie jest już Needs decision. Klasyfikacja: Do now"; `2026-06-24` N1 — „proposer =
> decision-maker (product)".

### B5a · Warstwa należy do nas → `do-now`
Nie ma kogo pytać. Gdy zmiana leży w warstwie, której właścicielem jesteśmy
(`presentation`, `copy` wg macierzy), nawet nie w pełni doprecyzowana prośba jest naszą
robotą, a nie pozycją do routowania.
`layer_owned_by_us = yes` (wyprowadzone) AND `asks_change = yes` → **do-now**

> **Dowód:** ta sama grupa co B6 — 📦 nie oznacza automatycznie `needs-decision`, a
> presentation/copy tym bardziej nie. Na train zamieniło 7 błędnych `needs-decision`
> na trafienia.

### B5 · Prośba nieokreślona → `needs-decision`
Sedno rozjazdu `do-now ↔ needs-decision`. Nie chodzi o to, *czego dotyka* komentarz
(produkt vs design), tylko czy **wynika z niego dokładnie jedna wykonalna zmiana**.
„Potrzebujemy miejsca pod nazwiskiem na rok szkolny" to produkt, ale jest określone
→ `do-now`. „Ustalmy, czy dokumenty wiszą na aplikacji czy na uczniu" to też produkt,
ale wymaga najpierw wyboru → `needs-decision`.
`asks_change = yes` AND `ask_determinate = no` → **needs-decision**

### B6 · Prośba określona → `do-now`
**Warstwa nie decyduje.** Zmiana produktowa niskiego ryzyka też jest `do-now` — 📦 nie
oznacza automatycznie `needs-decision`.
`asks_change = yes` AND `ask_determinate = yes` → **do-now**

> **Dowód:** rejestry `2026-06-16`, `2026-06-24` (F4-2), `2026-07-30` — „czysta zmiana
> mock-danych, zero ryzyka, nie dotyka DS/tokenów" → Do now mimo tagu 📦. 8+ pozycji.

### B9 · Pytanie z odpowiedzią po naszej stronie → `answer-close`
`asks_change = no` AND `answer_source = design` → **answer-close**

### B10 · Pytanie o niepodjętą decyzję → `needs-decision`
`asks_change = no` AND `answer_source = product_decision` → **needs-decision**

### B7 · Pozytyw z lekcją → `delight`
`positive_valence = yes` AND `asks_change = no` AND `reusable_lesson = yes` → **delight**

### B8 · Pozytyw bez treści → `no-action`
`positive_valence = yes` AND `asks_change = no` AND `reusable_lesson = no` → **no-action**

### B2 · Sam odkłada na później → `defer`
**Ostatnia w kolejności, celowo.** Odroczenie rozstrzyga tylko wtedy, gdy nic wykonalnego
nie zostało poproszone — inaczej „a przy okazji pomyślmy kiedyś o X" kasowało całą
konkretną prośbę z tego samego komentarza.
`phase_deferral = yes` → **defer**

> **Dowód:** 5 błędów `do-now → defer` na train, gdy reguła stała na drugim miejscu;
> po przesunięciu na koniec — zero.

Nic nie pasuje → **undetermined**.

### Kolejność ostateczna (oś B)
`B1 → B3 → B4 → B5a → B5 → B6 → B7 → B8 → B9 → B10 → B2`


---

## Oś C · Owner — nie osąd, tylko odczyt z macierzy

Owner **nie jest klasyfikowany**. Wynika deterministycznie z `change_layer` przez
macierz właścicieli w pliku kontekstu projektu (`context.<projekt>.json`):

| warstwa zmiany | właściciel | dlaczego |
|---|---|---|
| `data_model` | Matt | warstwa integracji/SIS — encje przekraczające granice ekranu |
| `scope` | Tom & Will | zakres MVP i roadmapa |
| `process` | Tom & Will | reguły biznesowe i kroki przepływu |
| `presentation` | Piotr | design |
| `copy` | Piotr | design (konsultacja z Tomem przy terminologii domenowej) |

> **Dowód (Matt):** `2026-06-09` F16 — „the backing model — documents stored on the
> student so they persist — is still Matt's call"; `2026-06-24` N7/R3; `2026-07-14` F3.
> 8+ pozycji.
> **Dowód (Tom & Will):** `2026-07-22` K1 — „MVP scope + Lighthouse→MVP tracking is
> their call"; `2026-06-24` N2/N3/N6. Kilkanaście pozycji.

Warstwa nierozstrzygnięta → Owner `undetermined`. Macierz jest **danymi projektu**,
nie kanonem procesu — ten sam plik reguł na innym projekcie czyta inną macierz.
