# Feedback Sweep — config per-projekt (szablon)

Skopiuj sekcje do `CLAUDE.md` projektu (lub `.claude/memory/feedback-sweep-config.md`).
Skill `obsidian-feedback-sweep` czyta to stąd — bez tego nie zgaduje ludzi ani reguł.

## 1. Folder rejestru (Obsidian)
- **Folder:** `Feedback Pipeline/`
- **Żywy rejestr:** `<YYYY-MM-DD> - <nazwa>.md` (jedyne źródło prawdy)
- **Runbook:** `Feedback Sweep — Runbook & Template.md`

## 2. Folder Delight (Obsidian — trwała baza pozytywu)
- **Folder:** `Delight/`
- **Żywa kolekcja:** `Delight — <projekt>.md` (kumulatywna, nigdy nie archiwizowana)
- **Widok:** `Delight.base` (`groupByProperty: person`) — jeśli wpisy jako osobne pliki; inaczej grupuj sekcjami `## #osoba` w notatce.
- **Target:** kto (team wewnętrzny / klient / oba) — decyduje, czyj delight zbieramy.

## 3. Scope kanału
- `Obsidian-only` — drafty w rejestrze, człowiek ręcznie wkleja odpowiedzi i resolve'uje wątki w Figmie.
  (Osobno od szybkich wrzutek typu Slack→Linear, jeśli projekt taki ma.)

## 4. Macierz decydentów (Owner + Consulted, RACI-lite)
| Domena decyzji | Owner | Zwykle konsultowani |
|---|---|---|
| Technologia · model danych · integracje · feasibility | <imię> | … |
| Produkt · scope · feature · flow · priorytety · Phase-2 | <imię> | … |
| Substancja · jak działa domena · reguły · terminologia | <imię> | … |
| Sales · rynek · pozycjonowanie · wartość dla klienta | <imię> | … |
| Design · UI · copy (bez zewnętrznego ownera) | <imię> | … |

## 5. Reguły domenowe (do uzasadniania klasyfikacji)
- Reguły design systemu / brandu, które czynią item „Do now" vs „Needs decision".
- Terminologia i reguły domenowe (do uzasadnień w kolumnie Reakcja).

## 6. Build philosophy (opcjonalnie)
- Czy projekt to concept-prototype (niski próg „buduj", wysoka wartość pokazania)?
- Definicja „done": np. token audit `count:0` + screenshot validation, build z instancji DS.

---

### Przykład wypełniony — projekt antisis (Manta Vault)
- **Folder rejestru:** `Feedback Pipeline/` · rejestr `Figma & Figjam Feedbacks.md`
- **Folder Delight:** `Delight/` · kolekcja `Delight — Manta.md` · target = **team wewnętrzny** (Manta).
- **Scope:** Obsidian-only (Piotr wkleja ręcznie); osobny `Anti Feeback Bot` = Slack→Linear.
- **Macierz:** Tech/data → **Matt** · Produkt/scope → **Tom & Will** · Substancja/szkoły → **Dominique** ·
  Sales → **Courtney & Kara** · Design/UI/copy → **Piotr** (Dominique = domain check).
- **Reguły:** powierzchnie Manta (2px Manta Gradient + Icon/Sparkles, `MantaInsightCard`), max 1–2 elementy Manta/kontekst.
- **Build philosophy:** concept-of-the-future — `Do now` = buduj w Figmie teraz; done = token audit count:0 + screenshot.
