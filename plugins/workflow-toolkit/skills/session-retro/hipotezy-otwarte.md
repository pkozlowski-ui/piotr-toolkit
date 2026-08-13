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

## Zamknięte (zostawiaj krótki ślad, żeby nikt nie proponował tego drugi raz)

### Z1 — poszerzenie hooka `route-skills.sh` o intent „komentarz do Figmy" — ODRZUCONE 2026-08-13

`held-out T: 2/12 trafione, 9 fałszywych alarmów` (regex projektowany na dev-secie 1769 promptów,
mierzony ślepo na held-oucie 948). Warunek zerowego fałszywego alarmu złamany 9×; zaciśnięcie
kandydata schodzi do 2 ocenianych przypadków, czyli pod bramkę wielkości. Powód strukturalny
i zakaz powtarzania siedzą w komentarzu w `hooks/route-skills.sh` — wznowienie tylko z INNYM
kanałem niż proximity słów kluczowych.
