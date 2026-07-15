---
id: prototype-to-review-001
skill: prototype-to-review
źródło: adaptacja z prototype-to-figma-skill (alima-max) 2026-07-15 — walidacja 2 twardych reguł, które
  odróżniają review-spec od zwykłego eksportu ekranu: (a) zakaz nowych komponentów DS, (b) adnotacje
  wpięte w węzeł, nie floating text
status: aktywny
---

# Prototyp→review buduje ze źródła, nie tworzy nowych masterów DS, adnotuje wpięte w węzły

**Scenariusz (input):** User daje działający prototyp w kodzie (React/CSS) i mówi „zrób z tego
reviewable Figmę / rozbij na flow do komentowania". Prototyp ma element bez odpowiednika w design
systemie (np. custom chip) i ≥3 stany interakcji.

**Pass:**
1. Klatki zbudowane **ze źródła kodu** (inwentarz elementów + zmierzony viewport) — NIE z
   browser-capture/screenshot/HTML-to-design.
2. Element bez matcha w DS → **prymityw z tokenami** + adnotacja **DS Drift** (pomarańcz). Zero nowych
   masterów komponentów DS utworzonych w pliku.
3. Adnotacje **wpięte w węzeł** (`node.annotations` native, albo child text-node w klatce w trybie
   fallback) — nigdy floating text na canvasie. 2–4 Interaction / klatkę.
4. Font prymitywów **dziedziczony z DS/pliku** — żadnego twardego „Inter" ani innego samowolnego kroju.
5. ≥3 stany → gate zakresu (plan pokazany, wybór usera) ZANIM budowa.

**Fail wygląda tak:**
- Klatki „odrysowane" ze screenshotu prototypu zamiast zbudowane ze źródła (piksele zamiast tokenów).
- Nowy komponent DS utworzony dla custom-chipa (zaśmieca bibliotekę, robota DS-ownera).
- Adnotacje jako floating text-boxy obok klatek (odrywają się, reviewer nie wie czego dotyczą).
- Hardcode font „Inter" w prymitywach (regresja reguły brandowej — realny footgun w źródłowym skillu).
- 40 klatek wygenerowanych bez pytania o zakres.

**Jak sprawdzić:** W pliku Figma — `findAll(type==='COMPONENT'|'COMPONENT_SET')` utworzone w tej sesji
= 0 (prymitywy to FRAME). Każda klatka-stan ma ≥1 adnotację wpiętą (`node.annotations.length>0` lub
child label-node w ramce). Fonty prymitywów = font DS/pliku. W transkrypcie: plan zakresu + wybór usera
poprzedza pierwszą budowę przy ≥3 stanach. Brak wywołań browser-capture/HTML-to-design.
