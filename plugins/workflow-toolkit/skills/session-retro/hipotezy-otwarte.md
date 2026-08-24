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
- **Stan gate'a:** `held-out C: 0 ocenianych przypadków, za mało danych` (przebieg 2026-08-13 —
  reguła powstała tego samego dnia, zero wywołań po zmianie).
- **Soczewka:** C (zmiana treści) — oceniaj per wymaganie na draftach, NIE per wywołanie.
- **Warunek wznowienia:** ≥ 3 przypadki OCENIANE, czyli drafty, które **niosą linki**. Draft bez
  linków to „nie dotyczy" i nie liczy się do bramki.
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
- **Stan gate'a:** eval case 001 przeszedł 0.80→0.90, rdzeń problemu (dosłowny zakazany wzorzec)
  zniknął w OBU runach re-runu — ale to jest ta sama, konieczna-nie-wystarczająca sytuacja co H2.
  **Uwaga:** resztkowy pojedynczy flake w re-runie (inna, węższa fraza „powiedz X, przepiszę
  sekcję" — niedotycząca wysyłki) potraktowany jako szum; jeśli held-out pokaże, że to się
  powtarza w realnych sesjach, może to być osobny, węższy finding, nie dowód że fix nie działa.
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
