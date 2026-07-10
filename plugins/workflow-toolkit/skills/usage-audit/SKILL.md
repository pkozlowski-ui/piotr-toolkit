---
name: usage-audit
description: Audyt UŻYCIA skilli toolkitu na transkryptach sesji (~/.claude/projects) — adopcja per skill, trigger fidelity (co user pisał przed wywołaniem / missed triggery), martwe skille. Daje baseline metryki dla validation-gate i evals/. Uruchamia się gdy user mówi "audyt użycia skilli", "usage audit", "które skille działają", "audyt wykorzystania toolkitu".
---

# Skill: usage-audit

## Cel

Zmierzyć, jak skille toolkitu działają **w praktyce** (nie w plikach): co jest wywoływane,
co martwe, czy triggery łapią intent usera, czy wywołania kończą się dobrym rezultatem.
Wynik = **baseline metryki + hipotezy do validation-gate** (patrz `evals-convention.md`
w katalogu tego skilla obok — konwencja `evals/`), NIGDY automatyczne przepisywanie skilli.

## Warstwy audytu (rosnący koszt — zatrzymaj się, gdy user chce mniej)

1. **Adopcja** (deterministyczna, ~darmowa): `scripts/adoption_scan.sh [SINCE]` —
   liczniki wywołań Skill tool per skill + lista skilli toolkitu z zerem wywołań.
2. **Trigger fidelity** (deterministyczna): `scripts/skill_trigger_context.py "<plugin:skill>"` —
   ostatnia wiadomość usera przed każdym wywołaniem. Ocena: trigger organiczny / wymuszony
   z nazwy / false positive.
3. **Missed triggery** (subagent Sonnet): z frontmattera skilla wyprowadź 3–6 fraz-intentów
   (PL+EN), grep w wypowiedziach USERA, sprawdź okno — zadanie zrobione bez skilla?
4. **Outcome tracing** (subagent Sonnet): sample sesji po wywołaniu — błędy narzędzi, korekty
   usera („nie o to", „znowu", „popraw"), retry. To najdroższa i najcenniejsza warstwa.

## Twarde reguły wykonania

- **Transkrypty są wielkie (GB)** — NIGDY nie czytaj plików JSONL w całości; tylko grep /
  ekstrakcja skryptem + wąskie okna wokół trafień. Warstwy 3–4 deleguj do subagentów
  (Sonnet/medium) z tym samym zakazem.
- **Interpretacja liczników — pułapki:**
  - Skille **auto-behavioral** (mają działać bez wołania, np. coding-principles): licznik ich
    nie mierzy — 0× ≠ brak wartości. Sprawdzaj ślady zachowania, nie wywołania.
  - Skille **setup-type** (jednorazowe): 0× to stan oczekiwany.
  - Frazy triggera pojawiają się w system-reminderach z listą skilli w KAŻDEJ sesji —
    filtruj do realnych wypowiedzi usera, inaczej wszystko wygląda na „popyt".
- **Hierarchia egzekucji** (ustalona audytem 2026-07): egzekwują się rytuał usera > instrukcja
  serwera MCP > hook > jawne wywołanie z nazwy; sam opis triggera w SKILL.md NIE egzekwuje.
  Gdy finding = „skill się nie odpala", rekomendacją jest zmiana KANAŁU, nie dopisanie
  kolejnego zdania do description.
- **Wynik**: raport lokalny (np. `AUDIT-USAGE.local.md`, git-exclude) z werdyktami + tabelą
  hipotez (hipoteza / check / baseline). Każdy potwierdzony failure → kandydat na task
  w `skills/<skill>/evals/` wg `evals-convention.md`. Zmiany w skillach tylko przez
  validation-gate.

## Pętla ulepszania (kadencja i domknięcie cyklu)

Audyt nie jest jednorazowy — działa w pętli **zmierz → porównaj → utwardź/wycofaj → zmierz**:

1. **Kadencja: co ~2 tygodnie** (rytuał — karta na kanbanie, nie automat; rytuał usera to
   empirycznie najskuteczniejszy kanał egzekucji). Minimum 2 tyg. świeżych transkryptów po
   zmianach — wcześniejszy pomiar to szum, nie sygnał.
2. **Przebieg porównawczy:** odpal warstwy 1–2 (deterministyczne, ~darmowe) i porównaj wyniki
   z **tabelą baseline'ów z poprzedniego raportu** (`AUDIT-USAGE.local.md`). Warstwy 3–4
   (subagenty) tylko dla metryk, które się nie poprawiły, i nowych anomalii.
3. **Rozstrzygnięcia per hipoteza:**
   - poprawa vs baseline → fix trzyma; eval zostaje jako regresyjny strażnik,
   - brak zmiany / regres → hipoteza wraca do puli; następny fix **innym kanałem**
     (wyżej w hierarchii egzekucji), nie mocniejszym sformułowaniem tego samego,
   - nowa wpadka → nowy task w `evals/` + wiersz w tabeli baseline'ów.
4. **Zaktualizuj raport** (nowe baseline'y = punkt odniesienia następnego przebiegu).
5. **Saturacja = sygnał zdrowia:** gdy 2 kolejne przebiegi nie wnoszą nowych findingów,
   wydłuż kadencję (miesiąc+). Nie generuj sztucznych hipotez, żeby pętla „miała co robić".

- `scripts/adoption_scan.sh [SINCE=YYYY-MM-DD]` — env: `CLAUDE_PROJECTS` (default
  `~/.claude/projects`), `TOOLKIT_ROOT` (default `~/Documents/piotr-toolkit`).
- `scripts/skill_trigger_context.py "<plugin:skill>" [SINCE=YYYY-MM-DD] [roots...]` —
  bez SINCE bierze ostatnie 30 dni.
