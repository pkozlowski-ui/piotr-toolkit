---
name: mobile-audit
description: >
  Kompleksowy audyt wersji mobilnej strony lub aplikacji. Używaj gdy chcesz
  sprawdzić mobile przed deployem, zbadać problemy responsywności, ocenić
  jakość mobile UX, lub zoptymalizować konwersję na mobile. Triggers:
  "audyt mobile", "sprawdź mobile", "mobile audit", "responsywność",
  "jak wygląda na telefonie", /mobile-audit, /mobile.
---

# Mobile Audit

Szukaj problemów, nie potwierdzeń. Raportuj po polsku.

> **Zakres (vs `browser-verify`):** to **głęboki**, wieloviewportowy audyt z raportem `MOBILE_AUDIT.md`. Do szybkiego smoke-checku po zmianie UI przed „done" użyj `browser-verify` (workflow-toolkit).

---

## Pre-flight (zanim cokolwiek zaczniesz)

**1. Playwright** — czy jest dostępny w projekcie?
- Jeśli tak: używaj do screenshotów, computed styles, bounding boxów.
- Jeśli nie: powiedz to **na początku** i zapytaj — instalujemy czy user robi screenshoty ręcznie? Bez wizualnego podglądu sekcje 3 i 4 będą oparte wyłącznie na analizie kodu.

Setup jeśli brak:
```bash
npm install -D @playwright/test && npx playwright install chromium webkit
```

**2. Cel strony** — zanim zaczniesz sekcję 4 (konwersja), ustal jaki jest główny cel. Bez tego audyt konwersji jest spekulacją. Zapytaj wprost jeśli nie wynika z kodu/contentu.

**3. Design system** — przejrzyj global CSS: breakpointy, custom properties, spacing tokens. To kontekst dla całego audytu.

---

## Viewporty do sprawdzenia

320px · 375px · 390px · 414px · 768px (tablet portrait)

Dla każdego: brak horizontal scroll, brak overflow poza viewport, text się nie przycina, obrazy zachowują aspect ratio.

---

## Step 1 — Layout basics (priorytet: krytyczny)

Bez tego reszta nie ma sensu. Sprawdź każdą sekcję:

- **Overflow** — horizontal scroll na całej stronie lub w sekcji (winowajca: fixed width, negative margin, translate poza viewport)
- **Widoczność** — nic nie znika przez `display:none` w złym breakpoincie, `opacity:0` przez błąd, `z-index:-1`
- **Przycinanie** — tekst nie ucięty przez `overflow:hidden` za małego kontenera, obrazy nie kadrowane przypadkowo
- **Absolute/fixed** — elementy nie wychodzą poza viewport ani nie przykrywają interaktywnego contentu
- **Kompletność** — wszystkie sekcje desktop są obecne na mobile
- **Klikalność** — przyciski i linki nie przykryte niewidocznym elementem

---

## Step 2 — Touch i interakcje (priorytet: wysoki)

- **Touch targets** — min 44×44px (Apple HIG) lub 48×48px (Material). Odstępy między klikalnymi: min 8px.
- **Stany** — `:hover` zastąpiony/zduplikowany przez `:active` i `:focus` na mobile
- **Formularze** — `type` i `inputmode` triggery klawiatury (patrz tabela niżej), `autocomplete` ustawione, klawiatura nie zasłania focusowanego pola, labelki zawsze widoczne (nie tylko placeholder), walidacja czytelna na małym ekranie
- **Nawigacja** — hamburger zamyka się po kliknięciu linku, trap focus w otwartym menu, backdrop scroll zablokowany gdy menu otwarte, sticky header nie zasłania contentu

| Pole | `type` | `inputmode` |
|---|---|---|
| Email | `email` | — |
| Telefon | `tel` | — |
| Liczba całkowita | `text` | `numeric` |
| Kod pocztowy | `text` | `numeric` |
| OTP | `text` | `numeric` + `autocomplete="one-time-code"` |

---

## Step 3 — Visual polish (priorytet: wysoki)

Patrz okiem designera. Cel: zidentyfikować co wygląda nieprofesjonalnie lub chaotycznie na małym ekranie.

- **Rytm pionowy** — czy padding/margin między sekcjami jest spójny lub celowo zróżnicowany
- **Hierarchia** — H1 > H2 > H3 zachowane, ale skala dostosowana do mobile; primary CTA wizualnie dominuje nad secondary
- **Typografia** — brak sierot, nagłówki nie łamią się w nieczytelny sposób, rozważ `text-wrap: balance` dla headingów; `text-align: justify` na mobile tworzy dziury — preferuj `left`
- **Obrazy** — focal point widoczny po przycięciu (`object-position`), ikony spójny rozmiar i styl w obrębie grupy, grafiki nie za małe (gubią się) ani nie za duże (dominują)
- **Detal** — spójne `border-radius` w podobnych komponentach, spójne bordery, animacje nie blokują interakcji

Jeśli po tym kroku widzisz głębszy problem z layoutem lub architekturą sekcji → uruchom `design-tweaker` dla pełnego audytu (UX/wizual/look&feel/AI-slop, diagnoza strukturalna).

---

## Step 4 — Konwersja (priorytet: wysoki)

**Wymagane: znany cel strony przed tym krokiem.**

- **Primary CTA** — widoczny bez scrollowania, wizualnie dominujący, treść action-oriented ("Zarezerwuj demo" > "Dowiedz się więcej"), powtórzony w kluczowych miejscach; na długich stronach rozważ sticky CTA w kciukowym zasięgu (dolna 1/3 ekranu)
- **Information flow** — kolejność: problem → rozwiązanie → wartość → dowód → akcja; value prop jasny w 5 sekund; brak sekcji opóźniających konwersję bez powodu
- **Social proof** — widoczny przed primary CTA; wiarygodny (imię, firma, zdjęcie — nie "J.D., happy customer")
- **Friction** — minimum pól w formularzach, smart defaults, submit button mówi co się stanie; popup/cookie banner nie zasłania CTA na mobile
- **Distraction** — hamburger nie za rozbudowany; na jednym ekranie jedna główna intencja; elementy nieinteraktywne nie wyglądają klikalnie

---

## Step 5 — Technikalia

**Typografia:**
- `font-size` body ≥ 16px (iOS auto-zoom poniżej)
- `line-height` 1.4–1.6 dla body
- `overflow-wrap: anywhere` dla długich URL/emaili

**Performance:**
- Obrazy: `srcset`/`sizes`, WebP/AVIF z fallbackiem, `loading="lazy"` poniżej foldu, `fetchpriority="high"` na hero LCP
- Fonty: `font-display: swap`
- Lighthouse mobile preset: raportuj LCP, CLS, INP z konkretnymi wartościami

**Dostępność:**
- Kontrast: 4.5:1 body, 3:1 duży tekst/UI (WCAG AA)
- `:focus-visible` widoczny i logiczny
- `aria-label` na icon buttons
- Zoom do 200% nie psuje layoutu

**Platform traps:**

iOS Safari:
- `100vh` problem → użyj `dvh`/`svh`
- Notch/home indicator → `env(safe-area-inset-bottom)` dla sticky elementów
- `-webkit-tap-highlight-color` na interaktywnych elementach
- Sticky position bugs przy otwartej klawiaturze

Android Chrome:
- `touch-action: manipulation` eliminuje 300ms click delay
- Pull-to-refresh konflikty ze swipe gestures

**Edge cases:** landscape orientation, bardzo długie słowa (`overflow-wrap: anywhere`), `prefers-reduced-motion`, slow network (jak wygląda podczas ładowania obrazów)

---

## Output

Zapisz raport jako `MOBILE_AUDIT.md` w root projektu. Struktura:

```
## Executive summary
3-5 zdań: co jest największym problemem i czy strona jest gotowa na deploy.

## Krytyczne (blokują deploy)
## Wysokie (naprawić przed deployem)
## Średnie (warto poprawić)
## Niskie (nice to have)
## Co działa dobrze (krótko)
```

Dla każdego znaleziska:
- **Lokalizacja**: plik i linia (+ screenshot jeśli Playwright)
- **Problem**: co konkretnie
- **Impact**: krytyczny / wysoki / średni / niski
- **Fix**: konkretny kod, nie ogólniki

Po każdej kategorii zapytaj czy implementować poprawki od razu, czy najpierw pokazać cały raport.

---

## Zasady

- Playwright niedostępny → powiedz to na początku, ustal jak pracujemy
- Cel konwersji nieznany → zapytaj przed sekcją 4
- Nie zgaduj — jeśli nie możesz sprawdzić bez uruchomienia, powiedz wprost
- Nie chwal na siłę — szukaj problemów
- Nie wprowadzaj zmian bez zgody
- Pisz po polsku
