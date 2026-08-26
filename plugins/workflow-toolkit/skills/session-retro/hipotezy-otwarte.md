# Hipotezy otwarte — rejestr zmian czekających na held-out

> Zmiana, która przeszła przez retro, ale **nie ma za sobą pełnego gate'a** (`held-out-gate.md`),
> jest HIPOTEZĄ, nie kanonem. Bez rejestru taka hipoteza cicho awansuje na regułę — nikt do niej nie
> wraca, bo w `SKILL.md` wygląda jak wszystko inne. Ten plik jest **wywoływaczem**: retro czyta go
> w kroku 4b i odpala gate dla każdej pozycji, której urósł materiał.
>
> Wpis usuwasz dopiero wtedy, gdy werdykt jest zapisany z liczbą i nazwaną soczewką — także werdykt
> negatywny („odrzucone") i „za mało danych" po raz drugi (wtedy przenieś datę odcięcia, nie kasuj).

## Jak to czytać

- **Warunek wznowienia** — co musi urosnąć, żeby gate w ogóle miał co mierzyć. Zwykle liczba
  przypadków OCENIANYCH (nie wywołań — `held-out-gate.md`, „licznik wywołań to górna granica").
- **Komenda** — dokładnie to, co odpalasz, żeby sprawdzić, czy warunek już spełniony.
- Warunek niespełniony → nie ma roboty, idź dalej. Kosztuje jedno odpalenie skryptu na retro.

---

## Otwarte

### H1 — `linear-ticket-draft` R3: rozmieszczenie linków wg ICH LICZBY

- **Co jest hipotezą:** > 1 link → wariant A (link per ekran, brak sekcji `**Links**`);
  dokładnie 1 link → wariant B (bullety bez linków, jeden link zbiorczy w `**Links**`).
- **Data zmiany:** 2026-08-13 (`workflow-toolkit` 1.25.0, commit `33ded25`).
- **Przebieg 2026-08-25:** surowe okno urosło do **7 wywołań** (z 3). Nowe od 2026-08-24: `2026-08-24T09:12`, `2026-08-24T11:27`, `2026-08-24T12:08`, `2026-08-25T09:38`, `2026-08-25T12:03`. Nieklasyfikowane — **wariant B (dokładnie 1 link) nadal 0 ocenianych**, więc gate stoi na tej samej przyczynie co poprzednio.
- **Przebieg 2026-08-25 (sesja sales-demo, antisis-prototype):** `heldout_split.sh
  workflow-toolkit:linear-ticket-draft 2026-08-13` → surowy held-out **7 wywołań** (≥3). Ręczny
  przegląd per wymaganie **odłożony po raz DRUGI** — retro szło w sesji na ~297k kontekstu, a
  przejrzenie 7 transkryptów kosztowało więcej niż wart był werdykt; sesja w ogóle nie dotykała
  `linear-ticket-draft`. ⚠️ **Następne retro robi ten przegląd JAKO PIERWSZY**, zanim weźmie
  cokolwiek innego — albo zamyka hipotezę werdyktem „za mało ocenianych, odcięcie przesunięte".
  Surowy held-out nie urośnie od czekania, a trzecie odłożenie znaczy, że rejestr przestał działać.
  Ten sam przebieg: **H2** (`design-tweaker` 2026-08-17) → held-out **0 wywołań**, warunek
  niespełniony, nic nie mierzono. **H3** (`linear-ticket-draft` 2026-08-17) → **6 wywołań**, ta
  sama blokada co H1 (brak ręcznego przeglądu).
- **Stan gate'a:** `held-out C: 3 wywołania po zmianie, 2 realnie oceniane, za mało danych na
  wariant B` (przebieg 2026-08-24, held-out okno 2026-08-13→2026-08-24). Rozbite per branch:
  - **Wariant A (>1 link) — POTWIERDZONY, 2/2:**
    - `2026-08-17T13:29:07Z`, MAN-848 (`7fcefd03-…jsonl`) — draft z 2 linkami Figma, **jeden per
      bullet** (F02 closed/single-window + multi-window), **brak sekcji `**Links**`**. Model sam
      nazwał to „wariant A" w tekście przed draftem — obie sub-reguły MET.
    - `2026-08-13T11:49:18Z`, MAN-825/„10-1 toggle update" (`a50d37d0-…jsonl`, Edit na karcie kanban,
      nie w treści czatu) — draft z 2 URL (F&A `antisis-prototype.vercel.app/schools`,
      Staff `mvp-staff-experience.vercel.app`), każdy przypięty do własnego akapitu/produktu, brak
      sekcji `**Links**` — MET. (Nuans: URL-e są gołym tekstem, nie markdown-linkiem — inna oś, nie
      dotyczy rozmieszczenia.)
  - **Wariant B (=1 link) — NIE PRZETESTOWANY, 0/1 właściwych przypadków:**
    - `2026-08-24T09:12:54Z`, MAN-896 (`adf0d2ba-…jsonl`, linia 1363) — 1 link (demo URL), ale draft
      to jednoakapitowe ogłoszenie jednego demo, **nie lista wielu ekranów/itemów** — nie ma bulletów
      w ogóle i nie ma sekcji `**Links**`, link leci inline blisko początku, nie „zbiorczo na końcu".
      Werdykt: **nie dotyczy** — precondycja hipotezy (lista itemów, z których trzeba by rozproszyć
      albo skonsolidować linki) nie zachodzi, więc mechanika wariantu B nie miała szansy się odpalić.
      Poprzednia sesja (retro 2026-08-24) osądziła to jako „zgodne z wariantem B" licząc tylko
      liczbę linków (=1) — ten osąd był policzeniem, nie soczewką C per-wymaganie; skorygowane tutaj.
- **Przebieg 2026-08-26 (retro sesji sales-demo, CZWARTY) — klasyfikacja WYKONANA, delegowana do
  subagenta zamiast po raz czwarty odłożona.** Przejrzane wszystkie 5 draftów z okna. **Ocenianych
  wariantu B: 0/3** → werdykt `ZA MAŁO OCENIANYCH`, ale **z inną przyczyną niż przez trzy poprzednie
  przebiegi**: to nie jest zaległość wykonawcza. Każdy realny case z DOKŁADNIE 1 linkiem wychodzi
  jako **jednoakapitowa odpowiedź, nie lista itemów w bulletach** (`MAN-896` — ogłoszenie reskinu,
  zero bulletów; `MAN-595` — krótka odpowiedź na komentarz Toma, zero bulletów), więc precondycja
  wariantu B **strukturalnie się nie odpala w realnym ruchu**. Dwa dalsze wywołania nie wyprodukowały
  draftu w ogóle (jeden świadomie wstrzymany, jeden zjechał w infra). Wariant A dostał **trzecie**
  potwierdzenie (ticket Family Portal, 3 linki, 3 bullety, brak sekcji `**Links**`).
  ⚠️ **Otwarte pytanie procesowe, nie kolejne odłożenie:** czy warunek wznowienia jest osiągalny.
  Jeśli „1 link + wiele itemów" nie występuje w tym mixie zadań, wariant B jest regułą bez populacji
  i należy go **usunąć ze skilla**, a nie czekać na materiał. Do decyzji Piotra.
- **Soczewka:** C (zmiana treści) — oceniaj per wymaganie na draftach, NIE per wywołanie.
- **Warunek wznowienia:** ≥ 3 przypadki OCENIANE **wariantu B specyficznie** — draft z dokładnie
  1 linkiem, opisujący WIELE itemów/ekranów w bulletach (nie jednoakapitowe ogłoszenie), żeby
  hipoteza „bullety bez linków + jeden link zbiorczy w `**Links**`" miała czego dotyczyć. Wariant A
  ma już wystarczający dowód (2/2 czyste przypadki) — nie szukaj więcej materiału na niego, chyba że
  trafi się kontrprzykład.
- **Komenda:**
  ```bash
  plugins/workflow-toolkit/skills/usage-audit/scripts/heldout_split.sh \
    workflow-toolkit:linear-ticket-draft 2026-08-13
  ```
- **Gdzie zapisać werdykt:** karta `KANBAN/Archive/Held-out gate — pierwszy realny przebieg na
  linear-ticket-draft.md` (sekcja kolejnego przebiegu) + zdjęcie adnotacji „HIPOTEZA" z `SKILL.md`.

---

### H2 — `design-tweaker` description: trigger na pytania meta/routingowe o WŁASNE granice

- **Co jest hipotezą:** dopisana fraza „who executes this / which skill owns X" w `description`,
  żeby pytania o routing/handoff (nie tylko „audit this") ładowały skill.
- **Data zmiany:** 2026-08-17 (`design-toolkit` 1.4.2, commit `860f5bf`).
- **Przebieg 2026-08-25:** held-out **0 wywołań** — warunek wznowienia niespełniony, nic nie mierzono.
- **Stan gate'a:** eval case 001 przeszedł 0.00→1.00 (dowód że fix DZIAŁA na tym scenariuszu),
  ale to konieczne, nie wystarczające — held-out na realnych sesjach nieodpalony (zero czasu
  od zmiany).
- **Soczewka:** trigger fidelity — oceniaj per realna sesja z pytaniem routingowym, nie per
  eval-run.
- **Warunek wznowienia:** ≥ 3 przypadki OCENIANE, czyli realne sesje z pytaniem meta/routingowym
  o `design-tweaker` po dacie zmiany.
- **Komenda:**
  ```bash
  plugins/workflow-toolkit/skills/usage-audit/scripts/heldout_split.sh \
    design-toolkit:design-tweaker 2026-08-17
  ```
- **Gdzie zapisać werdykt:** karta „Evale jako brama — dokoncz pozostale 10 plikow prozy" (Archive)
  albo nowa karta, + zdjęcie tej pozycji stąd.

### H3 — `linear-ticket-draft`: nigdy nie zaprasza do wysyłki (rule 1 przepisana)

- **Co jest hipotezą:** reguła „milkniesz, nie zapraszasz formułą oczekiwania" zamiast „czekasz
  na wyraźne «wyślij»" — usuwa lukę, w której model dosłownie pisał „Powiedz «wyślij»"/„czekam
  na «wyślij»".
- **Data zmiany:** 2026-08-17 (`workflow-toolkit` 1.31.4, commit `7344c77`).
- **Przebieg 2026-08-25:** surowe okno **6 wywołań** (≥3), klasyfikacja „nie dotyczy"/dev-set-source nierobiona — wciąż `za mało OCENIANYCH danych`, nie „za mało wywołań".
- **Stan gate'a:** eval case 001 przeszedł 0.80→0.90, rdzeń problemu (dosłowny zakazany wzorzec)
  zniknął w OBU runach re-runu — ale to jest ta sama, konieczna-nie-wystarczająca sytuacja co H2.
  **Uwaga:** resztkowy pojedynczy flake w re-runie (inna, węższa fraza „powiedz X, przepiszę
  sekcję" — niedotycząca wysyłki) potraktowany jako szum; jeśli held-out pokaże, że to się
  powtarza w realnych sesjach, może to być osobny, węższy finding, nie dowód że fix nie działa.
- **Przebieg 2026-08-26 (retro sesji sales-demo) — GATE PRZESZEDŁ, HIPOTEZA ODRZUCONA.**
  Warunek wznowienia spełniony: **4 oceniane** drafty po 2026-08-17 (`MAN-848`, `MAN-896`,
  ticket Family Portal, `MAN-595`). **SPEŁNIONE 2 · ZŁAMANE 2.** Dwa realne drafty emitują
  dokładnie ten wzorzec, który fix miał usunąć: `MAN-896` → „powiedz «wyślij» i doprecyzuj czy
  jako komentarz czy description"; `MAN-595` → „REKO: potwierdź słowem «wyślij»" (po tym, jak
  classifier zablokował próbę usera). Borderline w `MAN-848`: sam draft czysty, ale retro tej
  samej sesji pisze „karta … czeka na Twoje «wyślij»" — opisowe, nie imperatywne, policzone jako
  spełnione. Żaden case nie jest dev-setem (fix `7344c77` wszedł 2026-08-17, wszystkie wywołania
  późniejsze; `MAN-848` tego samego dnia, ale po zmianie).
  **Werdykt: `ODRZUCONA` — reguła NIE awansuje na kanon.** Eval case 001 (0.80→0.90) był konieczny,
  nie wystarczający: w realnych sesjach compliance ≈ **50%**, nie 100%. Wpadka zmaterializowana
  jako `evals/004-nigdy-nie-zapraszaj-do-wyslania.md` (rationale) — do przepisania na case CLI
  razem z realną poprawką reguły. **Adnotacji „HIPOTEZA" z `SKILL.md` NIE zdejmować.**
- **Soczewka:** doctrine-compliance — oceniaj per realny draft wysłany do Lineara/Figmy po dacie
  zmiany, sprawdzając czy PADA jakakolwiek formuła zaproszenia do wysyłki.
- **Warunek wznowienia:** ≥ 3 przypadki OCENIANE, czyli realne drafty `linear-ticket-draft` po
  dacie zmiany.
- **Komenda:**
  ```bash
  plugins/workflow-toolkit/skills/usage-audit/scripts/heldout_split.sh \
    workflow-toolkit:linear-ticket-draft 2026-08-17
  ```
- **Gdzie zapisać werdykt:** j.w. + zdjęcie tej pozycji stąd.

---

### Przebieg 2026-08-25 (retro sesji clever-ellis, TRZECI tego dnia) — wszystkie trzy odpalone, ZERO ruchu

Odpalone `heldout_split.sh` dla H1, H2 i H3. **Żadna nie drgnęła, bo ta sesja nie wywołała ani
`linear-ticket-draft`, ani `design-tweaker`** — pracowała w kodzie (`Antisis/antisis-prototype`,
poz. 4 registeru sales-demo: trasa `/reset` czyszcząca stan fabuły w `localStorage`).

| Hipoteza | Surowy held-out | Zmiana od 2. przebiegu | Co realnie blokuje |
|---|---|---|---|
| H1 | 7 wywołań (≥3) | brak | ręczna klasyfikacja per wymaganie na 7 draftach |
| H2 | 0 wywołań | brak | brak realnych sesji z pytaniem routingowym |
| H3 | 6 wywołań (≥3) | brak | ręczna klasyfikacja per wymaganie na 6 draftach |

**Wniosek procesowy, nie kolejna hipoteza:** H1 i H3 mają dość WYWOŁAŃ już od drugiego przebiegu i
stoją na tym samym kroku — **ręcznej klasyfikacji, której retro nie zrobi „po drodze"**. Trzeci
przebieg pod rząd raportujący „za mało OCENIANYCH danych" przy wystarczającej liczbie wywołań nie
mierzy już hipotezy; mierzy to, że nikt nie otworzył okna na ocenę. **Następne retro: albo zrób tę
ocenę (≈7+6 draftów, jedno okno), albo przenieś datę odcięcia i zapisz WPROST, że to zaległość
wykonawcza, nie brak materiału** — inaczej rejestr zamienia się w licznik odłożeń.

**Nowych hipotez z tej sesji: ZERO.** Jedyna dodana soczewka (`eval/scope-selftest.mjs` w
`antisis-prototype`, asercja podziału kluczy `localStorage` na story vs settings) ma pełny
break-restore — trzy celowe defekty, każdy złapany (2/1/3 FAIL), po przywróceniu `all cases
passed` — więc jest kanonem od razu, nie hipotezą. To ta granica: soczewka z break-restore nie
trafia do tego rejestru, reguła bez obiektywnego checku trafia.

**Gotcha zmierzona po drodze, warta zapisania tutaj, bo dotyczy TEGO pliku:** skille żyją w
`~/.claude/plugins/cache/<marketplace>/<plugin>/<wersja>/` jako **KOPIA, nie symlink** do
`piotr-toolkit`, i ta kopia bywa STARSZA niż repo (tu: cache 1.32.0 miał 145 linii, repo 223).
Edycja `hipotezy-otwarte.md` w cache'u jest więc podwójnie bezwartościowa — przepada przy
aktualizacji pluginu i nadpisuje starszy stan. **Rejestr edytuj ZAWSZE w `piotr-toolkit`**, nawet
gdy skill został wczytany z cache'u.


### H7 — `session-retro` krok 4a: miesięczny sweep trafności decyzji

- **Co jest hipotezą:** osobny krok w retro (odpalany tylko co ~30 dni, nie co sesję), który
  przegląda wpisy `project`/`feedback` starsze niż 30 dni i sprawdza, czy zapisana decyzja faktycznie
  się sprawdziła — domyka lukę, której held-out gate nie pokrywa (ten ocenia trafność reguł/skilli,
  nie efekt konkretnej decyzji z przeszłości). Rozszerzone o: (a) pole `metadata.status`
  (fakt/hipoteza/założenie/decyzja) w `memory-discipline`, żeby sweep nie musiał zgadywać pewności
  wpisu; (b) linię **Korekta:** dopisywaną do wpisu ocenionego jako nietrafny — domyka pętlę
  decyzja→wynik→ocena→korekta zamiast kończyć na samej ocenie.
- **Data zmiany:** 2026-08-26 (`workflow-toolkit`, `SKILL.md` krok 4a + rozszerzenie tego samego dnia
  — REKO na pytania usera inspirowane cudzymi setupami archiwizacji sesji do Obsidiana).
- **Stan gate'a:** `0 przebiegów` — mechanizm dopiero wdrożony, `_decision-sweep-log.md` jeszcze
  nie istnieje.
- **Soczewka:** per przebieg sweepu — czy realnie złapał choć jedną nietrafną/porzuconą decyzję
  (nie tylko potwierdził wszystko jako aktualne, co byłoby rytualne i nic nie dowodzi).
- **Ryzyko odwrotne, którego trzeba pilnować:** sweep staje się rytuałem „wszystko potwierdzone" bez
  realnej weryfikacji dowodu — wtedy koszt (czas na retro) rośnie bez korzyści.
- **Warunek wznowienia:** ≥ 3 przebiegi sweepu wykonane (wpisy w `_decision-sweep-log.md`), z czego
  przynajmniej jeden faktycznie zaktualizował/usunął wpis (dowód, że mechanizm coś łapie, nie tylko
  odhacza).
- **Komenda:**
  ```bash
  cat .claude/memory/_decision-sweep-log.md 2>/dev/null | wc -l
  ```
- **Gdzie zapisać werdykt:** nowa karta kanban „Decision-sweep — held-out" + zdjęcie tej pozycji stąd.

---

### H8 — `obsidian-feedback-sweep`: pętla korekty klasyfikacji w kroku CLOSE

- **Co jest hipotezą:** rozszerzenie fazy 5 CLOSE (re-pull, który i tak już się dzieje) o sprawdzenie,
  czy klasyfikacja/routing zamykanego itemu się sprawdziły (reopened z pushbackiem, Owner nadpisał
  routing, „Do now" odrzucone) — i dopisanie korekty do reguł domenowych projektu (`CLAUDE.md`/
  `.claude/memory/`), nie tylko do rejestru. Ten sam wzorzec decyzja→wynik→ocena→korekta co H7
  (`session-retro` krok 4a), przeniesiony na inny skill z identycznym problemem: klasyfikacja to
  decyzja zapisywana bez późniejszej weryfikacji trafności.
- **Data zmiany:** 2026-08-26 (`obsidian-toolkit`, `SKILL.md` obsidian-feedback-sweep — na prośbę
  usera „zrób podobny sweep dla obsidian-feedback-sweep, ma podobny problem").
- **Stan gate'a:** `0 przebiegów` — dopiero wdrożone, zero sweepów po zmianie.
- **Soczewka:** per przebieg CLOSE — czy sprawdzenie trafności faktycznie złapało choć jeden przypadek
  błędnej klasyfikacji/routingu (nie tylko potwierdziło wszystko jako trafne, co jest rytualne).
- **Ryzyko odwrotne, którego trzeba pilnować:** krok wydłuża CLOSE bez korzyści, jeśli re-pull rzadko
  niesie sygnał zwrotny (reopened/nadpisany routing to rzadkie zdarzenia) — wtedy koszt (czas per
  sweep) przewyższa wartość.
- **Warunek wznowienia:** ≥ 3 przebiegi CLOSE po dacie zmiany, z czego przynajmniej jeden faktycznie
  dopisał korektę do reguł domenowych (dowód, że mechanizm coś łapie, nie tylko odhacza).
- **Komenda:** brak automatycznego skryptu (proces manualny w Obsidianie) — sprawdź ręcznie w
  rejestrach `Feedback Pipeline/Done/`, czy któryś ma dopisaną linię korekty w `CLAUDE.md`/
  `.claude/memory/` projektu z odniesieniem do tego sweepu.
- **Gdzie zapisać werdykt:** karta kanban „Decision-sweep — held-out" (wspólna z H7) + zdjęcie tej
  pozycji stąd.

---

### H9 — `usage-audit` krok 3 „Pętla ulepszania": Korekta wpisana do hipotezy zamiast gołego „wraca do puli"

- **Co jest hipotezą:** gdy przebieg audytu stwierdza „brak zmiany / regres" dla hipotezy z
  `hipotezy-otwarte.md`, dopisz do TEGO wpisu jedno zdanie korekty (który kanał zawiódł, czego nie
  próbować drugi raz), zamiast generycznego „wraca do puli" bez treści. Werdykt „fix trzyma" pisz
  jako `metadata.status: fakt` (schemat `memory-discipline`), nie zostawiaj hipotezy wiecznie
  hipotezą mimo potwierdzenia. Ten sam wzorzec co H7/H8, trzeci skill z identycznym problemem:
  decyzja (fix na hipotezę) zapisana bez odzysku informacji zwrotnej dla następnej próby.
- **Data zmiany:** 2026-08-26 (`workflow-toolkit`, `SKILL.md` usage-audit — na prośbę usera „zrób
  podobny sweep dla usage-audit, ma podobny problem").
- **Stan gate'a:** `0 przebiegów` — dopiero wdrożone, żaden przebieg audytu jeszcze nie stosował tej
  wersji kroku 3.
- **Soczewka:** per przebieg audytu — czy „regres" faktycznie skutkuje dopisaną Korektą w
  `hipotezy-otwarte.md` (nie tylko w lokalnym, git-excluded `AUDIT-USAGE.local.md`, gdzie ginie przy
  następnym przebiegu/migracji — sedno tej klasy problemu to trwałość informacji zwrotnej, nie sam
  fakt jej istnienia).
- **Ryzyko odwrotne, którego trzeba pilnować:** Korekta wpisywana rytualnie, bez realnej treści
  („nie zadziałało, spróbuj czegoś innego") — wtedy nic nie różni się od status quo.
- **Warunek wznowienia:** ≥ 3 przebiegi `usage-audit` po dacie zmiany zakończone werdyktem „regres"
  na którejkolwiek hipotezie z rejestru, z czego przynajmniej jeden ma faktycznie treściwą Korektę
  (nie rytualną).
- **Komenda:** brak automatycznego skryptu — sprawdź `git log -p -- plugins/workflow-toolkit/skills/session-retro/hipotezy-otwarte.md`
  po dacie zmiany, czy któryś commit dopisuje linię `Korekta:` do istniejącego wpisu H1–H6.
- **Gdzie zapisać werdykt:** karta kanban „Decision-sweep — held-out" (wspólna z H7/H8) + zdjęcie
  tej pozycji stąd.

---

## Zamknięte (zostawiaj krótki ślad, żeby nikt nie proponował tego drugi raz)

### Z1 — poszerzenie hooka `route-skills.sh` o intent „komentarz do Figmy" — ODRZUCONE 2026-08-13

`held-out T: 2/12 trafione, 9 fałszywych alarmów` (regex projektowany na dev-secie 1769 promptów,
mierzony ślepo na held-oucie 948). Warunek zerowego fałszywego alarmu złamany 9×; zaciśnięcie
kandydata schodzi do 2 ocenianych przypadków, czyli pod bramkę wielkości. Powód strukturalny
i zakaz powtarzania siedzą w komentarzu w `hooks/route-skills.sh` — wznowienie tylko z INNYM
kanałem niż proximity słów kluczowych.

---

### H5 — warunek unieważnienia przy każdej rekomendacji — WERDYKT NIEJEDNOZNACZNY (gate nie przechodzi czysto) 2026-08-24

`held-out C: 26 ocenianych pozycji (source A, time-split, 20 sampli z 10 różnych projektów/
worktree, okno 2026-08-18→2026-08-24) — 16/26 met (62%), 10/26 broken (38%)` (50 itemów w 20
odpowiedziach; 24 wyłączone z mianownika jako „nie dotyczy" — format BRAK REKO albo decyzja
trywialna/odwracalna jednym ruchem). Rozkład w czasie jest tu rozstrzygający: WSZYSTKIE 10 złamań
skupione w poranku 2026-08-18 (08:08–09:40) — spójne z tym, że reguła weszła do globalnego
CLAUDE.md tego samego dnia, czyli ten wycinek jest zanieczyszczonym dev-setem, nie prawdziwym
held-outem. Zawężenie do samego 08-24: 0/13 złamań, ALE 7/13 „met" jest rytualne — warunek
unieważnienia to goła negacja własnej rekomendacji („traci trafność, gdy zdecydujesz inaczej"),
nie obserwowalny nowy fakt. Licząc tylko warunki niepuste/informacyjne: 9/26 (35%) nawet
w najkorzystniejszym ujęciu.

Werdykt wg `held-out-gate.md → „kiedy wolno powiedzieć «lepsza»"`: Warunek 2 (≥3 oceniane)
spełniony (26, albo 13 po zawężeniu do 08-24). Warunek 3 (zero NOWYCH złamań R1) — NIE spełniony
w pełnym oknie (10 złamań); warunkowo spełniony tylko w zawężonym 08-24, i to podważony przez
problem rytualnych odpowiedzi. **Bramka nie przechodzi jednoznacznie** — H5 zostaje hipotezą, NIE
awansuje do wymuszonego kanonu (reguła i tak już stoi w CLAUDE.md/SKILL.md od 08-18 — ten werdykt
nie każe jej zdejmować, tylko mówi że zgodność z nią nie jest jeszcze czysto dowiedziona).

Zastrzeżenia własne, warte zachowania: pojedynczy nie-ślepy sędzia (autor hipotezy), mała próbka
wobec 187 pasujących wiadomości w oknie, niepewny dokładny moment przyjęcia reguły (przybliżony
do dnia, nie do commita), brak prawdziwego A/B (reguły nie było przed 08-18), klasyfikacja
„rytualne" to osąd jakościowy, niezweryfikowany niezależnie.

**Warunek wznowienia:** świeże ~2-tygodniowe held-out okno UCZCIWIE po zanieczyszczonym poranku
08-18 + ślepy drugi sędzia (nie autor hipotezy) + filtr jakościowy odrzucający warunki będące
czystą negacją własnej rekomendacji jako „puste"/nieliczące się do progu (bez tego punktu (c) próg
3 przypadków jest trywialnie ogrywany rytualnymi odpowiedziami).

**Pełny zapis** (liczby, cytaty złamań, metodologia, wszystkie zastrzeżenia) → Obsidian
`KANBAN/Evale jako brama — dokoncz pozostale 10 plikow prozy.md`, sekcja „H5 — werdykt 2026-08-24".

---

### H4 — cost gate z ABORT-em w drogich skillach (`design-tweaker`, `code-design-audit`, `web-research`)

- **Co jest hipotezą:** trzy pytania self-judge przed trybem panel/full/deep; „nie" na którymkolwiek
  → tryb tańszy. Wzorzec zapożyczony z `neuroarxiv` (pre-flight gate), nie zmierzony u mnie.
- **Data zmiany:** 2026-08-18 (`design-toolkit` 1.5.0, `workflow-toolkit` 1.32.0).
- **Stan gate'a:** `held-out C: 0 ocenianych przypadków` — reguła powstała dziś, zero wywołań po zmianie.
- **Soczewka:** C (zmiana treści) — oceniaj per wywołanie skilla: czy gate został przebiegnięty i czy
  wybrany tryb był tańszy niż domyślny tam, gdzie któreś pytanie wypadło na „nie".
- **Ryzyko odwrotne, którego trzeba pilnować:** gate może ZANIŻAĆ jakość — panel/deep pominięty tam,
  gdzie był potrzebny. Werdykt musi liczyć obie klasy błędu, nie tylko oszczędność.
- **Warunek wznowienia:** ≥ 3 wywołania OCENIANE każdego z trzech skilli osobno (skille mają różne
  progi; wspólna liczba nic nie rozstrzyga).
- **Komenda:**
  ```bash
  for s in design-toolkit:design-tweaker design-toolkit:code-design-audit workflow-toolkit:web-research; do
    plugins/workflow-toolkit/skills/usage-audit/scripts/heldout_split.sh "$s" 2026-08-18
  done
  ```
- **Gdzie zapisać werdykt:** nowa karta kanban „Cost gate — held-out" + zdjęcie tej pozycji stąd.
  **Uwaga (2026-08-24):** werdykt H5 (siostrzana hipoteza, ta sama data zmiany) wylądował na
  ISTNIEJĄCEJ karcie „Evale jako brama — dokoncz pozostale 10 plikow prozy", nie na nowej „Cost
  gate — held-out" (ta jeszcze nie istniała w momencie gdy H5 był gate'owany). Kto będzie odpalał
  gate H4 — sprawdź, czy dorobić werdykt do TEJ SAMEJ karty co H5 (spójność) czy świadomie założyć
  osobną „Cost gate — held-out", jak było pierwotnie planowane.

---

### H6 — `ux-copy`: reguła American English z klauzulą „nie mirroruj brytyjskiej pisowni z promptu"

- **Co jest hipotezą:** cały nowy skill `design-toolkit:ux-copy` jako kanał pisania stringów, a w nim
  konkretnie §1 rule 1 — US English wygrywa z pisownią, którą user/brief/istniejące copy podaje
  brytyjsko (mirror-back to realna klasa błędu: MAN-809, dwie rundy feedbacku KIPP 2026-08-06/07).
- **Data zmiany:** 2026-08-18 (`design-toolkit` 1.6.0, commit `4a5511b`).
- **Stan gate'a:** `held-out: 0 ocenianych przypadków`. Eval 001 odpalony 2026-08-18 dwa razy:
  bez ablacji `score 1.00` (2/2), potem `--ablation with-without` → **`with 0.50 · without 0.00 ·
  Δ +0.50`** ($1.00, 332s). **Wkład skilla zmierzony i nośny**: arm `without` przegrał 6/6 głosami,
  bo bazowy model jawnie deklaruje en-GB („skoro używasz *personalise*, trzymam en-GB") — klasa
  błędu MAN-809 jest reprodukowalna. Spadek `with` do 0.50 to **fałszywe FAIL-e gradera**, nie
  regres skilla: wszystkie stringi w obu runach były amerykańskie, a sędzia karał wymaganą przez
  skill notkę „piszę US; jeśli klient jest UK-based, przerzucę". `criteria.md` przepisane
  (definicja *stringu interfejsowego* + zawężona klauzula FAIL); `SKILL.md` świadomie nietknięty.
  **Re-run na poprawionym kryterium: `1.00`, 3/3 runy, 9/9 głosów** ($1.05) — sprawdzone, że
  mierzyło nową wersję (`grep -c "wstrzymuje copy"` w cache 1.6.2 = 1, w 1.6.0 = 0). Warstwa evala
  **zamknięta**; otwarty zostaje wyłącznie held-out.
- **Soczewka:** dwie, mierz osobno — **T (trigger fidelity)**: czy prośba o copy („napisz copy",
  „co ma być na przycisku", placeholder w buildzie) ładuje skill, czy leci z pamięci; **C (treść)**:
  czy wyemitowane stringi trzymają US English + sentence case + verb-first CTA.
- **Ryzyko odwrotne, którego trzeba pilnować:** skill przechwytuje audyt copy zamiast pisania i
  produkuje drugi werdykt obok `design-tweaker`/`code-design-audit` — werdykt musi policzyć
  przypadki, w których `ux-copy` odpalił się na zadaniu audytowym.
- **Warunek wznowienia:** ≥ 3 przypadki OCENIANE (realne prośby o copy po dacie zmiany). Warstwa
  evala nie ma już długu — cokolwiek dalej rozstrzyga się na realnych sesjach, nie na case'ie.
- **Komenda:**
  ```bash
  plugins/workflow-toolkit/skills/usage-audit/scripts/heldout_split.sh \
    design-toolkit:ux-copy 2026-08-18
  ```
- **Gdzie zapisać werdykt:** ta sama karta co H4/H5 („Cost gate — held-out") + zdjęcie tej pozycji stąd.
