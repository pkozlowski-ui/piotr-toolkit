---
name: claude-artifact-prototype
description: Szybkie klikalne PoC publikowane jako claude.ai Artifact — z pojedynczego HTML (mockup persony, dashboard, raport, demo flow). Adresuje powtarzalne gotchy Artifactów (strict CSP, base64-safe embed, ekstrakcja assetów z Figmy, weryfikacja pod Browser-pane). Load gdy user chce "zrób prototyp/mockup jako artefakt", "opublikuj jako Artifact", "klikalny PoC", "artefakt z tego HTML", buduje mockup persony/ekranu do pokazania, albo iteruje istniejący artefakt.
---

# Skill: claude-artifact-prototype

## Rama nadrzędna (czytaj najpierw)
To **szybki PoC, NIE kod produkcyjny — niska fidelity jest OK.** Skill optymalizuje
**szybkość i łatwość** (główny sens Artifactów), nie rygor inżynierski. Nie przeprojektowuj,
nie dodawaj build-toolingu, nie „produkcjonizuj". Wartość skilla = zaadresowane gotchy, które
inaczej zjadają czas przy każdym artefakcie.

## Architektura: Engine vs Config DS
- **Engine (ten skill) = reusable, dowolny artefakt.** Kroki, skrypty i weryfikacja są
  niezależne od projektu i design systemu.
- **DS config = OSOBNO, per projekt.** Font, tokeny, komponenty, node-id assetów Figmy żyją
  w configu danego projektu (pamięć/repo projektu), NIE tutaj. Kształt configu i jak go podać:
  `references/ds-config.md`. (Dane klienckie nie trafiają do publicznego toolkitu.)

## Workflow
**clone bazy → adapt → verify → CSP transform → publish.**

1. **Clone bazy.** Jest już artefakt tego samego DS (np. inna persona)? Sklonuj jego `index.html`
   jako punkt startu — DS, inline @font-face i layout są gotowe. Brak bazy → złóż `index.html`
   z komponentów DS (patrz config) + [[design-system-lookup]] po istniejące wzorce.
2. **Adapt.** Podmień treść/widgety pod cel. Kompozycja widgetów per rola = KLASA B (osąd, niżej).
   Duże assety (avatar, logo, audio) wstawiaj **przez placeholder + skrypt**, nigdy ręcznym pastem.
3. **Verify (dev).** Zweryfikuj `index.html` lokalnie ZANIM transformujesz — [[browser-verify]]
   + reguła Browser-pane niżej. Stan po interakcji sprawdzaj przez computed styles, nie screenshot.
4. **CSP transform.** `index.html → artifact.html` skryptem (KLASA A #1). Preflight (#4) musi przejść.
5. **Publish.** Narzędzie Artifact, `file_path = artifact.html`. **Ten sam file_path = ten sam URL.**

---

## KLASA A — twarde kroki + skrypty (deterministyczne, główna wartość)
Skrypty w `scripts/` (odpalaj z katalogu skilla lub podaj pełną ścieżkę). Wszystkie zweryfikowane.

**#1 · Transform CSP** — `csp_transform.py IN.html -o OUT.html [--fonts fontface.html]`
- Wycina wrapper `<!DOCTYPE>/<html>/<head>/<body>` (Artifact owija plik własnym skeletonem).
- Zachowuje wszystkie `<style>` + wnętrze `<body>` (markup + inline `<script>`).
- Usuwa Google Fonts `<link>`/`@import` (strict CSP je blokuje).
- `--fonts` wstrzykuje gotowy inline blok `@font-face` base64 (z configu DS — patrz `references/ds-config.md`).
- Ostrzega o każdej pozostałej zewnętrznej referencji http(s).

**#2 · Base64-safe embed** — `embed_base64.py FILE.html __PLACEHOLDER__=asset[:mime] ...`
- Full-file Write **ucina base64 >~15–20KB** (awatar, mp3). Nigdy nie wklejaj dużego base64 ręcznie.
- Zostaw w HTML placeholder `__NAZWA__`, potem skrypt podmienia go na `data:...;base64,...`.
- Tryb `@plik` wstawia gotowy data-URI z pliku verbatim (base64 nie przechodzi przez kontekst/argv) —
  łączy się z #3.

**#3 · Ekstrakcja assetów Figma** — `figma_asset_extract.sh <ASSET_URL> <OUT> [MAX_PX]`
- **KROK MCP (nie skrypt):** `get_design_context(nodeId)` → zwraca URL assetu
  (`localhost:3845/...` Dev Mode albo `figma.com/api/mcp/asset/<uuid>`, TTL ~7 dni).
- **KROK skryptu:** `curl` → `sips -Z <px>` (resize rastra) → base64 → `.datauri`.
- **NIE** `figma_execute exportAsync` na ciężkim image-node = **timeout 5s pluginu.**
- Pełny łańcuch: `get_design_context` → `figma_asset_extract.sh URL avatar 160` →
  `embed_base64.py artifact.html __AVATAR__=@avatar.datauri`.
- Głębsze operacje Plugin API: [[figma-console]] (`figma-design-toolkit`).

**#4 · Preflight przed publish** — `preflight_artifact.py artifact.html`
- Gate przed narzędziem Artifact. FAIL (exit 1): wrapper obecny / zewnętrzne http(s) / Google Fonts.
- Info: rozmiar, liczba+rozmiar data-URI, liczba `<style>`/`<script>`. Musi być OK przed publish.

**#5 · Publish flow** — narzędzie **Artifact** (nie CLI):
- `file_path = artifact.html`. **Ten sam file_path przy re-publish = ten sam URL** (iteracja bez zmiany linku).
- **Preferencja Piotra: po istotnych zmianach republikuj automatycznie, bez pytania.**
- iPad landscape 1194×834, touch-first, tranzycje INSTANT (globalny default prototypów).

## Weryfikacja pod Browser-pane (gotcha, KLASA A)
Pliki poza folderem projektu w Browser-pane = **static snapshot — screenshot RESETUJE stan JS.**
Stany po interakcji (agent otwarty, tab przełączony, voice mode) weryfikuj przez **computed styles /
`getBoundingClientRect`** (`javascript_tool`), NIE licz na screenshot. Do screenshotu stanu:
tymczasowo ustaw stan jako default w HTML → screenshot → cofnij. Kompozycja z [[browser-verify]].
Globalna reguła: nie diagnozuj z rzutu oka — sprawdź realny stan (właściwości, nie wygląd).

---

## KLASA B — tylko principles (osąd — NIE utwardzać w kroki, hipoteza n=1)
- **Nie ma jednego szablonu dashboardu.** Każdy = kompozycja widgetów per rola (archetypy
  Operations/Growth/Oversight/System Admin). Home = top items, reszta w zakładkach.
- **Wiersze „worth your attention"/„flagged" = lekkie** (kółko + tytuł + 1 linia + chevron),
  bez przycisków akcji — akcja w drill-inie/agencie.
- **Differentiator** (rzecz, która dowodzi tezy) projektuj świadomie — to on niesie demo, nie chrome.
- **Look&feel** rób przez DS projektu, nie samowolny swap fontu/brandu (globalna reguła designu).
- To osąd zależny od celu i roli — traktuj jako punkt startu, nie procedurę. Referencja do DS,
  nie recepta.

## Kompozycja (nie duplikuj)
Ten skill dokłada TYLKO to, czego inne nie mają: CSP transform, base64-safe embed, asset-curl, preflight.
Resztę deleguj:
- [[browser-verify]] — gate weryfikacji UI (desktop+mobile+konsola+werdykt).
- [[figma-console]] (`figma-design-toolkit`) — pełny Plugin API, gdy `get_design_context` nie wystarcza.
- [[design-system-lookup]] — znajdź istniejące wzorce/komponenty przed tworzeniem nowych.
- [[coding-principles]] — higiena kodu (w granicach „to PoC, nie prod").

## Validation-gate (reguła Piotra — n=1)
Skill powstał z **jednej sesji** (Persona 2 CMO, 2026-07-23).
- **Klasa A** (skrypty, obiektywne) — utwardzone szybciej: 4/4 przechodzą smoke-test; kanon warunkowo.
- **Klasa B** (osąd) — **hipoteza, NIE kanon.** Nie egzekwuj jak reguły.
- **Held-out:** następny prototyp (MAP Lighthouse / MAN-595 albo iteracja person). Jeśli skróci robotę
  **bez regresji** → utwardź. Regres → cofnij. Realna wpadka → dopisz task do `evals/`
  (konwencja `evals-convention.md` w `usage-audit/`).
