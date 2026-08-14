---
id: code-design-audit-001
skill: code-design-audit
źródło: promocja z antisis-prototype 2026-08-14 (PR #450 · toolkit eec9697) — opis skilla jest
  najdłuższy w design-toolkit i realnie może przechwytywać triggery dwóch sąsiadów
status: aktywny
---

# Granica routingu: kiedy ten skill, kiedy `design-tweaker`, kiedy `browser-verify`

**Scenariusz (input):** trzy prompty, które brzmią podobnie, a należą do trzech różnych skilli:

1. „zaudytuj prototyp / sprawdź zgodność kodu z designem / is the prototype faithful"
2. „ten ekran wygląda generycznie / jak AI / popraw look & feel" — **bez** pliku designu jako źródła prawdy
3. „zmieniłem padding w karcie, sprawdź czy nic się nie wywaliło"

**Pass:**
1. → `code-design-audit`. Pierwszy ruch to **ustalenie tieru (T0–T3)** i przeczytanie overlayu;
   brak overlayu → propose-first z `reference/config-template.json`, **nie** wymyślony leksykon.
2. → `design-toolkit:design-tweaker` **samo** (nie ten skill). Bez pliku designu warstwy parity
   i geometrii nie mają z czym porównywać — ten skill nie ma tu przewagi, a doda ceremoniał.
3. → `workflow-toolkit:browser-verify`. Jedna edycja = smoke check, nie pętla audytu.

**Fail wygląda tak:**
- Prompt 1 obsłużony **samym** `design-tweaker`: dostajesz osąd craftu i zero parity/tokenów,
  a raport brzmi jak audyt zgodności — czyli deklaracja mocniejsza niż dowód.
- Prompt 2 obsłużony tym skillem: „0 findings" z warstw, które **nie mogły** się odpalić
  (brak baseline'ów) czytane jako czysty ekran. To dokładnie klasa „martwy check świeci zielono".
- Prompt 3 obsłużony tym skillem: pełna pętla 0–9 na jednej zmianie paddingu.
- Warstwa C zaimplementowana w tym skillu od nowa, zamiast delegacji do `design-tweaker`.

**Jak sprawdzić:** odpal skill na promptcie 1 i sprawdź dwie rzeczy w pierwszej odpowiedzi:
(a) czy **nazwał tier** i nie obiecał T3 bez rejestru ekranów/baseline'ów, (b) czy krok 4 deleguje
craft do `design-tweaker`, a nie opisuje własnych soczewek. Potem odpal na promptach 2 i 3 —
oba muszą **oddać robotę** sąsiadowi, nie wejść w pętlę.

**Dlaczego ten case istnieje:** granica „coś jest nie tak z UI" ↔ „UI nie zgadza się z designem"
jest niewidoczna w promptcie, a konsekwencja pomyłki jest asymetryczna — audyt bez pliku designu
produkuje **fałszywą pewność zgodności**, która jest gorsza niż brak audytu (ta sama reguła co
inwariant 7 w SKILL.md: fałszywe uniewinnienie > fałszywy finding).

---

**Warstwa bramy (CLI, 2026-08-14).** Trzy prompty tego case'a są nierozdzielne w jednym wywołaniu,
więc w formacie CLI żyją jako trzy katalogi dzielące ten slug: `001-granica-routingu-p1-audyt-zgodnosci/`
(prompt 1 — skill ma się odpalić), `001-granica-routingu-p2-look-and-feel/` i
`001-granica-routingu-p3-jedna-edycja/` (prompty 2 i 3 — robota ma zostać oddana sąsiadowi).
`--case '001-*'` odpala wszystkie trzy. Konwencja formatu: `session-retro/evals-convention.md`.

W p2 i p3 świadomie NIE ma gradera `skill-loaded` — poprawne zachowanie to oddanie roboty, więc
sygnałem jest darmowy `regex` na nazwie właściwego właściciela (`design-tweaker` / `browser-verify`).
Te nazwy są prywatne dla tego marketplace'u, więc regex działa jednocześnie jako detektor triggera:
model bez wczytanego pluginu nie ma skąd ich znać.
