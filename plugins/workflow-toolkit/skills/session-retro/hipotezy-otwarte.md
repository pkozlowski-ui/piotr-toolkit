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
