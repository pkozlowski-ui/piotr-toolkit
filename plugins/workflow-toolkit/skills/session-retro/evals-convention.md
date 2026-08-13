# Konwencja `evals/` — taski specyfikacyjne skilli

> Wykonuje doktrynę validation-gate (SKILL.md → „Validation-gate"): „waliduj na przykładach
> nieużytych do wymyślenia zmiany". Ten plik definiuje, GDZIE te przykłady żyją i jak wyglądają.
>
> **Nazwa poprawiona 2026-08-13:** wcześniej ten plik nazywał się „zmaterializowany held-out",
> co było nieprawdą — task pisany z tej samej wpadki, która zrodziła poprawkę, jest specyfikacją
> i przechodzi z definicji. Held-out ma własny mechanizm: [`held-out-gate.md`](held-out-gate.md).
> Konwencja jest cross-plugin — dotyczy każdego skilla w każdym pluginie tego marketplace'u.
>
> Rodowód: Evaluation-Driven Development (Anthropic „Demystifying evals for AI agents", Hamel
> Husain „Evals FAQ") — zbiór tasków rośnie z REALNYCH wpadek, nie z syntetycznych pomysłów.
> Utwardzone po held-out checku na 3 historycznych wpadkach (2026-07-10, sesja EDD-research).

## Layout

```
plugins/<plugin>/skills/<skill>/evals/
  001-<slug>.md
  002-<slug>.md
```

Numeracja rosnąca, nigdy nie reużywaj numeru. Task wycofany dostaje `status: wycofany`
(nie kasuj — historia werdyktów to też dane).

## Schemat taska

```markdown
---
id: <skill>-NNN
skill: <nazwa skilla>
źródło: <retro YYYY-MM-DD / commit / realna sesja — skąd wzięła się wpadka>
status: aktywny | wycofany
---

# <Jedno zdanie: jakie zachowanie ten task testuje>

**Scenariusz (input):** <sytuacja/dane wejściowe; gdy potrzebny plik — ścieżka do fixture obok>
**Pass:** <co skill MUSI zrobić w tym scenariuszu — werdykt binarny, bez skali>
**Fail wygląda tak:** <antywzorzec, który realnie wystąpił>
**Jak sprawdzić:** <manualnie: odpal skill na scenariuszu / porównaj zachowanie z Pass>
```

Dobry task = dwóch niezależnych oceniających da ten sam werdykt pass/fail (Anthropic, krok 2).
Jeśli nie umiesz napisać jednoznacznego „Pass" — to materiał na wpis w pattern-library, nie eval.

## Cykl życia

1. **Retro → task.** Realna wpadka skilla/reguły w sesji → dopisz task (krok w `session-retro`).
2. **Zmiana skilla → run.** ZANIM utwardzisz zmianę w SKILL.md — przejdź `evals/` tego skilla
   i sprawdź, że nowa wersja nadal przechodzi wszystkie aktywne taski. Regres = nie utwardzaj.
   **To jest warunek konieczny, nie wystarczający:** taski tutaj pisała ta sama sesja, która wymyśliła
   poprawkę, więc przechodzą z definicji. Pytanie „czy nowa wersja jest LEPSZA od starej" rozstrzyga
   [`held-out-gate.md`](held-out-gate.md) — podział czasowy realnych wywołań
   (`usage-audit/scripts/heldout_split.sh`), a syntetyki dopiero gdy realnych jest za mało.
3. **Bump wersji pluginu** — gdy zmieniasz skill mający `evals/`, odnotuj w commit message
   wynik: `evals: N/N pass`.
4. **Saturacja** — gdy skill od dawna przechodzi wszystko i wpadek brak, to sygnał zdrowia,
   nie powód do generowania sztucznych tasków.

## Kiedy NIE dodawać taska

- **Wpadka jednorazowa / ludzka** (misclick, literówka w prompcie usera) — nie zachowanie skilla.
- **Pokryte deterministycznym checkiem** (hook, skrypt typu `hygiene-audit.mjs`, gate w repo
  projektu) — wtedy TEN check jest evalem; nie dubluj go w markdown.
- **Hipotetyczny scenariusz** („a co gdyby…") — tylko realne porażki; syntetyki dopiero gdy
  zbiór z życia ma dziury klasowe (i wtedy oznacz `źródło: syntetyczny`).
- **Duplikat** — istniejący task pokrywa zachowanie → ewentualnie doostrz jego „Pass".
