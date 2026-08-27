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
- **Poprawka wdrożona 2026-08-26 (REKO Piotra), gate przemierzony OD NOWA od tej daty.** Reguła 1
  dostała punkt **1a** nazywający obie zmierzone luki wprost, zamiast liczyć, że wynikają
  z ogólnego zakazu: (a) **sekcja decyzji nie jest wyjątkiem** — kontrakt odpowiedzi wymusza nazwaną
  rekomendację i model wypełniał ją formą "REKO: potwierdź słowem wyślij" (`MAN-595`); draft nie
  jest pozycją do decyzji, więc nie wystawia się go do potwierdzenia; (b) **zablokowana próba wysyłki
  nie odblokowuje pytania** — po padniętym "wstaw to" mówisz w trybie oznajmującym, co zablokowało
  i co user może zrobić sam; (c) pytania o kanał nie łączy się z zaproszeniem (`MAN-896`:
  "powiedz wyślij i doprecyzuj czy jako komentarz czy description" to jedno i drugie naraz).
- **Nowa data odcięcia held-outu: 2026-08-26** (poprzednia 2026-08-17 zamknięta werdyktem
  `ODRZUCONA`). Warunek wznowienia bez zmian: >= 3 oceniane drafty, ale teraz **musi być wśród nich
  co najmniej jeden po zablokowanej próbie wysyłki** — to jest ta część populacji, której poprzedni
  fix nie pokrywał, więc przebieg bez niej nie zmierzy poprawki.
- **Soczewka:** doctrine-compliance — oceniaj per realny draft wysłany do Lineara/Figmy po dacie
  zmiany, sprawdzając czy PADA jakakolwiek formuła zaproszenia do wysyłki.
- **Warunek wznowienia:** ≥ 3 przypadki OCENIANE (musi zawierać ≥1 po zablokowanej próbie wysyłki —
  patrz wyżej), czyli realne drafty `linear-ticket-draft` po **2026-08-26**.
- **Komenda:**
  ```bash
  plugins/workflow-toolkit/skills/usage-audit/scripts/heldout_split.sh \
    workflow-toolkit:linear-ticket-draft 2026-08-26
  ```
  *(Poprawiona 2026-08-27 — commit `00cd066`, który dopisał „Nowa data odcięcia: 2026-08-26" i osobny
  blok „Zaktualizowana komenda" z tą datą, zostawił NIŻEJ stary blok „Komenda" ze STARĄ datą 2026-08-17
  nietknięty. Kanban-karta „Held-out przegląd hipotez" skopiowała ten stary blok jako priorytet H3 —
  scalone w jeden, poprawny blok, żeby drugi retro nie mierzył już zamkniętego okna.)*
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

### Przebieg 2026-08-27 (osobna sesja dedykowana temu przeglądowi, per kanban „Held-out przegląd hipotez") — WSZYSTKIE pozycje odpalone, ZERO ruchu, 2 błędy w rejestrze naprawione

Odpalone `heldout_split.sh`/ręczny check dla **wszystkich 8 pozycji z „Otwarte"** (H2, H3, H7–H12)
**+ dwóch pozycji z „Zamknięte", których held-out realnie stoi na zero i nie ma dowodu klasyfikacji**
(H4 — trzy skille, H6). H5 pominięty świadomie: jego warunek wznowienia wymaga ślepego DRUGIEGO
sędziego, którego ta sesja (jeden model, bez zewnętrznego oceniającego) nie może dostarczyć.

| Hipoteza | Held-out (nowe okno) | Zmiana vs poprzedni przebieg | Co blokuje |
|---|---|---|---|
| H2 | 0 wywołań | brak | zero realnych sesji z pytaniem routingowym |
| H3 | 2 wywołania (okno 2026-08-26..dziś, **1 dzień**) | nowe okno (poprawka wdrożona wczoraj) | za mało czasu, nie zaległość |
| H4a (design-tweaker) | 0 | brak | zero wywołań skilla po 08-18 |
| H4b (code-design-audit) | 0 | brak | zero wywołań skilla po 08-18 |
| H4c (web-research) | 0 | brak (2 wywołania total od 07-01, oba przed 08-18) | skill rzadko wołany w ogóle |
| H6 (ux-copy) | 0 (0 nawet w dev-secie — brak dowodu, że skill kiedykolwiek wystartował przez `Skill()`) | brak | zero adopcji, nie tylko zero held-outu |
| H7 | `_decision-sweep-log.md` nie istnieje nigdzie (`find` po całym `~`) | brak | mechanizm nieodpalony ani razu |
| H8 | 0 plików w `Feedback Pipeline/Done` zmodyfikowanych po 2026-08-26 | brak | zero CLOSE po zmianie |
| H9 | `git log` na tym pliku po 2026-08-26 — same commity WPROWADZAJĄCE H7–H12, żaden nie dopisuje `Korekta:` do H1–H6 | brak | zero przebiegów usage-audit z regresem |
| H10 | 1 nowy plik w `Research/` po 2026-08-26 (`MAN-909 translation management UI`), ale bez istniejącego raportu na ten temat wcześniej — krok 0b nie miał czego porównać | brak | temat bez poprzednika, nie zaległość |
| H11 | 19× `related:`, 13× `linear:` na JEDYNYM boardzie w vault (`find` = 1 plik `.base` w całym Manta Vault) | rośnie na tym boardzie, ale warunek pyta o INNY board, którego nie ma | **strukturalnie niespełnialny dziś** — patrz notatka w sekcji H11 |
| H12 | brak nowego wpisu > H12 w rejestrze | brak | zero sesji z powtarzalną edycją drafta po zmianie |

**Naprawione po drodze (bugi w samym rejestrze, nie w hipotezach):**
1. **H3 miała dwa sprzeczne bloki „Komenda"** — nowy (2026-08-26) i stary nietknięty (2026-08-17),
   pozostawiony przez commit `00cd066`. Kanban-karta zlecająca ten przegląd skopiowała STARY blok
   jako polecenie dla H3 — scalone w jeden. Bez tej naprawy kolejne retro (i ta karta) mierzyłyby
   zamknięte już okno.
2. **H11 ma dziś niespełnialny warunek wznowienia** — wymaga innego boardu niż antisis-prototype,
   a w całym dostępnym vault istnieje dokładnie jeden plik `.base`. Dopisana notatka w sekcji H11,
   żeby czwarty/piąty przebieg nie odpalał tego samego grepa bez sprawdzenia najpierw.

**Wniosek procesowy:** żadna pozycja nie osiągnęła progu ≥3 OCENIANYCH przypadków — w większości
dlatego, że skille źródłowe (`design-tweaker`, `code-design-audit`, `ux-copy`, `web-research`,
sweep-mechanizmy H7–H10/H12) po prostu rzadko/nigdy się odpalają, nie dlatego, że ktoś odkłada
klasyfikację (różnica względem H1's lekcji z 2026-08-25 — tam populacja BYŁA i czekała na ręczną
robotę; tu populacji często w ogóle nie ma). Jedyny wyjątek to H3, gdzie 1 dzień od poprawki to za
mało czasu z definicji, nie zaległość. **Nowych hipotez z tej sesji: ZERO.**

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

### H10 — `web-research`: pętla korekty przy ponownym researchu na ten sam temat

- **Co jest hipotezą:** krok 0b — gdy nowe wywołanie skilla dotyczy tematu z istniejącym raportem
  w Obsidian `Research/`, zestaw kluczowe twierdzenia starego raportu z aktualnym stanem PRZED
  napisaniem nowego raportu; potwierdzone → oznacz w starej notatce; sfalsyfikowane → dopisz
  `Korekta (data)` z kalibracją zaufania do KLASY źródeł/prognoz, nie tylko pojedynczej pomyłki.
  Czwarty skill z tym samym wzorcem co H7/H8/H9: twierdzenie zapisane jako fakt-na-dziś, nigdy
  nieskonfrontowane z wynikiem.
- **Data zmiany:** 2026-08-26 (`workflow-toolkit`, `SKILL.md` web-research — na prośbę usera „zrób
  podobny sweep dla web-research, ma podobny problem").
- **Stan gate'a:** `0 przebiegów` — dopiero wdrożone, zero powtórnych researchy na ten sam temat po
  zmianie.
- **Soczewka:** per przebieg — czy krok 0b faktycznie się odpalił (temat pokrywał się ze starym
  raportem) i czy porównanie było realne (na świeżych źródłach), nie rytualne odhaczenie.
- **Ryzyko odwrotne, którego trzeba pilnować:** krok 0b dodaje pracę do KAŻDEGO researchu na
  powtarzający się temat, nawet gdy stary raport jest za świeży, żeby cokolwiek się zmieniło —
  trzeba osądzić, czy w ogóle jest co porównywać, nie porównywać rytualnie.
- **Warunek wznowienia:** ≥ 3 przebiegi `web-research` po dacie zmiany, gdzie temat faktycznie
  pokrywał się z istniejącym raportem w `Research/` (rzadkie — ten skill nie jest wołany często na
  te same tematy, więc to może potrwać dłużej niż H7–H9).
- **Komenda:** brak automatycznego skryptu — sprawdź w vaulcie `Research/`, czy któraś notatka ma
  dopisaną linię `**Korekta (` albo `**Potwierdzone (` po dacie zmiany.
- **Gdzie zapisać werdykt:** karta kanban „Decision-sweep — held-out" (wspólna z H7/H8/H9) + zdjęcie
  tej pozycji stąd.

---

### H11 — `obsidian-kanban`: pola `related:`/`linear:` (cross-cutting powiązania poza epic/sub-task)

- **Co jest hipotezą:** dwa nowe pola frontmattera karty — `related:` (płaska sieć powiązań poza
  hierarchią epic/sub-task) i `linear:` (sam klucz ticketu, nie URL/kopia stanu) — mają uczynić
  powiązania między kartami queryowalnymi zamiast żyć wyłącznie w prozie. Wypróbowane na JEDNYM
  boardzie (antisis-prototype), backfill na 5 kartach, bez sprawdzenia że pomaga gdziekolwiek indziej.
- **Piąty skill z tym samym wzorcem co H7–H10, ale inny wariant problemu:** tu hipoteza była już
  SAMA SIEBIE nazwała „hipotezą" wprost w SKILL.md — ale samo słowo w prozie nie jest mechanizmem
  (dokładnie ostrzeżenie z nagłówka tego rejestru). Krok 4b retro czyta TEN plik, nie prozę
  poszczególnych skilli — więc hipoteza bez wpisu tutaj byłaby niewidoczna dla sweepu i cicho
  awansowałaby na kanon przez sam upływ czasu, mimo deklarowanego statusu „do potwierdzenia".
- **Data zmiany:** 2026-08-14 (`obsidian-toolkit`, wzorzec wprowadzony na antisis-prototype); wpisane
  do rejestru dopiero 2026-08-26 na prośbę usera „zrób podobny sweep dla obsidian-kanban, ma podobny
  problem" — czyli hipoteza żyła 12 dni poza zasięgiem sweepu.
- **Stan gate'a:** `0 ocenianych przypadków poza dev-setem` — jedyny dowód to backfill, na którym
  hipoteza powstała (dev-set, nie held-out).
- **Soczewka:** per board — czy pola faktycznie były wypełniane na kolejnym boardzie (nie tylko
  antisis-prototype) i czy queryowalność (`related` swimlane, `linear:` lookup) realnie ujawniła coś,
  czego nie było widać w prozie karty.
- **Ryzyko odwrotne, którego trzeba pilnować:** wymuszanie pól na boardzie, który nie ma problemu
  rozproszonych powiązań — koszt (dwa dodatkowe pola do utrzymania per karta) bez korzyści.
- **Warunek wznowienia:** ≥ 3 boardy OCENIANE (inne niż antisis-prototype) z realnie wypełnionymi
  polami `related:`/`linear:` po dacie zmiany.
- **Komenda:**
  ```bash
  grep -rl "^related:" "<vault>"/*/KANBAN 2>/dev/null | wc -l
  grep -rl "^linear:" "<vault>"/*/KANBAN 2>/dev/null | wc -l
  ```
  (ścieżka vaultu/folderu boardu per projekt — brak jednego wspólnego korzenia).
- **Gdzie zapisać werdykt:** karta kanban „Decision-sweep — held-out" (wspólna z H7–H10) + zdjęcie
  tej pozycji stąd + aktualizacja sekcji „Powiązania" w `obsidian-kanban/SKILL.md`.
- **Zmierzone 2026-08-27: warunek wznowienia jest dziś STRUKTURALNIE niespełnialny, nie tylko
  „za mało danych".** `find` po całym `Manta Vault` (jedyny vault z dostępem w tej sesji) znajduje
  dokładnie **JEDEN plik `.base`** (`KANBAN/-Kanban Board.base`) — czyli **zero innych boardów w
  ogóle istnieje**, nie tylko zero z wypełnionymi polami. Adopcja NA TYM boardzie urosła (19×
  `related:`, 13× `linear:`, było 5 przy backfillu 2026-08-14) — silny sygnał, że mechanizm coś daje
  tam, gdzie żyje, ale to nie jest to, co „Warunek wznowienia" pyta (inny board). Dopóki nie powstanie
  drugi board, ten gate nie ma czego mierzyć — nie odpalaj `Komendy` ponownie bez sprawdzenia najpierw,
  czy drugi board już istnieje (`find <vault> -iname "*.base"` na każdym vault, do którego jest
  dostęp), inaczej to czwarty/piąty przebieg z tym samym zerem.

---

### H12 — `linear-ticket-draft`: korekta z edycji przed wysyłką (sygnał poza formalnymi regułami)

- **Co jest hipotezą:** nowy krok w SKILL.md — gdy user powtarzalnie (≥2×) edytuje draft przed
  wklejeniem tym samym typem poprawki, dopisz NOWĄ hipotezę do tego rejestru zamiast tracić sygnał.
  Różni się od H1/H3 (ten sam skill, ale te dwa są już w pełni obsłużone held-out gate'em i dotyczą
  STYLU/reguł twardych) — H12 łapie sygnał o TREŚCI/trafności draftu, który nie ma jeszcze żadnej
  formalnej reguły do złamania, więc dziś ginie bez śladu.
- **Data zmiany:** 2026-08-26 (`workflow-toolkit`, `SKILL.md` linear-ticket-draft — na prośbę usera
  „zrób podobny sweep dla linear-ticket-draft, ma podobny problem"; szósty skill z rodziny H7–H11).
- **Stan gate'a:** `0 przebiegów` — mechanizm dopiero wdrożony, zero edycji-po-zmianie zaobserwowanych.
- **Soczewka:** per sesja z draftem tego skilla — czy powtarzalna edycja (2×+ ten sam typ poprawki)
  faktycznie skutkuje nowym wpisem w tym rejestrze, nie tylko cichą poprawką w locie.
- **Ryzyko odwrotne, którego trzeba pilnować:** nadinterpretacja pojedynczej edycji jako wzorca —
  krok wprost zabrania tworzenia hipotezy z jednego przypadku (to złamałoby validation-gate).
- **Warunek wznowienia:** ≥ 2 sesje po dacie zmiany, w których user edytował draft tym samym typem
  poprawki, żeby sprawdzić czy krok faktycznie doprowadził do zapisania nowej hipotezy.
- **Komenda:** brak automatycznego skryptu — sprawdź czy przybyła nowa hipoteza (numer > H12) w tym
  pliku z uzasadnieniem odwołującym się do edycji drafta `linear-ticket-draft`.
- **Gdzie zapisać werdykt:** karta kanban „Decision-sweep — held-out" (wspólna z H7–H11) + zdjęcie
  tej pozycji stąd.

---

## Zamknięte (zostawiaj krótki ślad, żeby nikt nie proponował tego drugi raz)

### H1 — `linear-ticket-draft` R3: rozmieszczenie linków wg ICH LICZBY — ZAMKNIĘTA 2026-08-26

**Werdykt: wariant A ZWALIDOWANY (3/3), wariant B USUNIĘTY ze skilla jako reguła bez populacji.**

Cztery przebiegi held-outu. Wariant A („> 1 link → link per ekran, brak sekcji `**Links**`") zebrał
**trzy czyste przypadki** (`MAN-848` 2 linki / 2 bullety, `MAN-825` 2 URL-e per produkt, ticket
Family Portal 3 linki / 3 bullety) i zero kontrprzykładów — awansuje na regułę, adnotacja HIPOTEZA
zdjęta ze `SKILL.md`.

Wariant B („= 1 link → bullety bez linków + jeden link zbiorczy w `**Links**`") zebrał **0/3
ocenianych** — i to nie była zaległość wykonawcza. Każdy realny draft z dokładnie jednym linkiem
okazywał się **jednoakapitową odpowiedzią, nie listą ekranów w bulletach** (`MAN-896` — ogłoszenie
reskinu; `MAN-595` — odpowiedź na komentarz Toma), więc precondycja tej reguły nie zachodzi
w obecnym mixie zadań. **Decyzja Piotra (REKO 2026-08-26): usunąć wariant B zamiast czekać na
materiał** — reguła bez populacji jest kosztem czytania skilla bez żadnego zysku. Punkty 3 i 6
struktury oraz reguła zgodności 1:1 uproszczone w tym samym ruchu.

*Wraca do rozważenia, gdy pojawi się realny draft z dokładnie 1 linkiem opisujący WIELE ekranów
w bulletach — wtedy populacja istnieje i pytanie jest otwarte na nowo.*

**Lekcja procesowa (ważniejsza niż sam werdykt):** trzy przebiegi pod rząd raportowały „za mało
ocenianych", traktując to jak brak materiału. Czwarty przejrzał drafty i okazało się, że materiał
nigdy nie miał się pojawić. **„Za mało ocenianych" trzeci raz z rzędu przy wystarczającej liczbie
WYWOŁAŃ nie znaczy „czekamy dłużej" — znaczy „otwórz okno i sprawdź, czy populacja w ogóle
istnieje".** Klasyfikacja jest robotą mechaniczną i należy ją delegować do subagenta, a nie
odkładać, bo retro jest na wyczerpanym kontekście.

**Pełny zapis (przebieg 3, 2026-08-26)** → Obsidian
`KANBAN/Archive/Held-out gate — pierwszy realny przebieg na linear-ticket-draft.md`.

---

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
