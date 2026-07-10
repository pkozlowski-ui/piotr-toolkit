---
name: figma-router
description: >
  Tablica routingu domen Figma — referencja "które zadanie → który skill" + hand-off do
  oficjalnego pluginu Figma i reguły doboru kanału zapisu. Load gdy nie wiesz, którym skillem
  zrobić zadanie figmowe, albo przy pracy cloud/headless (bez Figma Desktop). UWAGA: to
  referencja, nie gate — egzekucję triggerów robią twarde kanały (hook route-skills,
  reguły per-projekt), nie ten opis.
---

# figma-router — tablica routingu (referencja)

> Audyt użycia 2026-07: router jako "entry point ładowany przed każdą pracą figmową" nie
> działał (1 wywołanie / 6 tyg. przy 97 sesjach figma-console) — i nie musi: środowisko jest
> stałe (Desktop Bridge), a wejścia w metodologię egzekwują hook `route-skills.sh`
> (workflow-toolkit) i reguły per-projekt. Ten plik zostaje jako mapa domen + wiedza
> o kanałach zapisu i ścieżce cloud.

## Routing domen

| Domena | Sygnały | Skill |
|---|---|---|
| **Design / ekrany** | nowy ekran/layout, komponent, variables, auto layout, "zbuduj ekran" | `figma-design-workflow` |
| **FigJam / diagramy** | diagram, flow, flowchart, board URL (`figma.com/board/…`) | `figjam-diagrams` |
| **Accessibility** | WCAG, ARIA, kontrast, a11y, focus order | `figma-accessibility` |
| **DS audit / naprawa** | drift, hardcoded colors, "podepnij do DS", token audit, detached | `figma-ds-tools` |
| **DS scaffold / init** | "załóż design system", registry/build-kit | `figma-ds-init` |
| **Prototyp** | prototype mode, połącz ekrany, tranzycje, overlay | `figma-prototype` |
| **Cloud / headless** | brak Figma Desktop, telefon, web/cloud env | `figma-cloud` (mechanika) + skill domenowy (metodologia) |

Cross-domain → skill domeny PRIMARY (on odsyła do secondary). Niejasne → jedno pytanie.

## Kanał zapisu (rozmiar gate'uje)

- Małe/iteracyjne edycje, inspekcja, screenshoty, multi-file → `figma-console`
  (`figma_execute` ma twardy budżet ~5 s — guard bridge'a).
- **Ciężki/bulk write (≥~50 node'ów albo cokolwiek, co trzeba by chunkować pod 5 s) →
  `use_figma` przez `figma-cloud`** — atomowy, bez sufitu, odporny na padnięcie Bridge'a.
- Greenfield JSX-style → `figma-cli`.
- **Bridge pada mid-session i nie wstaje → nie pętlij reconnectów**: przełącz write na
  `use_figma` (`figma-cloud`); Bridge zostaw do screenshotów/inspekcji. Szczegóły:
  `figma-console` → "Connection — resilience protocol".

## Hand-off do oficjalnego pluginu Figma (`figma@claude-plugins-official`)

| Zadanie | Dokąd |
|---|---|
| design→code, "zbuduj ten design jako kod" | oficjalny plugin — `implement-design` |
| Code Connect (mapowanie komponentów na kod) | oficjalny `/figma-code-connect` |
| reguły DS po stronie kodu | oficjalny `create_design_system_rules` |
| kanoniczne zasady `use_figma` / `create_new_file` | oficjalny `/figma-use` (ładowane przez `figma-cloud`) |

Ten toolkit = budowanie/edycja WEWNĄTRZ Figmy + house rules (INSTANT transitions, dyscyplina
tokenów, ask-loudly). Oficjalny plugin = silnik; toolkit = orkiestracja. Patrz `OVERVIEW.md`.

## Extension pattern (anti-bloat — default: NIE dodawaj skilla)

Nowy skill tylko dla prawdziwie nowej DOMENY (własne sygnały + własny wiersz w tabeli).
Cross-cutting concern (gate, checklista, reguła działająca wewnątrz innego workflow) → sekcja
istniejącego skilla, nie nowy skill. Skill bez wiersza w tabeli = smell — napraw albo scal.
