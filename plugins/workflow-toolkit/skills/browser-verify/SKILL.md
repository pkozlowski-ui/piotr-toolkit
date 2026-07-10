---
name: browser-verify
description: Gate weryfikacji UI w przeglądarce przed deklaracją "done/naprawione" — desktop + mobile + konsola + werdykt, przez natywne narzędzia Claude_Preview (zero-setup). Load przy zmianach UI we frontendzie zanim ogłosisz rezultat; także na frazy "zweryfikuj w przeglądarce", "sprawdź jak wygląda", "browser verify".
---

# Skill: browser-verify

## Rola
**Gate, nie mechanizm.** Weryfikacja i tak dzieje się oportunistycznie (audyt użycia 2026-07:
model sam sięga po screenshot/eval przed „gotowe") — ten skill dokłada to, czego praktyka
ad hoc NIE gwarantuje: **parę desktop+mobile, check konsoli i explicit werdykt** przed deklaracją.

**Scope (vs `mobile-audit`):** browser-verify = szybki smoke-check przed „done". Pełny,
wieloviewportowy audyt mobile z raportem → `mobile-audit` (design-toolkit).

## Protokół (narzędzia `mcp__Claude_Preview__*` — zero-setup, bez instalacji)

1. **Serwer** — `preview_start` (czyta `.claude/launch.json`; brak configu → utwórz wg
   schematu z opisu narzędzia). Reużywa działający serwer. NIE odpalaj dev-serwera przez
   Bash, NIE zakładaj portu 3000 — port pochodzi z launch.json / outputu serwera.
2. **Desktop** — `preview_resize` preset `desktop` → `preview_screenshot`.
3. **Mobile** — `preview_resize` preset `mobile` → `preview_screenshot`. (Dark mode w grze →
   dodatkowo `colorScheme: "dark"`.)
4. **Konsola** — `preview_console_logs` z `level: "error"` — musi być czysto (nowe błędy = Issue).
5. **Właściwości, nie piksele** — kolory/tokeny/spacing weryfikuj przez `preview_inspect` /
   `preview_eval` (computed styles), NIE z rzutu oka na screenshot (globalna reguła:
   „nie diagnozuj z rzutu oka" — screenshot to layout, inspect to prawda o wartościach).
6. **Werdykt (explicit, zawsze):**
   - **OK** → dopiero teraz „done"; pokaż screenshoty userowi,
   - **Issue** → napraw, wróć do kroku 2,
   - **Niejasne** → zapytaj usera, zanim zmienisz cokolwiek.

## Check treści
Przy sprawdzaniu layoutu zweryfikuj też:
- elementy nachodzące / złamany grid/flex,
- niespójne spacingi, regresje kolorów/tokenów (krok 5, nie screenshot),
- tekst bez zmian, jeśli projekt ma regułę READ-ONLY TEXT.

## Fallbacki (tylko gdy `Claude_Preview` niedostępne)
1. `claude-in-chrome` / `Control_Chrome` (jeśli podłączone) — nawigacja + screenshot.
2. Playwright CLI (`npx playwright screenshot --viewport-size=1440,900 / 375,812`) — wymaga
   instalacji (`npm i -D @playwright/test && npx playwright install chromium`); to ostatnia
   deska, nie default (audyt: ten kanał miał 0 użyć, bo przegrywa z natywnym).
