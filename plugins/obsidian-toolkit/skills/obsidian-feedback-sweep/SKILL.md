---
name: obsidian-feedback-sweep
description: Zamiana komentarzy z review designu (Figma + FigJam) w sklasyfikowany, zrouowany, odpowiedziany rejestr w Obsidianie. Uruchamia się gdy user mówi "zrób sweep feedbacku", "przejrzyj feedback", "triage komentarzy z Figmy", "ogarnij komentarze z review", "feedback sweep".
---

# Skill: obsidian-feedback-sweep

## Cel
Po sesji review (Figma/FigJam) przerobić rozsypane komentarze w **jeden rejestr prawdy w Obsidianie**:
sklasyfikowane na 2 osiach, zrouowane do decydentów, z gotowymi draftami odpowiedzi. Rejestr żyje w
vaulcie; **człowiek decyduje, co wkleić z powrotem do Figmy** — to kuratorowany kanał review, osobny od
szybkich wrzutek (Slack→Linear).

## Auto-trigger
Uruchamia się gdy user mówi:
- "zrób sweep feedbacku" / "feedback sweep" / "ogarnij feedback"
- "przejrzyj komentarze z Figmy" / "triage komentarzy" / "feedback z review"
- po sesji review, gdy w pliku Figma / na boardzie FigJam pojawiły się nowe nierozwiązane wątki

## Wymagania
- **MCP `obsidian`** — rejestr i edycja notatek (`mcp__obsidian__*`). Patrz gotcha o wyszukiwaniu niżej.
- **MCP `figma-console`** — pobranie komentarzy (`figma_get_comments`) i mapowanie `node_id` → ekran (`figma_execute`).
- **Config per-projekt** — macierz decydentów, folder rejestru, scope kanału, reguły domenowe.
  Jeśli projekt go nie ma → patrz `reference/project-config-template.md` i zaproponuj założenie (propose-first).

## Konfiguracja per-projekt (skill jest vault-agnostyczny)
Skill koduje **proces**. To, co specyficzne dla projektu, czytaj z `CLAUDE.md` / `.claude/memory/`:
- **Macierz decydentów** (kto jest Ownerem jakiej domeny decyzji) — bez niej routing się nie domknie.
- **Folder rejestru** w vaulcie (np. `Feedback Pipeline/`) + nazwa żywego rejestru.
- **Scope kanału** — czy to Obsidian-only (drafty, człowiek wkleja ręcznie) czy mirror do Linear/Figmy.
- **Reguły domenowe** do uzasadniania klasyfikacji (np. reguły design systemu, brand, terminologia).

Brak configu w projekcie → **nie zgaduj ludzi ani reguł**; zaproponuj uzupełnienie z szablonu.

## Protokół — 5 faz

```
1. CAPTURE   INKREMENTALNIE — pobieraj tylko to, co nowe od ostatniego sweepu:
             a) ustal WATERMARK = `last-swept` z frontmatter poprzedniego rejestru
                (fallback: jego `updated`/`collected`). Zbierz też set zalogowanych thread-id.
             b) figma_get_comments(include_resolved:true) — duży output (potrafi >90k znaków,
                przekracza budżet tokenów) → ZAPISYWANY DO PLIKU; NIGDY nie wrzucaj go do kontekstu.
                Parsuj plik skryptem (python/jq), zwracaj tylko skondensowaną deltę.
             c) Grupuj po wątku (root = brak parent_id). Dla każdego wątku zachowaj tylko gdy ma
                wiadomość po watermark od AUTORA ≠ właściciel kanału (pomiń własne repliki/odpowiedzi).
                Odfiltruj rozwiązane WĄTKI (resolved_at na rootcie). Zdeduplikuj na poziomie wątku.
             d) Rozbij na: NOWE WĄTKI (root po watermark) vs NOWE ODPOWIEDZI na zalogowane wątki
                (root sprzed, reply po) — te drugie podlinkuj do istniejącego F##/B## po node_id.
             e) node_id → ekran/Flow przez figma_execute. FigJam (board) = osobny file_key → osobny pull.
2. CLASSIFY  Oś A (Typ) + Oś B (Dyspozycja), uzasadnione regułami domenowymi projektu
3. ROUTE     Dyspozycja = "Needs decision" → przypisz Ownera (macierz) + Consulted (RACI-lite, 1 primary)
4. ACT       Answer & close → draft odpowiedzi (odpowiedz na pytanie)
             Do now         → wykonaj/zaproponuj zmianę designu (wg build-philosophy projektu)
             Needs decision → zbuduj jasną część UI + draft Decision Ask dla Ownera
             Defer/Phase-2  → zaloguj + tag fazy (zaznacz intencję, nie tylko odłóż)
5. CLOSE     zaktualizuj rejestr; człowiek wkleja odpowiedzi + resolve'uje w Figmie;
             potem re-pull (active-only = mniejszy output; wątek z triażu którego NIE ma w active = resolved/zamknięty;
             sprawdź ostatniego autora + czy właściciel kanału odpisał). Leftovers (czekają na decyzję innych) →
             wydziel do osobnej notatki tematycznej `Open items`; nowe nieprzetriażowane komentarze → następny dated sweep.
             Po domknięciu: oznacz rejestr `status: done` i przenieś → podfolder `Done/` (patrz Schemat rejestru).
```

## Klasyfikacja — 2 osie

**Oś A · Typ** (czym jest input):

| Tag | Typ |
|---|---|
| ❓ | Pytanie |
| 🐞 | Bug / niespójność |
| 🎨 | Pomysł designowy |
| 📦 | Pomysł produktowy (scope / feature / model danych) |
| 💬 | Notka / pochwała |

**Oś B · Dyspozycja** (co dzieje się dalej):

| Dyspozycja | Znaczenie |
|---|---|
| **Do now** | Jasne, low-risk → zadanie designowe, bez zewnętrznej decyzji. |
| **Answer & close** | Pytanie, na które odpowiadamy wprost. |
| **Needs decision** | Routuj do Ownera zanim zadziałasz. |
| **Defer / Phase-2** | Zalogowane, zaparkowane, otagowane fazą. |
| **No action** | Pochwała / kontekst. |

> Kluczowa lekcja: **oddziel Typ od Dyspozycji.** Jeden łączony tag ukrywa, kto musi zadziałać.

## Krok zamykający — `done` + archiwizacja
Feedback-sweep jest **samodzielny** — nie zakłada ani nie rusza kart na tablicy zadań (Kanban). Domknięcie sweepu to dwie rzeczy w samym pipeline rejestrów:
1. **Wdrożone/odpowiedziane itemy → `status: done`** w rejestrze (źródło prawdy o stanie, nie nazwa pliku).
2. Gdy cały sweep domknięty → **przenieś rejestr do podfolderu `Done/`** (patrz Schemat rejestru i ⚠️ niżej o `mv`).

Leftovers (czekają na decyzję innych / na przyszłość) **wydziel do osobnych notatek tematycznych** (`Open items`, `type: concept-backlog`) z 1-liniowym pointerem + backlinkiem — żeby rejestr mógł zostać czysto domknięty.

## Propose-first (dyscyplina zapisu)
Każdy zapis do vaultu pokazuj **najpierw jako propozycję**, czekaj na OK.
- Pokaż diff/wstawkę zanim utworzysz lub nadpiszesz notatkę rejestru.
- **Nie** postuj odpowiedzi ani nie resolve'uj wątków w Figmie sam — to robi człowiek.
- Drafty odpowiedzi przygotuj w rejestrze; właściciel kanału decyduje, co i kiedy wklei.
- **Drafty pisz w języku kanału review** — jeśli komentarze w Figmie są po angielsku, drafty TEŻ po angielsku (lądują wprost w komentarzach Figmy). Metki/struktura rejestru mogą zostać w języku roboczym. (Cudzysłowy w eksporcie komentarzy Figmy bywają mieszane: otwierający `„` U+201E + zamykający prosty `"` U+0022 — przy `replace` mapuj dokładny znak.)
- Nowe notatki tematyczne → propozycja; zmiany w istniejącym rejestrze → też pokaż przed zapisem.

## Schemat rejestru
Żywy rejestr to **jedyne źródło prawdy**. Tabela triage:
`# · Lokalizacja · Typ · Owner (primary) · Dyspozycja · one-liner`
Blok detalu per item: `Lokalizacja · Autor · Data · Komentarz · Reakcja (Typ + uzasadnienie) · Odpowiedź`.
Dodaj **Status** (`New → Routed → Decided → Done`) w miarę postępu.

**Frontmatter (źródło prawdy o stanie — nie nazwa pliku):**
```yaml
type: feedback-log
status: open | active | done    # cykl życia rejestru (queryable, NIE w nazwie)
scope: <co sweep objął>          # ZAKRES, nie stan — nie mieszaj z status
last-swept: <ISO>                # czas pullu — punkt odcięcia następnego sweepu (wymagany)
previous: "[[poprzedni rejestr]]"
closed: <YYYY-MM-DD>             # gdy status: done
```
- **`status` to źródło prawdy stanu**, NIE nazwa pliku. **Nie oznaczaj done przez ✅/prefix w nazwie** — rename zmienia basename i psuje `[[linki]]` + łańcuch `previous`/`last-swept`. (Wyjątek: rename **w UI Obsidiana** auto-przepina linki; rename przez API lub `mv` na dysku — NIE.) Stan trzymaj w polu `status`.
- **`scope` ≠ `status`.** `scope` opisuje *co* sweep objął (np. „active threads only"); `status` opisuje *stan pracy*.

**Model „rejestr = pozycja to-do":** rejestr to zamknięta jednostka pracy (jeden sweep).
- **Definicja „done":** wszystkie itemy *odpowiedziane lub zrouowane* — **nic nie czeka na akcję właściciela kanału**.
  Item czekający na decyzję Ownera NIE blokuje zamknięcia (piłka po jego stronie); gdy Owner odpowie, wróci w następnym sweepie.
- Gdy `status: done` — nie dopisuj do rejestru; nowy sweep startuje od jego `last-swept`.
- Itemy szersze/na przyszłość (nie domkną się w tym sweepie) → **osobna notatka tematyczna** (`type: concept-backlog`),
  żeby rejestr mógł zostać czysto domknięty (zostaw 1-liniowy pointer + backlink).

**Widok Bases (własny dla pipeline'u, nie tablica zadań):** nad folderem rejestrów trzymaj `*.base`
(`groupByProperty: note.status`, kolumny `open · active · done`) — rejestry stają się odhaczalną listą sweepów.
To wewnętrzny widok feedback-pipeline'u, odrębny od jakiejkolwiek tablicy zadań w vaulcie.

**Archiwizacja done-rejestrów = przenieś do podfolderu `Done/`** (np. `Feedback Pipeline/Done/`), NIE rename z ✅. Obsidian rozwiązuje wikilinki po **basename**, więc przeniesienie do podfolderu **nie psuje linków** (zmiana basename — psuje). ⚠️ Filtr w `*.base` MUSI być **rekursywny**: `file.inFolder("<folder>")`, NIE `file.folder == "<folder>"` (to drugie wyklucza podfolder → done-rejestry znikają z kolumny Done). **Nigdy nie kasuj rekordu** — done zostaje jako archiwum.

⚠️ **Jak przenieść — `mv`, nie MCP copy+delete.** Najpierw zmień frontmatter na `status: done` + `closed:` (przez MCP `manage_frontmatter`/`patch_note`), **potem** `mv` pliku na filesystemie: `mv "<vault>/Feedback Pipeline/Nota.md" "<vault>/Feedback Pipeline/Done/"`. To **jeden atomowy ruch**. NIE rób „`write_note(Done/…)` + `delete_note(stary)`" — to dwa kroki, a gdy delete zostanie anulowany (jest destrukcyjny, często bez auto-zgody), zostaje **osierocony duplikat** w obu folderach (realny przypadek z sesji). Alternatywa: drag w UI Obsidiana (auto-przepina też ew. linki po basename), ale agent zwykle nie ma dostępu do UI → `mv`. Mechanika dwóch kanałów (treść = MCP, pliki = filesystem): skill `obsidian-setup`.

## Szablony (copy-paste)
W `reference/templates.md`: wiersz triage, blok detalu, Decision Ask. Użyj ich zamiast wymyślać format.

## Gotchas
- **`obsidian_search_notes` (text) fuzzy-matchuje tokeny** — szukanie `"Flow 9b"` zwraca trafienia samego
  `"Flow"` i zawyżony licznik. Do precyzji: `obsidian_get_note` z `format:document-map` (nagłówki) /
  `format:section` (treść), podstawienia przez `obsidian_replace_in_note` na pełnych, unikalnych stringach.
- **`figma_get_comments` to duży output** — przy aktywnym pliku łatwo >90k znaków → przekracza budżet
  tokenów i ląduje w pliku. Parsuj plik skryptem (grupuj wątki, filtruj po watermark/autorze/resolved),
  zwracaj tylko deltę. Pola: `id`, `parent_id`, `user.handle`, `created_at`, `resolved_at`, `client_meta.node_id`, `message`.
- **`figma_get_comments` zwraca też rozwiązane** — filtruj rozwiązane WĄTKI po stronie skilla.
- **`figma_execute` nie jest transakcyjny** — przy błędzie/timeoucie zostają częściowe node'y; sprzątnij
  przed retry. Trzymaj skrypty małe.
- **Wikilinki w YAML frontmatter** — `klucz: [[A]], [[B]]` to NIEPOPRAWNY YAML (dwa flow-seq po przecinku) →
  Obsidian nie sparsuje frontmatter → notatka traci `type`/`status` i **wypada z widoku Bases**. Zawsze listą i w cudzysłowach:
  `klucz:\n  - "[[A]]"\n  - "[[B]]"`. Każda notatka, którą board ma pokazać, musi mieć `status` (inaczej ląduje w „Uncategorized").

## Po sweepie — higiena (jeśli projekt ma design system)
Powtarzający się nowy element → komponentyzuj i zarejestruj w DS projektu. Reguły DS, brandu i
„build philosophy" (np. concept-of-the-future) czytaj z `CLAUDE.md` projektu — nie hardcoduj ich tutaj.

## Raport końcowy
Wypunktuj: ile wątków przetworzono (active/skipped), rozkład Typ × Dyspozycja, co zrouowano do kogo,
ile draftów gotowych do wklejenia, co czeka na decyzję. Zaznacz **wyraźnie, co jest done** w rejestrze.
