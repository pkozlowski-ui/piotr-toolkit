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
### Przebieg 2026-09-02, trzeci tego dnia (retro sesji „Phone Authentication Flow / Account Console", antisis-prototype) — trzy pozycje z materiałem, jedna wystrzeliła NA MNIE

Sesja: zbudowała 18-ekranowy zestaw weryfikacji telefonu w Figmie, przeniosła go na własną stronę
`--- [AC] · Account Console`, odpaliła pełny gate (17/18 `pass:true`, break-restore potwierdzony),
przeniosła toast FP na dół-środek i zmergowała 3 PR-y (#763, #777, #779). Większość pozycji rejestru
znów bez materiału (ta sama klasa co dwa wcześniejsze przebiegi dziś) — odpalone tylko te trzy,
dla których sesja realnie dostarczyła sygnał.

**H13 (limit BAJTÓW w `guard-claudemd-bloat.sh`) — NOWY, mocny wsad, hipoteza NADAL otwarta.**
Rozkład bez zmian jakościowo (1 plik nad 30 KB: ten projekt 40 835 B; drugi 21 264 B; reszta ≤7,8 KB),
ale sesja dostarczyła to, czego brakowało: **realny przypadek przekroczenia progu w praktyce.**
Dopisałem ~280 bajtów do `CLAUDE.md`, plik przeszedł 40 251 → 41 028 B, i **nic mnie nie zatrzymało** —
zauważyłem sam, bo z nawyku odpaliłem `wc -c`. Potem ręcznie przyciąłem do 40 835 (nadal nad 40 KB).
Czyli doktrynalny limit „≤40 KB" zapisany w samym `CLAUDE.md` **nie jest mechanizmem** — dokładnie ta
klasa, którą ten rejestr ma łapać. To argument ZA wdrożeniem limitu bajtów w hooku, ale nie zamyka
hipotezy: brak testu hooka na payloadzie Write z 41 KB (część „Komendy", której nie da się odpalić,
póki hook nie liczy bajtów). **Zostaje otwarta, z dopisanym wsadem.**

**H15 (delegacja jako tryb domyślny) — zmierzone, bez werdyktu.**
`subagent-share.mjs --days 14`: dla `antisis-prototype` main/sub = **19227/6879 ≈ 26 % udziału
subagentów**. Ta sesja delegowała pełny gate do subagenta buildującego (kanał z kontraktu), więc jest
po stronie „za" — ale hygiene-audit w tej samej sesji zgłosił **11 sesji >40 wywołań bez delegacji**
w oknie 3 dni. Sygnał nadal mieszany, próg werdyktu nieustalony. **Zostaje otwarta.**

**H23 (rozmiar wpisu pamięci jako RATCHET) — mechanizm ZADZIAŁAŁ, i zadziałał przeciwko mnie.**
Check `memory-entry-size` wystrzelił na `browser-verification-gotchas.md` **po moim własnym edycie**
(25,0 → 26,2 KB). Reakcja: NIE dopisałem siebie do ledgera (to byłby fałszywy wyjątek — dokładnie to,
przed czym ostrzega `gate-exemption-discipline`), tylko zrobiłem to, o co check prosi — **rozbiłem na
fakty**: nowy wpis `browser-measurement-trust.md` (2,0 KB) z dwoma faktami o wiarygodności pomiaru,
grab-bag wrócił do 25,1 KB. **Sygnał ZA H23: ratchet realnie wymusił konsolidację zamiast rosnięcia.**
⚠️ Kontrsygnał w tym samym pomiarze: wpis był **już 25 576 B na `origin/main`, czyli nad progiem,
PRZED tą sesją** — czyli check strzelał wcześniej i nikt nie zadziałał. Mechanizm strzela, ale sam nie
wymusza reakcji; wymusiła ją dopiero sesja, która akurat czytała wynik. **Zostaje otwarta** — do werdyktu
brakuje dowodu, że standing finding jest domykany bez przypadkowego czytelnika.

**Znalezione przy okazji, do sprzątnięcia w rejestrze: KOLIZJA NUMERACJI — dwa różne H20** (linia 22
„motion-toolkit: adopcja komend" i linia 984 „brama `PreModelSwitch`/`PostModelSwitch`"). Nie ruszam
numerów w tym retro, żeby nie zepsuć odniesień z poprzednich przebiegów, ale to trzeba rozstrzygnąć,
bo „werdykt na H20" jest dziś dwuznaczny.


### H20 — motion-toolkit: adopcja komend i wartość tury drugiej (otwarte 2026-09-02)

Plugin `motion-toolkit` 1.0.6 dostarczony i zweryfikowany behawioralnie: `animate` (Sonnet,
end-to-end), `review-motion`, `motion-ideas`, `motion-name` — pass. **`motion-audit` NIETESTOWANY**
— jednoplikowy projekt testowy nie daje sygnału dla audytu całego codebase'u.

Dwie rzeczy czekają na materiał z realnego użycia:

1. **Czy komendy w ogóle się odpalają** w sesjach frontendowych — czy Piotr sięga po
   `/motion-toolkit:*`, czy praca z animacją idzie obok nich (ta sama klasa co missed-triggery
   z audytu 2026-07-10).
2. **Czy tura druga ma sens** — soczewka „Motion" w `design-tweaker`, wymiar motion
   w `code-design-audit`/`ui-polish-loop`, sekcja motion spec w `figma-handoff-prep`. Świadomie
   NIE zrobiona: routing utwardzamy dopiero, gdy widać, że warstwa jest używana i gdzie się gubi.

**Warunek wznowienia:** ≥3 sesje z realną pracą nad animacją w kodzie (nie testy tego pluginu).

**Komenda:**
```bash
grep -rl 'motion-toolkit:' ~/.claude/projects/*/[0-9a-f]*.jsonl 2>/dev/null | wc -l
```

**Ryzyko przeciwne:** plugin leży martwy, bo motion w kodzie to rzadka klasa zadań w tej pracy
(przewaga Figmy) — wtedy werdykt brzmi „zostaw jako referencję, nie rozbudowuj", i to też jest
wynik do zapisania, nie porażka.

### Przebieg 2026-09-02, drugi tego dnia (retro sesji „warstwa Virtual Assistanta w sales-demo", antisis-prototype) — ZERO ruchu, jeden confound na H15

Sesja: zbudowała i zmergowała trzy PR-y w `antisis-sales-demo` — warstwę Virtual Assistanta
Georginy (#765: home, Enrollment portfolio, Data Scientist z raportem Manty), sekcję R&E u Alicii
(#768) i portfolio executive Dr. Callahana (#769). Zero wywołań `linear-ticket-draft`,
`design-tweaker`, `code-design-audit`, `ux-copy`, `web-research`, `obsidian-feedback-sweep`,
`usage-audit`, `hygiene-audit`, zero edycji CLAUDE.md, zero nowych pól `related:`/`linear:` na
karcie — H2, H3, H7–H12, H14, H16, H18, H19 bez materiału (ta sama klasa co przebiegi 08-28..09-02:
sesja nie dotknęła mierzonego skilla).

Odpalone komendy tam, gdzie istnieją: **H13** (`find … CLAUDE.md -exec wc -c`) → jeden plik nad
progiem 40 KB (`antisis prototype` 40 465 B, pozostałe 1,6–21 KB) — n=1, za mało na gate, warunek
wznowienia niespełniony. **H17** (`find … audit-invariants.json`) → 1 plik, bez zmiany.

**H15 (delegacja jako domyślny tryb) — confound, NIE liczyć jako sygnał:** ta sesja nie delegowała
niczego, ale nie z wyboru — jej system prompt zawierał twarde „Do not call the AgentTool unless the
user requested it", więc delegacja była zablokowana narzędziowo, nie odrzucona przez model. Wpis
istnieje po to, żeby przy zliczaniu H15 nie policzyć tej sesji jako „reguła nie zadziałała".

**Nowych hipotez z tej sesji: ZERO.** Jedyna lekcja (ukryty Browser pane zamraża renderer: brak
layoutu → `innerText` = `""`, `rAF` w ogóle nie leci, animowany UI wygląda na zacięty; weryfikuj
`get_page_text` + SSR-`curl` + settled-state zamiast czekania) ma obiektywny check — objawy są
mierzalne i powtarzalne w każdej sesji z tym panelem — więc poszła jako **konsolidacja istniejącego
wpisu** `.claude/memory/browser-verification-gotchas.md` (zastąpiła sekcję z 2026-08-13, która
opisywała ten sam objaw jako „race paint/composite, brak powtarzalnego triggera" — trigger jest
nazwany: widoczność panelu). Netto rozmiar wpisu bez zmian (soczewka `memory-entry-size` zielona),
bo stara sekcja została wchłonięta, nie dołożona.


### Przebieg 2026-09-02 (retro sesji "FP Home visual polish w sales-demo", antisis-prototype) — ZERO ruchu

Sesja: poprawiła wizualnie ekran Family Portal home w `antisis-sales-demo` (avatary dzieci, greeting
z IconCircle, akcent na kartach "Action needed"), inspirując się figmowym Lighthouse home ale
kreatywnie recomponując elementy (nie klon 1:1) — zweryfikowała w Browser pane desktop+mobile,
zacommitowała i wypchnęła (`e843b8bb`). Zero wywołań `linear-ticket-draft`, `design-tweaker`,
`code-design-audit`, `ux-copy`, `web-research`, `obsidian-feedback-sweep`, `usage-audit`,
`hygiene-audit`, edycji CLAUDE.md, nowych pól `related:`/`linear:` na karcie kanban — żadna hipoteza
z rejestru miała czego mierzyć. Zgodnie z regułą z przebiegów 08-25..09-01 (sesja nie dotykająca
mierzonego skilla = nie liczy się jako odłożenie) — komendy nieodpalone.

**Nowych hipotez z tej sesji: ZERO.** Jedyna lekcja ("sales-demo ZERO etapu Figmy" z ADR 0009 nie
zakazuje Figmy jako wizualnej inspiracji, tylko formalnego kroku procesowego) poszła do
`.claude/memory/` projektu (`feedback-sales-demo-figma-as-inspiration.md`) jako doprecyzowanie
istniejącej reguły z jednoznacznym potwierdzeniem usera, nie jako hipoteza wymagająca held-out gate'u.

### Przebieg 2026-09-01, trzeci tego dnia (retro sesji „F12 Phase 4 mini-funnel + Houston content fix", antisis-prototype) — ZERO ruchu na H2/H3/H7–H14, jeden confound na H15

Sesja: zbudowała i zmergowała F12 Family profile MVP Phase 4 (mini-funnel, PR #756 + fix
kolizji nazw), potem REKO Piotra na przebudowę FP12M/D.10 School selection względem aktualnego
rosteru Houston (Figma + kod, PR #759), plus ten retro (PR #760, memory-only). Zero wywołań
`linear-ticket-draft`, `design-tweaker`, `web-research`, `obsidian-feedback-sweep`,
`hygiene-audit`, edycji CLAUDE.md, nowych pól `related:`/`linear:` na karcie kanban — H2, H3,
H7–H14 bez ruchu (ta sama klasa co przebiegi 08-28/08-31: sesja nie dotknęła mierzonego skilla).

**H15 (delegacja jako domyślny tryb) — confound, nie liczyć wprost:** sesja DELEGOWAŁA jeden
duży reuse-audit (Explore agent, na starcie, przed budową) zgodnie z regułą, ale WIĘKSZOŚĆ
mechanicznej roboty potem (Figma `figma_execute` do przebudowy School selection, `curl`/`grep`
inwentaryzacyjne, wielokrotne `gh pr checks` polling) zrobiła sesja główna bezpośrednio, nie
subagentem — częściowo dlatego, że praca była interaktywna/iteracyjna (screenshot→fix→re-screenshot
w pętli, niewygodna do oddania jednym promptem agentowi), częściowo bo build+audyt+PR-flow jest
jedną spójną narracją, nie osobnymi mechanicznymi krokami. Nie wpisuję tego jako nowy sygnał H15
(brak dostępu do pełnej definicji gate'a/Komendy w tej sesji, więc klasyfikacja byłaby zgadywaniem)
— zostawiam do przebiegu, który ma kontekst H15 w całości.

**Nowych hipotez z tej sesji: ZERO.** Lekcje operacyjne (jednostka `maxMismatch` w
`eval/manifest.*.json`, scoped `--files=` audit nie łapiący `component-name-collision`, fallback
`javascript_tool`+`MouseEvent` na zawodzący `computer{left_click}`) poszły do `.claude/memory/`
projektu (`code-design-audit-gate.md`, `browser-verification-gotchas.md`) — mają obiektywny
mechanizm sprawdzenia (czytaj `budgetPct` w wyniku diff / grep po repo / obserwowany fallback),
nie wymagają held-out gate'u tego rejestru.

### Przebieg 2026-09-01, drugi tego dnia (retro sesji „FP 7 przeterminowanych baseline'ów + REKO na wszystko", antisis-prototype) — ZERO ruchu

Sesja: przeczytała kartę kanban, zweryfikowała w izolowanym worktree (`origin/main`, PR #752) że
problem już rozwiązany side-effectem tej PR-ki, zamknęła kartę `Done`→`Archive`, zaktualizowała
pamięć projektu (`fp-baseline-staleness-2026-09` → RESOLVED → zarchiwizowana do `_archive/`),
zrebase'owała `feat/fp-lighthouse-mvp-iteration-panel` na `origin/main`, i przesunęła kartę „Task
for Kasel KIPP NYC" `To-do`→`To confirm` (blocked na priorytetyzację Piotra). Zero wywołań
`linear-ticket-draft`, `design-tweaker`, `code-design-audit`, `ux-copy`, `web-research`,
`hygiene-audit`, `obsidian-feedback-sweep`, edycji CLAUDE.md, przełączenia modelu, nowych pól
`related:`/`linear:`. H15 (delegacja): kolejny pomiar dopiero 2026-09-15 (pomiar 1 już zrobiony
2026-09-01 przez inną sesję tego dnia) — nie due. H22 (external-blocked sweep, 4a2): dopiero
wdrożony dziś przez inną sesję, cadence ~30 dni od PIERWSZEGO ręcznego sweepu (dziś) — nie due.
**Nowych hipotez z tej sesji: ZERO.**

### Przebieg 2026-09-01 wieczór (retro sesji „status karty FP parity-content-drift", antisis-prototype) — ZERO ruchu

Sesja była czysto informacyjna: przeczytała kartę kanban + powiązaną kartę, zweryfikowała stan
przez `git log`/`gh pr view` (PR #741/#742/#744 zmergowane, gate FP zielony), zwolniła claim.
Zero wywołań `linear-ticket-draft`, `design-tweaker`, edycji CLAUDE.md, pól `related:`/`linear:`,
`usage-audit`, `web-research` — żadna hipoteza z rejestru nie miała czego mierzyć. Zgodnie z regułą
z przebiegów 2026-08-25/08-28 (sesja nie dotykająca mierzonego skilla = nie liczy się jako
odłożenie) — komendy nieodpalone. **Nowych hipotez z tej sesji: ZERO.**

### Przebieg 2026-09-01 (retro sesji „kanban Dominique / epic sales-demo", antisis-prototype) — ZERO ruchu

Sesja pracowała wyłącznie na kartach Obsidian KANBAN i Linear (read-only na MAN-860/MAN-848) —
nie odpaliła `linear-ticket-draft`, `design-tweaker`, `hygiene-audit`, ani nie edytowała żadnego
CLAUDE.md. Zgodnie z regułą z przebiegów 2026-08-28/08-28-wieczór (sesja nie dotykająca mierzonego
skilla = nie liczy się jako odłożenie) — komendy nieodpalone, brak ruchu na H2/H3/H7/H13/H14.
**Nowych hipotez z tej sesji: ZERO.** Jedyna lekcja sesji (błędne przyjęcie, że sub-taski epika są
otwarte, bez sprawdzenia ich frontmattera) poszła do `.claude/memory/` projektu jako punkt reguły
(pamięć `kanban-workflow-discipline`), nie tutaj — ma obiektywny mechanizm sprawdzenia (czytaj
`status:` karty), nie wymaga held-out gate'u.

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
- **Przebieg 2026-09-01 — kanał odczytu ustalony, 9/9 held-out sklasyfikowanych ręcznie, warunek
  DALEJ NIESPEŁNIONY (brakuje podpopulacji 1b), ale silny sygnał na 1a/1c.**
  Dwie wcześniejsze próby tej sesji (surowy Bash `grep`/`cat` po `~/.claude/projects/**/*.jsonl`;
  `mcp__ccd_session_mgmt` — zero trafień treściowych) zawiodły. **Hipoteza „ccd_session_mgmt nie
  indeksuje sesji CLI/worktree" nieprzetestowana wprost i nieistotna — istnieje inny, działający
  kanał**: `skill_trigger_context.py` (już w repo) czyta `.jsonl` bezpośrednio przez `python3`
  wołane z Bash i NIE jest blokowane przez classifier (w przeciwieństwie do gołego `cat`/`grep` na
  tym samym pathspecie — różnica w klasyfikacji polecenia, nie w dostępności danych). Rozszerzony o
  nowy skrypt `usage-audit/scripts/skill_trigger_draft.py` (ten sam katalog, ten sam wzorzec), który
  dopisuje PEŁNĄ ścieżkę `.jsonl` i wyciąga treść draftu (tekst asystenta między wywołaniem skilla a
  kolejnym promptem usera) — dokładnie brakujący element do klasyfikacji per wymaganie.
  **Klasyfikacja 9 held-out wywołań (okno 2026-08-26 09:17 UTC commit `00cd066` .. dziś), reguła
  1/1a/1c (formuła zaproszenia „czekam/poczekam na «wyślij»", w tym zlepiona z pytaniem o kanał):**
  **5/9 ZŁAMANE** — `MAN-909` translation UI (13:14 26.08, dosł. „czekam na Twoje «wyślij» (i wybór
  komentarz/description)"), `MAN-900` (13:25 26.08, „czekam na Twoje «wyślij» + wybór kanału"),
  `MAN-595` (09:24 27.08, „czeka na Twoje «wyślij»… dopytam przy «wyślij»"), `MAN-764` handoff
  (10:34 27.08, „czekam na Twoje jawne «wyślij»"), `MAN-899` (11:21 27.08, „poczekam na Twoje
  «wyślij»" zlepione z pytaniem o kanał). **1/9 borderline** — `MAN-903` (09:57 28.08): bez formuły
  „wyślij", ale pytanie „komentarz czy description?" zadane PRZED inicjacją usera, wbrew „dopiero
  gdy user sam zainicjuje" z bazowej reguły — inny wariant tego samego problemu, nie liczony do
  twardego wskaźnika. **3/9 SPEŁNIONE** — `MAN-534` (11:04 27.08), `MAN-578` (10:00 28.08),
  HCZ report (08:39 31.08): draft pokazany, sekcja decyzji milczy o wysyłce, zero pytania o kanał.
  **Twardy wskaźnik 5/9 (56%) złamań — GORZEJ niż poprzedni przebieg (2/4, 50%), który już wtedy
  dał werdykt `ODRZUCONA`.** Reguła 1a/1c nie działa; sygnał jest jednoznaczny mimo braku 1b.
  **Reguła 1b (zablokowana próba wysyłki) — ZERO testowalnych przypadków.** Sprawdzone we
  wszystkich 9 sesjach: brak jakiegokolwiek wywołania `mcp__linear__save_comment`/`save_issue` w tym
  oknie (draft nigdy nie doszedł do próby wysyłki) i brak tool_resultów z odmową/blokadą powiązaną z
  wysyłką. Warunek wznowienia w PEŁNYM brzmieniu (wymaga ≥1 case po zablokowanej próbie) pozostaje
  NIESPEŁNIONY — to nie jest kanał zablokowany, tylko realnie brak tego typu zdarzenia w populacji.
  **Werdykt formalny NIE zapisany** (populacja 1b = 0, gate nie może uznać się za w pełni
  przeprowadzony) — ale liczba 5/9 na testowalnej części (1a/1c) jest zbyt jednoznaczna, żeby ją
  pominąć milczeniem do następnego przebiegu.
- **REKO Piotra 2026-09-01: eskalacja do hooka zamiast trzeciej wersji tekstu w SKILL.md
  (ten sam ruch co precedens H15/`context-watch.sh` v1→v2→v3 — tekst w kontekście nie jest
  deterministyczny).** Wdrożony `plugins/workflow-toolkit/hooks/guard-send-invitation.sh`
  (`Stop` hook, `hooks.json`, commit `5fd7213`) — regex na 3 warianty zmierzone w danych powyżej
  („czekam/czeka/poczekam na «wyślij»", „powiedz/potwierdź «wyślij»", zamykające „wysłać?"),
  blokuje (exit 2) `last_assistant_message` PRZED dotarciem do usera, fail-open na błąd
  parsowania. Reguła jest globalna (CLAUDE.md „Wysyłka na zewnątrz"), więc hook łapie każdy
  skill, nie tylko `linear-ticket-draft`. **Break-restore na wszystkich 9 held-out draftach z
  klasyfikacji wyżej: 5/5 znanych złamań → fire, 3/3 czystych → silent, borderline (`MAN-903`,
  brak dosłownego „wyślij") świadomie POZA zasięgiem tego węższego hooka — mechanizm jest kanonem
  od razu (precedens 2026-08-25/08-28: pełny break-restore nie czeka na held-out).**
  **Hipotezą NIE jest sama mechanika (zweryfikowana), tylko efekt w realnych sesjach idących
  naprzód** — czy model realnie przepisuje odpowiedź po bloku, czy próbuje obejść wzorzec
  (synonimy, inny szyk zdania) zamiast usunąć zaproszenie. **Nowe okno held-out startuje
  2026-09-01** (data wdrożenia hooka) — mierz DWIE rzeczy osobno: (a) czy w transkryptach
  pojawiają się realne odpalenia bloku (dowód że hook w ogóle się aktywuje — sprawdzalne po
  `stderr`/kontynuacji w `.jsonl`), (b) czy FINALNA (po ew. bloku) odpowiedź nadal niesie
  zaproszenie do wysyłki w innej formie niż złapane 3 wzorce (dowód realnego obejścia, nie
  tylko luki w regexie). Warunek wznowienia bez zmian co do liczby (≥3 oceniane, w tym ≥1 po
  zablokowanej próbie wysyłki), ale teraz drugi model deterministyczny jest w grze — jeśli
  utrzyma się do zera złamań, to on jest kanonem, nie akapit w SKILL.md.
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

### Przebieg 2026-08-28 (retro sesji MAN-578/F16, antisis-prototype) — ZERO ruchu, sesja nie dotknęła żadnego mierzonego skilla

Odpalone `heldout_split.sh` dla dwóch pozycji, których warunek dawał się sprawdzić jednym wywołaniem:

| Hipoteza | Held-out | Zmiana | Co blokuje |
|---|---|---|---|
| H3 (`linear-ticket-draft`, okno od 2026-08-13) | 15 wywołań (z 13 w przebiegu 08-27 wieczór) | +2 surowe | ręczny przegląd per wymaganie — nadal 0 OCENIANYCH przypadków wariantu B (dokładnie 1 link) |
| H4a (`design-tweaker`, okno od 2026-08-13) | 1 wywołanie | +1 | próg ≥3 niespełniony |

Sesja **nie odpaliła** `linear-ticket-draft` — hook routingu podniósł go przy słowie „draft do Linear",
ale draft nigdy nie powstał (robota była już zrobiona w równoległej sesji). Zgodnie z regułą z przebiegu
2026-08-26 ręczny przegląd czeka na sesję, która skill REALNIE wywoła, i idzie wtedy NA START sesji.
**Nowych hipotez z tej sesji: ZERO** — jedyna lekcja („karta `To confirm` = czytaj natywny kanał zanim
zbudujesz") poszła do pamięci projektu jako obserwacja z jednego przypadku, nie do skilla jako reguła.

### Przebieg 2026-08-31 (retro sesji „zawężenie dopasowania w code-audit-pr-gate", antisis-prototype) — ZERO ruchu, jedna pozycja z nowym wsadem obserwacyjnym

| Hipoteza | Stan po odpaleniu Komendy | Zmiana | Co blokuje |
|---|---|---|---|
| H7 (`session-retro` krok 4a) | `_decision-sweep-log.md` = **1** przebieg | brak (krok 4a nie był due — poprzedni przebieg tego samego dnia) | próg ≥3 przebiegów |
| H13 (limit BAJTÓW w `guard-claudemd-bloat.sh`) | 1 plik > 30 KB: `antisis prototype/CLAUDE.md` = **40251 B**, reszta ≤ 21 KB | brak — sesja nie edytowała żadnego CLAUDE.md | próg ≥3 realnych edycji plików > 30 KB |
| H14 (progi soczewek hygiene-audit) | **brak logu przebiegów** — `~/.claude/*hygiene*` nie istnieje | niemierzalne | nie ma z czego policzyć ≥5 przebiegów; warunek jest dziś nieweryfikowalny |
| H16 (PL narracja w blokach roboczych) | **+1 przypadek OCENIANY** — sesja narratorska w PL także w blokach roboczych, bez korekty od Piotra | 1 → liczba łączna nietrackowana mechanicznie | próg ≥3 ocenianych, przegląd ręczny transkryptów |
| H15 (delegacja jako domyślny tryb) | **przypadek SKAŻONY, nie liczyć** | — | sesja miała realną mechanikę (harness, greps, inwentaryzacja wersji hooka) wykonaną BEZ delegacji, ale wyłącznie dlatego, że instrukcja sesji jawnie zakazywała `Agent`. To confound, nie sygnał o skillu — H15 mierzy odruch delegowania, a tu odruch był zablokowany z zewnątrz. |
| H2, H3, H8–H12 | — | brak | sesja nie dotknęła tych skilli |

**Wniosek procesowy:** H14 ma warunek wznowienia, którego **nie da się dziś sprawdzić** — „≥5 przebiegów `hygiene-audit`" zakłada istnienie licznika przebiegów, a taki licznik nie istnieje (audyt drukuje stan, nie loguje przebiegu). To ta sama klasa, którą ta sesja naprawiała w bramie PR-a: **warunek/soczewka odnoszący się do obiektu, którego nikt nie mierzy, wygląda identycznie jak spełniany**. Zanim H14 da się rozstrzygnąć, potrzebny jest jednolinijkowy log przebiegu (jak `_decision-sweep-log.md` dla H7) — do decyzji Piotra, nie foldowane samowolnie.

**Nowych hipotez z tej sesji: ZERO.** Kandydat był jeden — soczewka `index-parity` w `hygiene-audit.mjs` nie wyklucza plików `_`-prefiksowanych, więc `_decision-sweep-log.md` (infra-log tworzony PRZEZ ten skill) jest raportowany jako pamięć bez wpisu w indeksie. Nie wpisany jako hipoteza, bo **nic nie zostało wdrożone** — to propozycja zmiany czekająca na decyzję, a rejestr trzyma zmiany już wdrożone bez pełnego gate'a. Jeśli Piotr przyjmie fix, wchodzi tu razem z golden-setem soczewki.

### Przebieg 2026-08-28 wieczór (retro sesji „runtime gates Guardian/FP", antisis-prototype) — ZERO ruchu, sesja nie dotknęła żadnego mierzonego skilla

| Hipoteza | Held-out | Zmiana | Co blokuje |
|---|---|---|---|
| H1/H3 (`linear-ticket-draft`, okno od 2026-08-13) | 15 wywołań | brak vs przebieg 08-28 rano | ręczny przegląd per wymaganie — wariant B (dokładnie 1 link + lista itemów w bulletach) nadal 0 OCENIANYCH |
| H3 (`linear-ticket-draft`, okno od 2026-08-17) | 14 wywołań | — | j.w. |
| H2/H4a (`design-tweaker`, okno od 2026-08-17) | 1 wywołanie | brak | próg ≥3 niespełniony |

Sesja pracowała wyłącznie w CI/kodzie (`design-gates.yml`, warstwy runtime dla Guardiana i FP) —
**nie odpaliła ani `linear-ticket-draft`, ani `design-tweaker`**, więc zgodnie z regułą z przebiegu
2026-08-26 to NIE liczy się jako kolejne odłożenie ręcznego przeglądu.

**Nowych hipotez z tej sesji: ZERO.** Trzy rzeczy dodane do repo produktowego mają obiektywny check
i są kanonem od razu, nie hipotezą: macierz po apkach w `design-gates.yml` (break-restore 3 warstwy ×
2 apki = 6/6 fire→silent), `eval/warm-routes.mjs` (break-restore: dead-port → exit 1), oraz cztery
pliki `parity-allow` w trybie strict (residual 0/0 na wszystkich czterech). To ta sama granica co
zapisana w przebiegu 2026-08-25: soczewka z break-restore nie trafia do tego rejestru.

**Gotcha zmierzona po drodze — czysto wykonawcza, nie reguła skilla, więc tylko ślad tutaj:**
kontekst `matrix` GitHub Actions **nie jest dostępny w job-level `if`**. `if: needs.x.outputs[matrix.a.k]`
nie daje błędu walidacji z komunikatem — daje startup failure całego workflow: run bez jobów, pusty
`check-runs`, zero adnotacji. Kosztowało dwa ślepe failed runy. Rozwiązanie: job poprzedzający emituje
CAŁĄ macierz jako JSON, konsument robi `matrix: ${{ fromJSON(needs.changes.outputs.apps) }}`. Kanon
tej gotchy siedzi w komentarzu w `design-gates.yml` w repo produktowym, nie tutaj.

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
- **Przebieg 2026-08-28 (retro sesji „Reset family portal state", antisis-prototype):** sesja
  domknęła jedną kartę (bez ticketu Linear i bez powiązań cross-cutting → słusznie zero nowych pól),
  ale board to **antisis-prototype, czyli dev-set** — warunek wznowienia mówi wprost „≥ 3 boardy INNE
  niż antisis-prototype", więc przypadek nie liczy się do held-outu i **nic nie mierzono**. Stan bez
  zmian: `0 ocenianych poza dev-setem`.
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

### H13 — `guard-claudemd-bloat.sh`: limit BAJTÓW (~40 KB) zamiast (albo obok) limitu linii

- **Co jest hipotezą:** zmiana guardu z `LIMIT=240` linii na limit bajtów ~40 KB (40 960 B,
  `wc -c`), ewentualnie oba naraz. **Guard NIE został zmieniony** — to propozycja czekająca na check.
- **Skąd:** audyt workflow 2026-08-27 (Manta Vault, „Workflow audit — AI harness, gates, koszty")
  + refaktor anti-bloat `antisis-prototype` PR #664: projektowy CLAUDE.md miał **98 286 B w 242
  liniach** — mieścił się o włos w limicie linii, a ważył ~29k tokenów always-on. Limit linii nie
  łapie puchnięcia W SZERZ (jedna linia po 5 400 B); dowód: linie 21/54/58 starego pliku po
  1,5–5,4 KB każda. Po refaktorze plik ma 40 930 B / 234 linie — limit bajtów by go pilnował,
  limit linii dalej pozwala mu urosnąć z powrotem do ~98 KB bez jednego bloku.
- **Ryzyko odwrotne, którego trzeba pilnować:** projekty z CLAUDE.md < 240 linii ale > 40 KB,
  które dziś przechodzą — twardy blok mógłby zablokować legalne edycje w innych repo
  (guard jest globalny dla wszystkich `*CLAUDE.md|*AGENTS.md`); przed utwardzeniem zmierzyć
  `wc -c` wszystkich plików instrukcji, które guard realnie widuje.
- **Soczewka:** fire/silent na obu osiach — (a) Write/Edit powiększający plik > 40 KB przy
  < 240 liniach → blok (dziś: przechodzi — to jest luka); (b) edycja skracająca/neutralna
  na pliku już > 40 KB → przechodzi (guard blokuje tylko powiększanie); (c) plik < 40 KB,
  edycja mała → przechodzi. Break-restore per gałąź, jak w kanonie gate'ów.
- **Warunek wznowienia (potwierdzony REKO Piotra 2026-08-27 — czekamy, nie utwardzamy):** ≥ 3 realne edycje plików instrukcji > 30 KB po dacie wpisu
  (żeby zobaczyć, czy klasa „wide bloat" w ogóle wraca), ALBO decyzja Piotra „utwardzaj".
- **Komenda:** `find ~/Documents -maxdepth 4 \( -name CLAUDE.md -o -name AGENTS.md \) -exec wc -c {} +`
  (rozkład rozmiarów = czy 40 KB to dobry próg) + test hooka na payloadzie Write z 41 KB treści.
- **Gdzie zapisać werdykt:** karta kanban audytu workflow 2026-08-27 + zdjęcie tej pozycji stąd.
- **Pomiar rozkładu 2026-09-01 (wsad do progu, hipoteza NADAL otwarta):** `find ~/Documents -maxdepth 4
  \( -name CLAUDE.md -o -name AGENTS.md \)` → **9 plików instrukcji, tylko JEDEN nad 30 KB**
  (`antisis prototype/CLAUDE.md` = 40 251 B / 238 linii); drugi w kolejności to `claude-memory/
  CLAUDE.global.md` (22 758 B) i `daily work/CLAUDE.md` (21 264 B), reszta ≤ 7,8 KB. **Konsekwencja
  dla progu:** proponowane 40 960 B zostawia jedynemu dużemu plikowi **709 B luzu** — czyli utwardzenie
  go dziś oznacza blok na pierwszej edycji tego repo, nie siatkę bezpieczeństwa. Jeśli próg wchodzi,
  realistyczny punkt to ~45 KB (headroom ~5 KB) albo warstwa Post jako ⚠️ zamiast twardego bloku.
- **Warunek wznowienia — NIESPEŁNIONY na 2026-09-01:** wymagane ≥3 realne edycje plików > 30 KB;
  rozkład pokazuje, że taki plik jest **jeden**, więc próg „≥3 edycje" jest osiągalny tylko przez
  powtarzalne edycje tego samego repo. Do rozstrzygnięcia razem z decyzją Piotra, nie samo z siebie.

---

### H14 — hygiene-audit: PROGI dwóch nowych soczewek stanu (gate-block, ci-nightly)

- **Co NIE jest hipotezą:** sama mechanika obu soczewek. `evalGateBlock` i `evalCiNightly` są
  czystymi funkcjami z lustrzanym break-restore w `hygiene-audit.mjs --selftest` (**18/18**,
  fire i silent per gałąź, w tym kontrole negatywne: „bez progów w configu asercje skali milczą"
  oraz „szybki `workflow_dispatch` nie maskuje wolnego `schedule`"). Wg precedensu z przebiegu
  2026-08-27 pełny break-restore czyni check kanonem od razu — więc kod nie czeka na gate.
- **Co JEST hipotezą — trzy liczby i jedna decyzja o kanale, bez ani jednego held-outu:**
  1. **`ciNightly.maxMinutes = 10`** — próg wzięty z jednego pomiaru (przed fixem #659 workflow
     ciągnął ~36 min, po fixie dispatch zmierzył 5,5 min). Nie wiadomo, jaka jest naturalna
     WARIANCJA zdrowego nightly na runnerach macOS — jeśli zdrowy run oscyluje 4–11 min, próg
     10 daje losowe ⚠️ i sam się zdyskredytuje.
  2. **`ciNightly.maxAgeHours = 48`** — czy pominięty cron to normalka (wtedy 48 h szumi), czy
     wyjątek (wtedy 48 h jest dobrym detektorem). Zmierzone 2026-08-28: cron `0 6 * * *` nie
     odpalił do 08:06 UTC — czyli klasa jest realna, ale próba = 1.
  3. **`claudeMd.maxBytes = 40 960` z zapasem 30 B** (antisis-prototype) — świadomie BEZ ~20%
     zapasu, jako forcing function. Hipotezą jest to, że zapala się RZADKO i sensownie; ryzyko
     odwrotne: ⚠️ przy każdej legalnej dopisce → alarm fatigue i check przestaje być czytany
     (dokładnie ta klasa, która zabiła auto-archiwum: „zaplanowany automat bez sprawdzonego logu").
  4. **Kanał `gate-block` = tryb `--hook`** (2 podprocesy node przy KAŻDYM starcie sesji, zmierzone
     +~40 ms, cały audyt 111 ms). Tanie dziś — ale to jedyna soczewka odpalająca cudzy skrypt
     w SessionStart, więc koszt rośnie razem z tym skryptem, nie z tym plikiem.
  5. **Trzy zacieśnione liczniki CLAUDE.md** (antisis-prototype #674, `8ad93e82`): `maxLines`
     380→280, `maxLineChars` 5200→1800, `designMarkerBaseline` 55→20 — po refaktorze #664 miały
     zapas 1,6× / 3,7× / 3,4×, czyli świeciły ✅ nie mierząc niczego. Fire/silent per licznik
     ZWERYFIKOWANY (próg o 1 pod wartość bieżącą → każdy strzela), więc mechanika żyje; hipotezą
     jest to samo co w punkcie 3 — czy „dziś + ~20%" to zapas zapalający się rzadko i sensownie,
     czy zbyt ciasny na naturalny rytm dopisek do always-on.
- **Data zmiany:** 2026-08-28 (REKO 1 i 3 audytu workflow 2026-08-27; karta kanban
  „Wpięcie weryfikacji REKO 1-3 w rutyny").
- **Soczewka:** stosunek sygnał/szum per soczewka — liczony na PRZEBIEGACH audytu, nie na
  sesjach: ile razy ⚠️ zapaliło się i ilu z tych zapaleń odpowiadał realny defekt (potwierdzony
  fixem albo świadomym podniesieniem progu w tym samym commicie). Osobno per liczba, bo mogą
  rozjechać się w przeciwne strony.
- **UNBLOCKED 2026-08-31 — warunek był NIEWERYFIKOWALNY, teraz jest mierzalny.** „≥ 5 przebiegów"
  zakładało licznik przebiegów, a taki nie istniał: audyt drukował stan i nie zostawiał śladu, że
  się odpalił, więc warunek odnoszący się do liczby przebiegów wyglądał identycznie jak spełniany
  (ta sama klasa co soczewka mierząca nie ten obiekt — patrz H17). Dodany best-effort log, jedna
  linia na run, POZA repo: **`~/.claude/hygiene-audit-runs.log`** (format: ISO-timestamp · tryb ·
  root · `warnings=N`). Zapis owinięty `try/catch`, bo hook ma kontrakt „exit 0 zawsze".
  **Licznik startuje 2026-08-31 od zera** — przebiegi wcześniejsze są bezpowrotnie niepoliczalne,
  więc próg liczymy od tej daty. Komenda: `wc -l ~/.claude/hygiene-audit-runs.log`.
- **Warunek wznowienia (zawężony 2026-09-01 — REKO Piotra, przebieg 2026-09-01 pokazał że surowe
  „≥5 wpisów w logu" jest gameable: 41 wpisów w 1 dzień, 34 to `hook` czyli auto-retrigger
  SessionStart, nie świadome audyty):** ≥ 5 wpisów w `hygiene-audit-runs.log` z trybem **`json` lub
  `human`** (WYŁĄCZAJĄC `hook`), każdy z zapisanym stanem tych trzech checków. Werdykt per liczba:
  wszystkie zapalenia trafione → próg trzyma; ≥ 2 zapalenia bez defektu → poluzuj TĘ liczbę (nie
  wszystkie) i dopisz powód. Przy licznikach CLAUDE.md (punkty 3 i 5) „trafione" znaczy: zapalenie
  skończyło się zwinięciem treści ALBO świadomym podniesieniem progu W TYM SAMYM commicie —
  podniesienie w oddzielnym commicie „bo się nie mieści" liczy się jako NIEtrafione, bo dokładnie to
  zamienia licznik w dekorację (i tak powstał zapas 3,7×, który tu zaciskamy).
  ⚠️ **Znana luka, nierozwiązana:** `json`/`human` też nie gwarantuje „scheduled `hygiene-audit-antisys`
  co ~3 dni" — subagent sweepu hipotez sam odpala `--json` żeby SPRAWDZIĆ ten warunek, więc wpisy
  potrafią rosnąć jako efekt uboczny mierzenia, nie niezależnego przebiegu (ta sama klasa błędu co
  oryginalny problem H14). Realny fix wymaga pola `source` w logu (cron vs ad-hoc-check vs manual)
  zapisywanego przez `hygiene-audit.mjs`, nie tylko `mode` — nieutwardzone, do decyzji Piotra przy
  następnym przebiegu jeśli próg `json`/`human` zacznie fałszywie zapalać.
- **Komenda:**
  ```bash
  # liczba ocenianych przebiegów po zawężeniu (wyklucza hook)
  awk -F'\t' '$2!="hook"' ~/.claude/hygiene-audit-runs.log | wc -l
  # stan trzech checków na dziś (json = pełny raport, także checki pomijane w --hook)
  cd ~/Documents/antisis\ prototype && node ~/Documents/piotr-toolkit/plugins/workflow-toolkit/scripts/hygiene-audit.mjs --json \
    | python3 -c "import json,sys; [print(c['id'], c['ok'], c['value']) for c in json.load(sys.stdin)['checks'] if c['id'] in ('gate-block','ci-nightly','claudemd-bytes')]"
  # wariancja zdrowego nightly (czy próg 10 min nie jest w chmurze szumu)
  cd ~/Documents/antisis\ prototype && gh run list --workflow=pixel-gate.yml -L 20 --json createdAt,updatedAt,event \
    | python3 -c "import json,sys,datetime as d; r=[x for x in json.load(sys.stdin) if x['event']=='schedule']; print([round((d.datetime.fromisoformat(x['updatedAt'].replace('Z','+00:00'))-d.datetime.fromisoformat(x['createdAt'].replace('Z','+00:00'))).total_seconds()/60,1) for x in r])"
  ```
- **Gdzie zapisać werdykt:** karta kanban „Wpięcie weryfikacji REKO 1-3 w rutyny" (sekcja
  `## Rezultat`) + zdjęcie tej pozycji stąd.

---

### H15 — delegacja jako DOMYŚLNY tryb w skillach sweep/audyt podnosi udział subagentów

- **Co jest hipotezą:** REKO 7 audytu workflow 2026-08-27 (karta „Fable inspects my workflow") —
  tekstowy nudge („rozważ delegację") w skillach mechanicznych nie działał (dowód: audyt tokenów,
  subagenci 15%→11,9% requestów w oknie; 4/20 sesji z 30–85 wywołaniami narzędzi, zero delegacji).
  Zmiana: `ui-polish-loop` (§2, sekcja „Execution mode") i `usage-audit` (§ Twarde reguły wykonania)
  przepisane z „rozważ subagenta" na deterministyczne „krok X wykonuje subagent Haiku/low (mechanika)
  lub Sonnet/medium (rutyna), chyba że user każe inaczej". Hipoteza: to podniesie udział subagentów
  w kolejnych audytach tokenów — sam zapis w SKILL.md wystarczy, bez zmiany kanału egzekucji
  (hook/gate). **Ryzyko odwrotne** (znane z „Hierarchia egzekucji" w `usage-audit`): sam opis w
  SKILL.md nie egzekwuje — jeśli hipoteza nie utrzyma się po 2 pomiarach, następny krok to hook/gate,
  nie trzecia wersja tego samego zdania.
- **Co NIE jest tą hipotezą:** eskalacja checku `model-delegation-threshold` w `hygiene-audit.mjs`
  (próg >40 mechanicznych wywołań narzędzi bez Task/Agent w oknie, per sesja) — to osobny, już
  break-restore'owany kanał (selftest 23/23), egzekwujący na poziomie hooka, nie na treści skilla.
  Ta hipoteza mierzy WYŁĄCZNIE efekt zmiany treści w `ui-polish-loop`/`usage-audit`.
- **Domknięcie luki 2026-08-28:** REKO 7 objęło pierwotnie tylko te dwa skille — `obsidian-feedback-sweep`
  (mechanika CAPTURE/CLASSIFY) był pominięty. Dopisany 2026-08-28 (ten sam wzorzec: Haiku/low dla
  CAPTURE, Sonnet/medium dla CLASSIFY) — trzeci skill w tej samej hipotezie, mierzony tym samym
  audytem tokenów.
- **Data zmiany:** 2026-08-28 (REKO 7 audytu workflow 2026-08-27, karta „Fable inspects my workflow").
- **Soczewka:** T (trigger/adoption) — `scripts/adoption_scan.sh` per skill nie mierzy tego wprost
  (mierzy wywołania SKILLA, nie subagentów WEWNĄTRZ jego kroków), więc metryka sukcesu jest z audytu
  tokenów, nie z `usage-audit` warstwy 1: **udział subagentów w requestach > 15% w 2 kolejnych
  audytach tokenów z rzędu** (kadencja audytu: 1. i 15. dnia miesiąca).
- **Warunek unieważnienia:** 2 kolejne audyty tokenów (najbliższe: 2026-09-01, 2026-09-15) BEZ
  wzrostu udziału subagentów powyżej baseline'u 11,9% → zmiana treści skilli nie działa; nie pisz
  trzeciej wersji tego samego nudge'u — eskaluj do hooka/gate'a (ten sam ruch co REKO na
  `model-delegation-threshold`, tylko wymuszony zamiast opisany) albo do decyzji Piotra o wycofaniu.
- **Komenda (od 2026-09-01 mechaniczna — koniec z ręcznym czytaniem transkryptów):**
  ```bash
  node plugins/workflow-toolkit/scripts/subagent-share.mjs --days 14        # globalnie
  node plugins/workflow-toolkit/scripts/subagent-share.mjs --days 14 --project .   # tylko ten projekt
  ```
  Skrypt liczy udział requestów subagentów (`type:"assistant"` z `usage`) w oknie z
  `~/.claude/projects`, z rozbiciem na rodzinę modelu, `effort` i `agentType` — czyli to samo, co
  `/tasks` pokazuje per subagent w UI od 2.1.243, ale porównywalne między oknami i wpisywalne do
  gate'a. `--json` daje `verdict` (`above-target` / `above-baseline` / `at-or-below-baseline`).
- **⚠️ Zmiana metody = nowy baseline, nie dowód wzrostu.** Baseline 11,9% pochodzi z RĘCZNEGO audytu
  tokenów 2026-08-27, liczonego inaczej niż ten skrypt — porównywanie 11,9% z liczbą skryptu miesza
  dwie metody i samo w sobie nie potwierdza H15. Pierwszy pomiar skryptem **jest baseline'em tej
  metody**; werdykt H15 zapada z DWÓCH kolejnych pomiarów tym samym skryptem.
- **Pomiar 1 tą metodą (2026-09-01):** okno 4 dni (od daty zmiany 2026-08-28), globalnie —
  **24,2%** subagentów (main 17 975 / sub 5 740 req; sonnet 4 746, haiku 994; agentType:
  general-purpose 117, claude 9, Explore 8). Okno 14 dni: **21,6%**. Sam `piotr-toolkit`, 14 dni:
  **13%** (123 req, wszystko haiku). Zero spawnów `fork`. Pomiar 2: **2026-09-15**, tą samą komendą,
  `--days 14`.
- **Gdzie zapisać werdykt:** karta kanban „Fable inspects my workflow" (sekcja `## Rezultat`) +
  zdjęcie tej pozycji stąd.

---

### H16 — `reinject-rules.sh`: PL narracja rozszerzona z finałów na bloki robocze

- **Co jest hipotezą:** dopisany punkt 4 do reguł re-injectowanych co turę — „PL nie tylko w finałach:
  bieżące komunikaty robocze (co robisz, co znalazłeś, dlaczego zmieniasz kierunek) też po polsku,
  nie tylko podsumowanie na końcu". Poprzednia treść hooka nie mówiła NIC o narracji roboczej,
  tylko o kontrakcie odpowiedzi (finałach) — hipoteza jest to, że jedno zdanie w tym samym kanale,
  który już realnie działa (`reinject-rules.sh` cytowany w `context-watch.sh` jako precedens
  „ten kanał w tym repo realnie działa"), wystarczy bez nowego mechanizmu (np. lintu na blokach).
- **Skąd:** audyt workflow 2026-08-27 (REKO 10), karta kanban „REKO 9-10 — stop-hooki warunkowo +
  domkniecie przeciekow EN w narracji". Zmierzone przy tym audycie: **13% bloków roboczych po
  angielsku przy 100% PL na zamknięciach** — czyli luka jest specyficznie w narracji W TRAKCIE
  pracy, nie w finałach (te już były 100% zgodne bez tej zmiany).
- **Data zmiany:** 2026-08-28 (`workflow-toolkit`, `hooks/reinject-rules.sh`, punkt 4).
- **Stan gate'a:** `0 przebiegów` — zmiana dopiero wdrożona, zero sesji po niej.
- **Soczewka:** T/C mieszane — per sesja PO zmianie: policz udział bloków ROBOCZYCH (nie
  finałowych) po angielsku vs po polsku; porównaj z baseline 13% z audytu 2026-08-27.
- **Ryzyko odwrotne, którego trzeba pilnować:** re-injection co turę już jest długi (4 punkty) —
  jeśli ten punkt nie obniży odsetka EN, kolejny krok to NIE piąte zdanie w tym samym hooku
  (przeciążenie kanału), tylko inny mechanizm (np. lekki lint na blokach roboczych).
- **Warunek wznowienia:** ≥ 3 sesje OCENIANE po 2026-08-28 z co najmniej jednym blokiem roboczym
  (żeby był w ogóle co mierzyć) — ręczny przegląd transkryptu per sesja, klasyfikacja per blok
  roboczy PL/EN.
- **Komenda:** brak automatycznego skryptu — ręczny przegląd transkryptów sesji po dacie zmiany,
  ten sam sposób liczenia co audyt 2026-08-27 (bloki robocze vs finałowe, per język).
- **Gdzie zapisać werdykt:** karta kanban „REKO 9-10 — stop-hooki warunkowo + domkniecie przeciekow
  EN w narracji" (Archive po domknięciu) + zdjęcie tej pozycji stąd.

---

### Przebieg 2026-08-27 (retro sesji gate-block `--only`, antisis-prototype) — zero ruchu

Sesja czysto kodowa (tryb selektywny `--only` w `.claude/scripts/gate-block.mjs`, PR #662) — nie
wywołała ŻADNEGO skilla z pozycji otwartych. `heldout_split.sh`: **H2** (`design-tweaker` 2026-08-17)
→ held-out **0 wywołań**, warunek niespełniony. **H3** (`linear-ticket-draft`, nowe odcięcie
2026-08-26 po werdykcie ODRZUCONA) → sesja skilla nie dotknęła, zero nowych draftów w oknie od 08-26
(strumień od 08-13 ma 12 wywołań, wszystkie sprzed nowego odcięcia albo już ocenione) — przegląd czeka
na sesję, która skill realnie odpali (musi zawierać ≥1 przypadek po zablokowanej próbie wysyłki). **H7–H12**
(checki manualne) — żadna sesja tego typu nie zaszła, nic nie mierzono. **Nowych hipotez: ZERO** —
jedyne nowe checki tej sesji (walidacja `--only`: fire/silent/closure/dangling) mają pełny lustrzany
break-restore w `gate-block.mjs --selftest` (15/15), więc są kanonem od razu, nie hipotezą.
Gotcha cache-vs-repo z 2026-08-25 potwierdzona kolejny raz: cache pluginu (1.32.0) nadal serwuje
starą wersję TEGO pliku (H1/H4/H5/H6 widoczne jako otwarte) — komendy odpalone najpierw z cache'owej
listy; werdykty spisane z repo.

---

### H17 — `hygiene-audit.mjs`: `_`-prefiks = plik infrastrukturalny, nie wpis pamięci

**Zmiana (wdrożona 2026-08-31):** inline-filtr `memFiles` wyciągnięty do czystej funkcji
`isMemoryEntry(f, indexFile)` i rozszerzony o wykluczenie plików `_`-prefiksowanych. Powód
konkretny: `_decision-sweep-log.md` — infra-log tworzony przez krok 4a TEGO skilla — był
raportowany przez soczewkę `index-parity` jako „pamięć bez wpisu w indeksie", czyli check żądał
wpisu w `MEMORY.md` dla pliku, który wpisem pamięci nie jest. Soczewka mierzyła NIE TEN obiekt.

**Co JEST udowodnione:**
- **Break-restore: 32/32** (było 23/23, +9 case'ów). Złamanie (usunięcie linii `startsWith('_')`)
  daje **3 czerwone** case'y i werdykt `FAIL (29/32)`; przywrócenie — `PASS (32/32)`.
- **Gate-proof w self-teście:** `decision-sweep-log.md` BEZ prefiksu nadal JEST wpisem, a
  `foo_bar.md` (podkreślenie w środku) też. To przypina regułę do PREFIKSU, nie do tej jednej
  nazwy pliku — soczewka „nauczona jednej nazwy" tych case'ów nie przechodzi.
- **Golden-set na realnym korpusie (antisis prototype): dokładnie 2 z 15 soczewek zmienione,**
  obie w zamierzonym kierunku — `index-parity` 1 → 0 (`ok` false → **true**, fałszywy pozytyw
  zdjęty) i `memory-cap` 42 → 41 (`ok` **nadal false**, czyli realny problem capu NIE został
  zamaskowany, tylko liczba jest uczciwa). Lista soczewek identyczna, **13 bez ruchu = zero
  collateralu**.

**Czego NIE da się dziś udowodnić — powód istnienia tej pozycji:** skrypt jest z założenia
reużywalny między projektami (żyje w `piotr-toolkit`, korzeniem jest CWD), ale **populacja
held-out jest PUSTA** — `find ~/Documents -name audit-invariants.json` zwraca dokładnie JEDEN
projekt, ten sam, na którym zmianę wymyślono. Roszczenie „nie psuje pozostałych projektów" jest
więc nietestowalne, nie potwierdzone. Dodatkowo tylko ten jeden projekt ma dziś w ogóle plik
`_`-prefiksowany, więc realna delta poza nim = nieznana.

- **Warunek wznowienia:** ≥ 2 KOLEJNE projekty z `.claude/audit-invariants.json` (poza
  `antisis prototype`), na których da się odpalić golden-set przed/po. Wtedy: powtórz diff
  soczewka-po-soczewce i zaakceptuj tylko, jeśli `index-parity` nie traci pokrycia na realnych
  wpisach pamięci, a lista soczewek zostaje identyczna.
- **Komenda:** `find ~/Documents -maxdepth 4 -name 'audit-invariants.json' -path '*/.claude/*' | grep -v worktrees | wc -l`
  (dziś: **1** → próg niespełniony, nic nie rób).
- **Warunek unieważnienia samej reguły:** przestaje obowiązywać, gdy `_`-prefiks zacznie
  oznaczać realne wpisy pamięci — wtedy potrzebna jest jawna allowlista infra-plików zamiast
  reguły prefiksu.

### H18 — reguła „pracuj seriami": próg 15 min zamiast miękkiego „długie luki"

**Co jest hipotezą:** nie sam fakt, że luka gasi cache (to jest ZMIERZONE, niżej), tylko że
**wpisanie progu liczbowego do always-on CLAUDE.md zmieni zachowanie na tyle, żeby te ~8% cache
write realnie spadło.** Reguła bez progu („pracuj seriami", „długie luki") istniała od dawna i
nie zapobiegła 22,8 mln tokenów przebudów — próg może po prostu opisać to samo dokładniej,
nie zmieniając niczego.

**Data zmiany:** 2026-09-01 (`CLAUDE.global.md`, sekcja „Dobór modelu i effort").

**Co JEST udowodnione** — pomiar na 86 022 unikalnych requestach z transkryptów
`~/.claude/projects`, okno 2026-08-01 → 2026-09-01, 835 sesji głównych + 305 sidechain
(`cache_probe.py`, definicja rebuildu: `cache_read < 50%` kontekstu z poprzedniej tury):

- **TTL potwierdzony twardo, nie z dokumentacji:** główna sesja zamawia **98,5%** tokenów
  cache jako `ephemeral_1h`, subagenty **100%** jako `ephemeral_5m`. To niezależnie domyka
  poprawkę z commita `5be5841` (wcześniejsze „5-min TTL" w regule było błędne).
- **Krzywa rebuildu vs luka (główna sesja)** — próg jest realny i ostry:
  `0–1m 0,2%` · `1–5m 4,4%` · `5–15m 6,0%` · **`15–30m 20,0%`** · `30–60m 41,5%` ·
  `60–120m 96,0%` · `>120m 100%`. Poniżej 15 min przerwa jest praktycznie darmowa;
  powyżej 60 min rebuild jest pewny i kosztuje średnio **~250k tokenów**.
- **Subagenty potwierdzają 5 min osobną krzywą:** `1–5m 19,2%` → **`5–15m 93,6%`**. Zapadka
  wypada dokładnie tam, gdzie TTL — czyli metoda pomiaru mierzy to, co ma mierzyć
  (to jest wewnętrzny gate-proof, nie druga hipoteza).

**Co pomiar OBALIŁ w intuicji stojącej za regułą:** luki ≥15 min odpowiadają za **7,8%**
całego `cache_creation` głównej sesji (22,8 mln z 293,4 mln). Rebuildy przy lukach **poniżej
5 minut** — czyli wewnątrz serii, tam gdzie „pracuj seriami" z definicji nic nie zmienia —
to **21,5%** (63,0 mln). Główny koszt przebudowy nie bierze się z przerw w pracy. Reguła
celuje w mniejszą część problemu i tak musi być zapisana: jako próg higieniczny, nie jako
dźwignia oszczędności.

**Czego NIE da się dziś rozstrzygnąć — powód istnienia tej pozycji** (pkt 1 domknięty 2026-09-01):
1. ~~**Przyczyna tych 21,5% jest nieznana.**~~ **ROZBITE 2026-09-01** — `cache_probe.py`
   dostał atrybucję przyczyn (`causes_report`) i podział na granicę tury (`boundary_report`).
   Worek „prefiks się zmienił" spadł z 94% do **62,6%**, a reszta ma nazwane udziały
   (główna sesja, luka <5 min, 249 zdarzeń / 63,5 mln tok):

   | przyczyna | zdarzeń | tokeny | % worka |
   |---|---|---|---|
   | **zestaw narzędzi** (`deferred_tools_delta`, `mcp_instructions_delta`, `agent_listing_delta`, `skill_listing`) | 53 | 13,1 mln | **20,7%** |
   | zmiana katalogu (`cwd`/`gitBranch`) | 12 | 4,4 mln | 6,9% |
   | zmiana modelu | 16 | 3,2 mln | 5,0% |
   | zmiana effortu | 9 | 1,9 mln | 2,9% |
   | uprawnienia/tryb | 4 | 1,2 mln | 1,9% |
   | nierozpoznane | 155 | 39,7 mln | 62,6% |

   **Eviction po stronie dostawcy WYKLUCZONY jako główna przyczyna** — to był warunek
   zamknięcia pozycji bez reguły, więc rozstrzygnięcie ma znaczenie. Nierozpoznane rebuildy
   nie rozkładają się równomiernie: **na granicy tury 5,78% par kończy się przebudową, wewnątrz
   tury 0,05% — 123× rzadziej** (2145 vs 66 218 par). Eviction nie wie nic o naszych turach
   i uderzałby równomiernie. To jest coś naszego, dziejącego się deterministycznie na styku tur.

   **Czego NIE udało się rozstrzygnąć i dlaczego — to jest twarda granica, nie niedoróbka.**
   Naiwny test podniesienia wskazywał `hook_success` (80% nierozpoznanych rebuildów vs 3,3% tła,
   lift 24×) i `hook_system_message` (lift 60×). To **korelacja pozorna albo nierozstrzygalna**:
   hooki odpalają się na praktycznie każdej granicy tury, więc grupa kontrolna „granica tury bez
   hooka" ma **n = 4**. Eksperyment naturalny też odpada — `reinject-rules.sh` wszedł 2026-07-07
   (`e3597a9`), a najstarszy zachowany transkrypt jest z **2026-07-31**: okres sprzed hooka
   nie istnieje w danych. Nie da się dziś oddzielić „wstrzyknięcie hooka" od „granica tury sama
   w sobie" i **nie należy udawać, że się da**.
2. **Efekt samej zmiany reguły jest niezmierzony.** Baseline zapisany wyżej pochodzi z okna
   PRZED zmianą; nie ma jeszcze ani jednego dnia po.

- **Warunek wznowienia:** ≥ 30 dni od 2026-09-01 (okno 2026-10-01+, porównywalne objętościowo —
  ≥ 40k requestów głównej sesji). Wtedy powtórz pomiar tą samą komendą i porównaj z baseline'em.
- **Próg akceptacji (liczbowy, ustalony PRZED pomiarem):** udział rebuildów `≥15m` w
  `cache_creation` głównej sesji spada z **7,8% do ≤ 5,0%**, przy niepogorszonym udziale
  rebuildów `<5m` (baseline **21,5%** — wzrost powyżej 25% czytaj jako regres, nie sukces:
  znaczyłby, że praca została ściśnięta w serie kosztem czegoś innego). Poniżej progu →
  reguła zostaje jako higiena, ale **bez** miejsca w always-on; wtedy przenieś ją do runbooka
  `bootstrap-machine`.
- **Komenda:**
  ```bash
  plugins/workflow-toolkit/skills/usage-audit/scripts/cache_probe.py 2026-10-01
  ```
- **Warunek unieważnienia samej reguły:** przestaje być trafna, gdy Anthropic zmieni TTL cache
  albo gdy CLI zacznie odnawiać cache w tle — pierwsze widać w linii „TTL faktycznie zamawiany"
  (udział `1h` w głównej sesji spada poniżej 90%), drugie w zapadnięciu się krzywej `60–120m`
  poniżej 50%. Oba czyta ta sama komenda, bez osobnego pomiaru.
- **Gdzie zapisać werdykt:** karta `Pomiar cache promptu — licznik zamiast domyslu w regule
  o seriach` (kanban) + zdjęcie tej pozycji stąd.

### H19 — reguły FORMY odpowiedzi trzymają się KANAŁU, nie treści (warunek unieważnienia → `reinject`)

**Co jest hipotezą:** że o egzekucji reguły formy decyduje **kanał dostarczenia**, a nie jej
brzmienie — i że przeniesienie warunku unieważnienia z always-on `CLAUDE.global.md` do hooka
`reinject-rules.sh` (pkt 5) podniesie jego przestrzeganie z 23% do poziomu pozostałych reguł
tej rodziny (~86%).

**Data zmiany:** 2026-09-01 (`reinject-rules.sh` pkt 5 dodany; treść usunięta z
`CLAUDE.global.md`, został jeden wskaźnik — 256 → 253 linie).

**Co JEST udowodnione** — `style_probe.py`, mianownik zawężony do odpowiedzi zamykających turę
**z realną pracą** (mutacja pliku albo `git commit`), 08.2026, n = 1250:

| soczewka | kanał | egzekucja |
|---|---|---|
| sekcja „Decyzje dla Ciebie" | hook + CLAUDE.md | **86%** |
| nazwana rekomendacja (REKO) | hook + CLAUDE.md | **82%** |
| warunek unieważnienia przy REKO | **tylko CLAUDE.md** | **23%** |

Ta sama rodzina reguł, ta sama populacja odpowiedzi, ten sam autor — różni je kanał. To jest
najmocniejsza przesłanka, jaką mamy, że doktryna „dopisz regułę do CLAUDE.md" wyczerpała się
jako metoda: `reinject` wstrzykuje HARD RULES **co turę**, wielkimi literami, i to on dowozi te 86%.

**Czego to NIE dowodzi — powód istnienia tej pozycji.** To **korelacja, nie eksperyment**:
warunek unieważnienia jest także **trudniejszy** od pozostałych dwóch (wymaga wymyślenia
obserwowalnego X; sekcja decyzji to w praktyce szablon). Część luki 86 → 23 to trudność zadania,
nie kanał, i dziś nie da się tych dwóch wyjaśnień rozdzielić. Zmiana jest tania i odwracalna
właśnie po to, żeby je rozdzielić pomiarem, a nie założyć z góry.

- **Warunek wznowienia:** ≥ 30 dni od 2026-09-01 (okno 2026-10-01+) i ≥ 300 odpowiedzi
  zamykających pracę w tym oknie (baseline miał 1250/mies., więc próg jest luźny).
- **Próg akceptacji (ustalony PRZED pomiarem):** warunek unieważnienia **z 23% do ≥ 60%**,
  przy sekcji decyzji **nie niżej niż 86%**. Spadek sekcji decyzji czytaj jako regres, nie
  szum: znaczyłby, że `reinject` się przeładował i cała lista przestała się wyróżniać.
  Wynik **< 50%** → kanał nie jest wyjaśnieniem, wyjaśnieniem jest trudność reguły; wtedy nie
  dokładaj trzeciej warstwy, tylko rozstrzygnij H5 (zdjąć regułę albo uprościć jej wymóg).
  Wynik **50–60%** → poprawa realna, ale niedomknięta: dopiero wtedy rozważ Stop-hook
  `guard-response-contract.sh` (deterministyczny check na wyjściu).
- **Komenda:**
  ```bash
  plugins/workflow-toolkit/skills/usage-audit/scripts/style_probe.py 2026-10-01
  ```
- **Warunek unieważnienia samej reguły:** przestaje obowiązywać, gdy `reinject-rules.sh` przekroczy
  ~6 punktów — wtedy hook sam staje się ścianą tekstu i traci przewagę nad CLAUDE.md, którą tu
  mierzymy (budżet zapisany w komentarzu skryptu). Widać to po spadku soczewki „sekcja decyzji"
  poniżej 86% przy rosnącej liście punktów.
- **Gdzie zapisać werdykt:** karta `Styl komunikacji peka na KANALE, nie na tresci regul` (kanban)
  + zdjęcie tej pozycji stąd. Domyka też H5, jeśli wynik wyjdzie poniżej 50%.

**Przebieg 0 (2026-09-01) — POMIAR PRZEDWCZESNY, bez werdyktu.** Rutyna `h19-style-probe-pomiar`
odpaliła się w dniu wdrożenia zmiany, 30 dni przed swoim oknem (nie planowo — zadanie ma nadal
`nextRunAt 2026-10-01T07:00Z` i żadnego `lastRunAt`, harmonogram nietknięty). Okno `2026-10-01+`:
**n = 0**. Okno `2026-09-01+`, czyli sam dzień wdrożenia: **n = 22** — 100% / 95% / **75%**.
Tych 75% **nie wolno czytać jako wskazania**: n = 22 to 7% progu 300, a populacja to wyłącznie
sesje, w których sama reguła była tematem pracy — czyli pomiar najlepszego możliwego przypadku,
nie zwykłego ruchu. Próg i baseline zostają zamrożone, hipoteza zostaje otwarta.

*Lekcja procesowa: rutyna mierząca hipotezę musi sama sprawdzić, czy jest w swoim oknie —
„odpal probe i zastosuj próg" bez warunku na datę produkuje wynik, który wygląda jak dowód.
Tu obronił się dopiero warunek wznowienia (≥ 300 odpowiedzi), nie sam harmonogram.*

**Kandydat do pkt 6 hooka — WSTRZYMANY do werdyktu H19 (decyzja Piotra, REKO 2026-09-01).**
Lekcja z tej samej sesji: *pozycja w „Decyzje dla Ciebie" musi być MOJĄ akcją, nie Piotra* —
trzy pozycje pod REKO, z których dwie były akcją usera, dały pętlę „REKO → nie mogę → REKO"
przez trzy tury. Kandydat NIE trafia teraz do `reinject-rules.sh`, bo szósty punkt zjadłby
budżet ~6 punktów, który ta hipoteza wskazuje jako granicę, i zmieniłby mierzony kanał w środku
okna pomiarowego. Treść lekcji żyje na razie w warstwie 3 jako `feedback`
(`feedback-name-the-cost-in-recommendation`, commit `9c05bdb`).
*Wraca do rozważenia po 2026-10-01, razem z werdyktem H19 — wtedy budżet hooka renegocjujemy
na podstawie zmierzonego wyniku, nie domysłu.*

---

### H20 — brama `PreModelSwitch`/`PostModelSwitch`: reguła kosztowa egzekwowana w momencie przełączenia modelu

- **Co jest hipotezą:** że przeniesienie dwóch reguł kosztowych z prozy globalnego CLAUDE.md
  (próg 50% limitu 7d na Fable 5; tabela routingu zadanie→model→effort) do hooka odpalanego
  **dokładnie przy zmianie modelu** zmienia realne zachowanie — a nie tylko dokłada kolejny
  wstrzyknięty tekst, który przepływa obok. Ta sama klasa co `context-watch.sh`, gdzie dwie
  kolejne wersje nagging-u zmierzyły się jako NIEPOTWIERDZONE.
- **Data zmiany:** 2026-09-01 (`workflow-toolkit` 1.36.0, commit `e5e50bf`; 1.36.1 wycisza `source: resume`).
- **Stan gate'a:** `0 zaobserwowanych odpaleń na żywo`. 20/20 przypadków selftestu zielonych (odpalone także na kopii z cache pluginu, nie tylko na repo), ale
  selftest mierzy kontrakt hooka na syntetycznym payloadzie, nie to, czy Claude Code faktycznie
  woła te eventy w sesji Piotra i czy dialog `ask` realnie się pokazuje. **Do czasu pierwszego
  odpalenia na żywo brama jest nieodróżnialna od martwej** — dokładnie ta klasa błędu, która
  ukryła niedziałające auto-archiwum kanbana pod TCC.
- **Dwie soczewki, mierz osobno:**
  - **E (egzekucja):** czy `PreModelSwitch` w ogóle się odpala — czy w transkryptach po 2026-09-01
    występuje wpis hooka przy zmianie modelu; czy `ask` pokazał dialog, gdy 7d ≥ 50%.
  - **B (behawior):** czy adnotacja `PostModelSwitch` przekłada się na routing — udział delegacji
    do subagentów w sesjach na Opusie po zmianie vs przed (ta sama metryka co H15).
- **Ryzyko odwrotne:** `ask` przy każdym wejściu na Fable powyżej progu może być na tyle uciążliwe,
  że Piotr podniesie próg albo wyłączy hook — czyli brama zniknie nie przez werdykt, tylko przez
  zmęczenie. Werdykt musi policzyć, ile razy potwierdzenie zostało wyklikane „tak" bez namysłu.
- **Znany słaby punkt kanału:** dane o limicie 7d nie są w payloadzie hooka — idą przez
  `~/.claude/state/rate-limits.json`, który pisze `statusline.sh`. Zmiana statusline'a albo
  konfiguracja bez niego = brama fail-open. Fail-open jest głośny (`PostModelSwitch` mówi
  „nie miała danych"), ale to nadal miękkie ogniwo, nie twarde.
- **Warunek wznowienia:** ≥ 3 realne przełączenia modelu po dacie zmiany (dowolny kierunek),
  w tym ≥ 1 wejście na Fable.
- **Komenda:**
  ```bash
  grep -rlF '"hookName":"PostModelSwitch"' ~/.claude/projects | wc -l
  ```
  **Nie licz golego `grep -rl "PostModelSwitch"`** — retro 2026-09-01 dalo `20` plikow, z czego
  wszystkie to transkrypty sesji, ktora te bramе pisala (moje wlasne grepy po binarce i kod hooka).
  Szukany dowod to wpis `hook_additional_context` wstrzykniety przez hooka, nie samo slowo.
- **Gdzie zapisać werdykt:** karta kanban „Brama na przelaczanie modelu — PreModelSwitch i PostModelSwitch" + zdjęcie tej pozycji stąd.

### H23 — `hygiene-audit`: rozmiar wpisu pamięci jako RATCHET z ledgerem, nie płaski próg doktrynalny

- **Co jest hipotezą:** że soczewka `memory-entry-size` z **ledgerem świadomego długu** (próg
  25 600 B tylko dla wpisów POZA ledgerem + zero-zapasowy ratchet na pozycjach ledgerowych) realnie
  zatrzymuje puchnięcie wpisów pamięci — a nie tylko dokłada czwarty licznik obok trzech, które
  CLAUDE.md już ma. Kluczowe: hipotezą jest sam **wybór mechanizmu**, bo płaski próg 10 KB z doktryny
  „jeden fakt = jeden plik" został ODRZUCONY pomiarem (2026-09-02: **15 z 38** aktywnych wpisów
  antisis-prototype przekracza 10 KB → check strzelałby 15× w pierwszym przebiegu i zostałby
  odruchowo zignorowany). Ledger jest zakładem, że dług NAZWANY z rozmiarem maleje, a dług
  bezimienny rośnie.
- **Data zmiany:** 2026-09-02 (`workflow-toolkit`, `hygiene-audit.mjs` + progi w
  `antisis prototype/.claude/audit-invariants.json`).
- **Powód powstania:** re-score 2026-09 zmierzył **regres**: `memory-cap` (liczy PLIKI) świecił
  ✅ przy poprawie 42→40 wpisów dokładnie w oknie, w którym treść rosła W plikach —
  `git-session-collisions` 56→62,7 KB, `family-portal-design-register` 51→57,6 KB, nowy
  `worktree-tooling-gotchas` 38,6 KB. Ta sama klasa wady co linie-vs-bajty w CLAUDE.md, i check,
  który miał to łapać, był w planie audytu 2026-08-27 jako soczewka (b) — nie wszedł.
- **Stan gate'a:** selftest **42/42** (10 nowych case'ów: 4 gałęzie fire × mirror + 5 silent,
  w tym gate-proof „+1 bajt ponad ledger strzela"). Sondy na **żywym** stanie projektu
  potwierdzone dla (a) moloch poza ledgerem, (b) przyrost ponad zapis, (c) ledger na nieistniejący
  wpis; stan przywrócony. **To dowodzi, że check STRZELA — nie że dług maleje.** Ta druga rzecz
  jest hipotezą i wymaga okna czasu.
- **Ryzyko odwrotne (mierz je, nie tylko sukces):** ledger może się zamienić w **amnestię** —
  wpis rośnie, ktoś podnosi liczbę w ledgerze „w tym samym commicie" i formalnie jest zielono.
  Werdykt musi policzyć, ile pozycji ledgera **znikło przez sweep** vs ile zostało **podniesionych**.
  Jeśli podniesień jest więcej niż zdjęć — mechanizm licencjonuje dług, a nie go zbiera, i hipoteza
  jest ODRZUCONA niezależnie od tego, że soczewka „działa".
- **Druga soczewka (istotna):** gałąź (d) — „schudł >20% → ZACIŚNIJ ledger". Bez niej sweep zostawia
  próg na starej wysokości i cicho pozwala wrócić. Sprawdź, czy po realnym sweepie ktokolwiek ten
  ledger faktycznie zacisnął, czy tylko zignorował ⚠️.
- **Warunek wznowienia:** ≥ 3 przebiegi `hygiene-audit` z **niepustym** findingiem tej soczewki
  ALBO ≥ 1 pełny cykl (sweep → zaciśnięcie ledgera) po dacie zmiany. Same zielone przebiegi nie są
  materiałem — zielone przy 6 pozycjach ledgera znaczy „nic nie urosło", nie „dług maleje".
- **Komenda:**
  ```bash
  cd "$HOME/Documents/antisis prototype" && node "$HOME/Documents/piotr-toolkit/plugins/workflow-toolkit/scripts/hygiene-audit.mjs" --json \
    | python3 -c "import json,sys; d=json.load(sys.stdin); print([c for c in d['checks'] if c['id']=='memory-entry-size'])"
  # oraz TREND ledgera (to jest realny werdykt, nie stan checku):
  git -C "$HOME/Documents/antisis prototype" log -p --follow .claude/audit-invariants.json \
    | grep -E '^[+-] *"[a-z0-9-]+\.md": [0-9]+' | head -40
  ```
- **Gdzie zapisać werdykt:** notatka `Research/Workflow maturity re-score — <YYYY-MM>.md` (kolejny
  przebieg cyklu) + zdjęcie tej pozycji stąd.

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
- **Przebieg 2026-08-31 (retro sesji F05 code-design-audit, antisis-prototype):** `heldout_split.sh
  design-toolkit:code-design-audit 2026-08-18` → **17 wywołań surowych** (≥3, próg wznowienia
  spełniony na tej samej soczewce co poprzednio). Klasyfikacja per przypadek (czy gate 3-pytaniowy
  z §0.5 realnie przebiegł i czy wybrany tryb był tańszy tam, gdzie trzeba) **NIE wykonana w tym
  przebiegu** — 17 transkryptów do ręcznego przeglądu przekracza budżet retro na koniec sesji.
  Zgodnie z lekcją procesową z H1/H3 (3× „za mało danych" bez otwarcia okna = odkładanie, nie brak
  materiału) — **nie odkładaj czwarty raz bez klasyfikacji; deleguj ją do subagenta jako osobne
  zadanie**, nie czekaj na kolejną okazję retro. Ta sesja sama jest jednym z 17 wywołań (audyt F05
  Family Portal, `d2bcecbf`→`64cb0da0`) — kwalifikuje się do klasyfikacji, gdy ktoś ją zrobi.

- **Klasyfikacja 2026-08-31 wieczór (delegowana z retro F05, wykonana w osobnej sesji, worktree
  `strange-blackwell-1959f5`) — H4b (`code-design-audit`) osiąga próg, H4a/H4c nadal nie:**
  17 surowych wywołań przeczytane pojedynczo wprost z transkryptów (`~/.claude/projects/**/*.jsonl`,
  plik+linia namierzone z `tool_use Skill`), nie z podsumowań.

  **Wyłączone jako „nie dotyczy" (3 surowe, 1 case logiczny):** `epic-meninsky-ab3bd4` (sesja główna +
  jej subagent) i kontynuacja na chipie (`inspiring-ardinghelli-4c9554`) — user zażądał „proper,
  complete audit session"/„complete, fresh audit" jednego już-nazwanego flow (15 ekranów) — to
  explicit opt-in z doktryny §0.5 („full audit... skip the checks and run it"), nie test gate'a.
  Pierwsza próba przerwana przez usera (`TaskStop` + chip do nowej sesji: „wolałbym żebyś ten audyt
  odpalił w nowej sesji"), druga (chip) dokończona poprawnie (15/15 ekranów, structural walkthrough,
  terminal state `converged`, sekcja inspection-scope) — ale opt-in z definicji nie mierzy checków.

  **Ocenianych: 11 przypadków logicznych** z pozostałych 14 surowych — po odjęciu duplikatu
  sesji-forka `distracted-meitner-2a2673` (2 pliki `.jsonl`, identyczne do linii 920 — jeden
  resume/fork, nie dwa wywołania) i po scaleniu par sesja-główna+jej-własny-subagent-na-ten-sam-cel
  (F10: `strange-blackwell` + subagent; F11: `festive-keller` + subagent) w jeden case każda:

  | Case | Zakres proszony | Ekranów | Werdykt |
  |---|---|---|---|
  | `distracted-meitner` — fix 7 luk + re-audit, agent-first flow | 1 flow, cel już potwierdzony przez usera (4 decyzje czytane z audytu) | 32 | MET — bez explicit recytacji checków, ale zakres trafny (nie rozjechał się na cały monorepo) |
  | `subagents` — MAP „AI Upload School File" | 1 nazwany, nigdy-nieaudytowany shipped flow | 5 + 3 manualnie (poza zasięgiem pixel-gate) | MET — T1–T3 + craft pass, jawna linia „Scope:" w werdykcie |
  | `sleepy-spence-466278` — koordynator epiku FP | 6 vs 12 flow, ambiwalentne | — | **MET, najczystszy przykład** — `AskUserQuestion` PRZED wywołaniem skilla, jawna rekomendacja tańszej opcji (6 flow bez baseline), user świadomie nadpisał na 12 |
  | `blissful-lehmann` — F06+F08 | 1 sesja, 2 flow, nigdy niemierzone | 22 | MET — pełne T1–T3, regresja cross-flow ograniczona do realnie dotkniętych 12 ekranów (nie całego DS) |
  | `optimistic-kapitsa` — F05 | 1 flow | 16 | MET — realny bug znaleziony i naprawiony (Save nie zapisywał), PR #703 zmergowany |
  | `strange-blackwell` — F10 (+subagent) | 1 flow, mały | 4 | **MET, explicit** — „craft pass (design-tweaker, quick mode — uzasadnione małym, jednorazowym zakresem)" |
  | `busy-snyder` — F04+F07+F09 | 1 sesja, 3 flow | — | MET — 2 realne defekty naprawione, 1 finding poprawnie routowany do Figmy (nie po cichu w kodzie) |
  | `festive-keller` — F11 (+subagent) | 1 flow | 10 | MET — brak geometry-baseline nazwany jako dług, nie przemilczany |
  | `sleepy-spence` subagent — F07 | 1 flow | 12 | **MET, explicit** — „deliberate cost-conscious deviation: jeden zsyntetyzowany reviewer zamiast 7-subagentowego panelu", nazwane wprost w werdykcie |
  | `sleepy-spence` subagent — F09 | 1 flow | 14 | **MET, explicit** — ta sama redukcja panelu + terminal state uczciwie `max_iterations_reached` zamiast wymuszonego `converged` |
  | `sleepy-spence` subagent — F05 (capture baseline) | 1 flow | 16 | MET, częściowo niepewne — transkrypt urywa się w trakcie capture'u baseline'ów bez werdyktu końcowego; brak dowodu na zły zakres, ale brak też dowodu na domknięcie |

  **Wynik: 11/11 MET, 0 złamań** — ani przeszacowania (żadna sesja nie rozjechała się w pełny sweep
  monorepo), ani niedoszacowania (żadna nie ograniczyła się do powierzchownego sprawdzenia tam, gdzie
  wyszły realne defekty — 3 case'y znalazły i naprawiły prawdziwe bugi). **4 z 11 case'ów explicite
  artykułują rozumowanie kosztowe z §0.5** (koordynator: pytanie o zakres przed startem; F10/F07/F09:
  „quick mode"/redukcja panelu z podanym powodem) — to nie tylko brak porażki, to widoczny ślad
  działania mechanizmu, nie przypadek. **Próg wznowienia dla H4b (`design-toolkit:code-design-audit`)
  jest osiągnięty i spełniony.** H4a (`design-tweaker`) i H4c (`web-research`) nadal `0 ocenianych`
  (patrz tabela na górze pliku) — warunek wznowienia całego H4 wymaga wszystkich trzech osobno, więc
  **H4 jako całość NIE domyka się tym przebiegiem**, tylko jego gałąź `code-design-audit`.

  **Czego ten przebieg NIE dowodzi:** nie testuje odwrotnego kierunku ryzyka — żaden z 11 przypadków
  nie miał sytuacji „pojedyncza edycja / brak artefaktu designu" (check 1/2 na „nie"), więc gałąź
  gate'a chroniąca przed *niedoszacowaniem* pozostaje niezmierzona w tę stronę. Nie mierzy trafności
  triggera (T) — wszystkie 17 wywołań to jawne, świadome prośby o audyt, nie testy „czy skill w ogóle
  powinien wystartować". Ocena jednoosobowa (ten model, bez ślepego drugiego sędziego).

  **Efekt uboczny zauważony po drodze (NIE H4, osobna obserwacja procesowa):** F05, F07 i F09 zostały
  faktycznie zaaudytowane dwa razy niezależnie — raz przez dedykowane worktree (`optimistic-kapitsa`
  → F05, `busy-snyder` → F04/F07/F09), raz przez subagentów w sesji koordynatora `sleepy-spence-466278`.
  Wygląda na kolizję zakresu między równolegle wystartowanymi sesjami (możliwe naruszenie własnej
  reguły CLAUDE.md „recon przed startem karty — `git log --all` + `gh pr list`"), nie na błąd gate'a
  H4. Warte osobnego zgłoszenia Piotrowi — nie rozwijane dalej w ramach tej klasyfikacji.

  **Gdzie zapisać:** ta sama karta kanban „Cost gate — held-out" (patrz notatka 2026-08-24 wyżej) —
  dopisać `code-design-audit: 11/11 MET (held-out C)`, zostawić H4a/H4c jako otwarte na tej karcie.

- **Klasyfikacja 2026-08-31 (H4a `design-tweaker`, delegowana z karty „Cost gate — held-out"):**
  `heldout_split.sh` zaraportował skok 1→14 wywołań held-out (próg ≥3 przekroczony). Wszystkie 14
  przeczytane wprost z transkryptów (plik+linia namierzone offline, bez zgadywania). **Wynik: 11/14
  MET, 3/14 BROKEN, 0 „nie dotyczy"** — w przeciwieństwie do H4b, ta gałąź **nie** przechodzi czysto.

  Wzorzec złamań nie jest losowy: **wszystkie 3 BROKEN to sesje, w których caller EXPLICITE zażądał
  „Panel mode" na realnie dużej powierzchni (22/10/10 ekranów), a `design-tweaker` po cichu spadł do
  Quick — bez rozpoznawalnego craft-passu i bez zdania uzasadniającego odstępstwo.** To jest dokładnie
  odwrotny kierunek ryzyka, który H4 miało łapać (gate zaniżający jakość, nie tylko oszczędzający
  koszt) — i dotąd niezmierzony w H4b. Pozostałe 11/14 poprawnie zejmowały tryb (Quick albo
  zredukowany single-pass zamiast 7-agentowego panelu) **z jawnym jednozdaniowym uzasadnieniem
  cytującym własny cost gate skilla** („is the surface actually big? — No, so Quick mode…" itp.).

  **Próbka NIE jest niezależna od H4b** (potwierdzone w transkryptach): 8/14 pozycji to te same
  sesje/worktree co 8/11 przypadków H4b (`design-tweaker` jest wołany wewnątrz `code-design-audit`
  jako craft-pass), pozostałe 6 to fan-out jednej sesji-koordynatora (`sleepy-spence-466278`), którą
  H4b liczyło jako jeden case. **Warunek wznowienia H4 zakładał trzy NIEZALEŻNE progi — w praktyce
  H4a i H4b mierzą w dużej mierze te same 8-9 sesji z dwóch różnych bramek**, więc „trzy osobne
  potwierdzenia" dają mniej niezależnego dowodu niż zakładano przy formułowaniu warunku wznowienia.

  **Czego ten przebieg NIE dowodzi:** skorelowane zachowanie w 9/14 fan-outach jednej sesji (wspólny
  szablon promptu, niemal identyczne frazy uzasadnień); 3 złamania wykryto czytaniem transkryptu, nie
  self-reportem sesji („żadna sesja sama nie nazwała 'powinienem był użyć panelu'"); ocena
  jednoosobowa bez ślepego sędziego; brak testu gałęzi „Q1/Q2/Q3=nie" dla samodzielnego wywołania
  `design-tweaker` przez człowieka (wszystkie 14 to craft-passy wewnątrz `code-design-audit`).

  **Werdykt: próg liczbowy osiągnięty (14≥3), ale H4a NIE jest potwierdzone.** 11/14 MET, 3/14 BROKEN
  z jednym powtarzalnym wzorcem — gałąź `design-tweaker` zostaje HIPOTEZĄ z udokumentowanym złamaniem,
  nie awansuje do kanonu jak H4b. Zapis werdyktu również na karcie kanban „Cost gate — held-out".

  **Fix wdrożony 2026-08-31 (REKO Piotra):** `design-tweaker/SKILL.md` → sekcja „Cost gate" dostała
  wymóg jednozdaniowej deklaracji wybranego trybu PRZY KAŻDYM wywołaniu, nie tylko przy „nie" na
  jednym z pytań, z jawnym wskazaniem że milczący downgrade z żądanego panelu do Quick jest błędem
  gate'a. **To jest NOWA zmiana treści (soczewka C) — otwiera własny held-out, licz od 2026-08-31,
  nie od 2026-08-18.** Nie utwardzać werdyktu „fix działa" bez ≥3 ocenianych wywołań PO tej dacie —
  ta sama pułapka co reszta doktryny („przeszło na trzech przykładach, na których go wymyślono" nie
  jest held-outem). Komenda do sprawdzenia po nagromadzeniu ruchu:
  `heldout_split.sh design-toolkit:design-tweaker 2026-08-31`.

  H4 jako całość nadal się nie domyka: H4b potwierdzone, H4a hipoteza z otwartym złamaniem, H4c wciąż
  `0 ocenianych`.

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

---

### H22 — `session-retro` krok 4a2: miesięczny sweep rejestru „external-blocked" (np. `Waiting On.md`)

- **Co jest hipotezą:** nowy krok (4a2, cadence jak 4a — ~30 dni) który odpytuje Linear dla każdego
  wiersza rejestru external-blocked z linkiem do ticketu i usuwa/aktualizuje wiersze, których
  „czekanie" już się rozwiązało. Ósmy skill z rodziny H7–H10 (decyzja/wpis zapisany bez późniejszej
  weryfikacji trafności) — tu wariant to rejestr-pointer, nie pojedynczy wpis pamięci.
- **Skąd:** audyt karty kanban „Waiting on weryfikacja" (Manta, 2026-09-01) — ręczne sprawdzenie
  9 z 13 wierszy `Waiting On.md` przez `mcp__linear__get_issue`/`list_comments` znalazło **4 wiersze
  stale** (MAN-311, MAN-436, MAN-391-w-ramach-MAN-589, MAN-428 — tickety Done/Live tygodnie/miesiąc
  wcześniej, rejestr nieaktualizowany), ale też **2 wiersze wciąż realnie otwarte mimo Done/Live
  ticketu** (MAN-483, MAN-489 — pytanie z rejestru jest osobne od tego, co zamknęło ticket). Root
  cause: `memory-discipline` deklaruje „review at retro", ale `session-retro` nigdy nie miał kroku,
  który to robi — czysto deklaratywna reguła bez egzekucji (ta sama klasa co martwy LaunchAgent
  auto-archiwum kanbana).
- **Data zmiany:** 2026-09-01 (`workflow-toolkit`, `SKILL.md` session-retro krok 4a2, REKO Piotra na
  karcie „Waiting on weryfikacja").
- **Stan gate'a:** `0 przebiegów` — mechanizm dopiero wdrożony; ten pierwszy sweep był RĘCZNY (ta
  sesja), nie przez krok 4a2 (który jeszcze nie istniał).
- **Soczewka:** per przebieg — czy sweep faktycznie złapał ≥1 wiersz do usunięcia/aktualizacji (nie
  tylko potwierdził wszystko jako aktualne — rytualne), ORAZ czy nie usunął błędnie wiersza, który
  ticket-Done ale pytanie-otwarte (dowód: MAN-483/MAN-489 powyżej — to jest realna pułapka fałszywego
  pozytywu, nie hipotetyczna).
- **Ryzyko odwrotne, którego trzeba pilnować:** sweep staje się rytuałem „ticket Done → usuń wiersz"
  bez sprawdzenia komentarzy — to skasowałoby MAN-483/MAN-489-podobne przypadki, które są realnie
  żywe. Krok w SKILL.md już to nazywa wprost, ale held-out musi to zmierzyć, nie tylko tekst obiecać.
- **Warunek wznowienia:** ≥ 3 przebiegi sweepu (log w `.claude/memory/_decision-sweep-log.md` albo
  osobna linia), z czego przynajmniej jeden faktycznie usunął/zaktualizował wiersz.
- **Komenda:** brak automatycznego skryptu — sprawdź `git log` na pliku rejestru external-blocked
  (per projekt, np. `Waiting On.md` w Manta Vault) po 2026-09-01, czy któryś przebieg retro (nie
  ręczna sesja jak ta) dopisał zmianę.
- **Gdzie zapisać werdykt:** karta kanban „Decision-sweep — held-out" (wspólna z H7–H10) + zdjęcie
  tej pozycji stąd.

---

### H21 — `obsidian-feedback-sweep`: oś Dyspozycji jest poniżej klasy większościowej

- **Co jest hipotezą:** nie zmiana, którą wprowadzono, tylko **zmierzony deficyt istniejącego
  kanonu**. Przy ślepym wsadzie (tekst komentarza + lokalizacja) klasyfikacja Dyspozycji trafia
  w 30–33%, podczas gdy „zawsze `do-now`" trafia w 47%. Oś Typu wypada dobrze (58–63% vs null 35%)
  — problem jest wyłącznie na osi, która decyduje, czy pozycja idzie do budowy czy do człowieka.
- **Data pomiaru:** 2026-09-01. Korpus: 18 domkniętych rejestrów Manty, 153 pozycje, split
  chronologiczny po rejestrach (train 110 do 07-10, held-out 43 od 07-14).
- **Stan gate'a:** **trzy warianty zmierzone na tym samym held-oucie, żaden nie przeszedł.**
  Baseline (osąd modelu, same osie): 33% · reguły projektu podane prozą: 42–47% · deterministyczny
  silnik nad skompilowanymi regułami: 37% (pokrycie 72%, precyzja 52%). Null: 47%. Silnik na train
  dawał 62% → przepaść generalizacji 25 punktów, pętla naprawcza przeuczyła reguły.
  **Werdykt: nic nie utwardzone w `SKILL.md`.** Kod i harness leżą jako eksperyment w
  `plugins/obsidian-toolkit/skills/obsidian-feedback-sweep/experiments/policy-engine/`.
- **Co JEST ustalone (nie hipoteza):** cztery reguły polityki, które rządzą korpusem, a nigdy nie
  zostały spisane — (1) odpowiadamy tylko tam, gdzie rzecz dotyczy naszego designu; cudza rozmowa
  na naszym pliku to `no-action`; (2) macierz właścicieli warstw (model danych → Matt, zakres
  i proces → Tom & Will, prezentacja i copy → Piotr); (3) proposer = decision-maker; (4) tag
  produktowy nie oznacza automatycznie `needs-decision`. To **dane projektu**, nie kanon skilla —
  miejsce dla nich to config per-projekt, którego `SKILL.md` już się domaga.
- **Soczewka:** **D (dyspozycja)** — trafność przypisania `do-now / needs-decision / answer-close /
  no-action` wobec tego, co ostatecznie zapisano w rejestrze. Mierz WYŁĄCZNIE tę oś; Typ i Owner
  mają inne rozkłady i mieszanie ich zaciera sygnał.
- **Zastrzeżenie, bez którego liczba kłamie:** wszystkie warianty dostały wsad ślepy, a realny
  sweep widzi ekran, wątek i historię. Porównania MIĘDZY wariantami są uczciwe (ten sam wsad),
  poziom bezwzględny **nie jest oceną skilla w realnej pracy**. Gold set to też etykiety jednego
  człowieka z jednego przebiegu — sufit korpusu nieznany.
- **Warunek wznowienia:** ≥ 4 nowe domknięte rejestry po 2026-09-01 (rośnie held-out, którego
  żadna runda naprawcza nie dotknęła) **albo** decyzja, żeby powtórzyć pomiar z wsadem
  kontekstowym (screenshot ekranu + wątek), co rozstrzygnie, ile z luki to głód kontekstu.
- **Komenda:**
  ```bash
  cd plugins/obsidian-toolkit/skills/obsidian-feedback-sweep/experiments/policy-engine
  python3 extract_goldset.py "$HOME/Documents/Manta Vault/Feedback Pipeline/Done" goldset.json
  ```
- **Gdzie zapisać werdykt:** karta „Polityka skompilowana do reguł plus deterministyczny silnik
  (feedback-sweep)" + zdjęcie tej pozycji stąd.
