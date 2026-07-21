---
name: obsidian-feedback-sweep
description: Turn scattered design-review comments from Figma & FigJam into one classified, routed, answered register in Obsidian — type + disposition axes, owner routing (RACI-lite), ready reply drafts. Use after a design/review session to triage unresolved comment threads. Also captures positive signal & inspiration (praise, references stakeholders point to) into a separate persistent Delight registry — building per-stakeholder profiles of what lands and how to reuse it. Triggers EN+PL — "feedback sweep", "sweep the feedback", "triage Figma/FigJam comments", "go through the review comments", "process review feedback", "zrób sweep feedbacku", "przejrzyj feedback", "triage komentarzy z Figmy/FigJam", "ogarnij komentarze z review", "feedback z review", plus manual delight capture "zapisz do delight", "to się spodobało", "save to delight", "add to delight" — and on the intent even when unnamed: new unresolved comment threads on a Figma file or FigJam board to process after a review, or a positive/inspiration signal from a stakeholder worth keeping. NOT for: code-review/PR feedback, written feedback on a doc, user/customer feedback analysis, or one-off comment replies. Needs a per-project config (decision-owner matrix, register folder, delight folder); if missing, proposes setup from the template (propose-first).
---

# Skill: obsidian-feedback-sweep

## Cel
Po sesji review (Figma/FigJam) przerobić rozsypane komentarze w **jeden rejestr prawdy w Obsidianie**:
sklasyfikowane na 2 osiach, zrouowane do decydentów, z gotowymi draftami odpowiedzi. Rejestr żyje w
vaulcie; **człowiek decyduje, co wkleić z powrotem do Figmy** — to kuratorowany kanał review, osobny od
szybkich wrzutek (Slack→Linear).

**Druga misja — pozytyw NIE jest szumem.** Pochwała i podrzucona inspiracja („o, to jest super", „zróbmy
jak tu") to sygnał ulotny i cenny — który w czystym triażu ląduje w koszu „No action". Sweep zamiast tego
**promuje go do osobnej, trwałej kolekcji Delight** (baza „co ląduje u kogo i jak to reużyć"). Rejestr
feedbacku jest przepływowy (rotuje, archiwizuje się); Delight jest **kumulatywny** — rośnie i buduje
profil preferencji per-stakeholder. Dlatego mieszka osobno, nie w rotowanym rejestrze. Patrz „Delight
Registry" niżej.

## Auto-trigger
Uruchamia się gdy user mówi (EN+PL — bramką jest pole `description`, ta lista jest jej lustrem):
- "feedback sweep" / "sweep the feedback" / "zrób sweep feedbacku" / "ogarnij feedback"
- "triage Figma/FigJam comments" / "go through the review comments" / "process review feedback"
- "przejrzyj feedback" / "przejrzyj komentarze z Figmy" / "triage komentarzy" / "feedback z review"
- **na samą intencję** (nawet bez słowa „sweep"): po sesji review pojawiły się nowe nierozwiązane wątki na pliku Figma / boardzie FigJam do przerobienia
- **ręczny wrzut do Delight** (osobne wejście, bez pełnego sweepu): „zapisz do delight" / „to się spodobało" / „save to delight" / „add to delight" — pozytyw/inspiracja spoza kanałów, które sweep przemiata (Slack, call, DM). Idź prosto do fazy CAPTURE-DELIGHT (patrz „Delight Registry"), pomiń resztę protokołu.
- **NIE dla:** feedbacku z code-review/PR, feedbacku do tekstu/dokumentu, analizy user/customer feedback, jednorazowej odpowiedzi na pojedynczy komentarz

## Wymagania
- **MCP `obsidian`** — rejestr i edycja notatek (`mcp__obsidian__*`). Brak narzędzi `mcp__obsidian__*` → najpierw skill `obsidian-setup`. Patrz gotcha o wyszukiwaniu niżej.
- **MCP `figma-console`** — pobranie komentarzy (`figma_get_comments`) i mapowanie `node_id` → ekran (`figma_execute`). Projekt może mieć inny Figma MCP (oficjalny `mcp__Figma__*` lub inny server) — użyj jego odpowiednika pobierania komentarzy; gdy żaden Figma MCP nie jest podłączony → poproś usera o podłączenie zanim ruszysz CAPTURE.
- **Config per-projekt** — macierz decydentów, folder rejestru, scope kanału, reguły domenowe.
  Jeśli projekt go nie ma → patrz `reference/project-config-template.md` i zaproponuj założenie (propose-first).

## Konfiguracja per-projekt (skill jest vault-agnostyczny)
Skill koduje **proces**. To, co specyficzne dla projektu, czytaj z `CLAUDE.md` / `.claude/memory/`:
- **Macierz decydentów** (kto jest Ownerem jakiej domeny decyzji) — bez niej routing się nie domknie.
- **Folder rejestru** w vaulcie (np. `Feedback Pipeline/`) + nazwa żywego rejestru.
- **Folder Delight** (np. `Delight/`) + nazwa żywej kolekcji — trwała baza pozytywu (patrz „Delight Registry").
- **Scope kanału** — czy to Obsidian-only (drafty, człowiek wkleja ręcznie) czy mirror do Linear/Figmy.
- **Reguły domenowe** do uzasadniania klasyfikacji (np. reguły design systemu, brand, terminologia).

Brak configu w projekcie → **nie zgaduj ludzi ani reguł**; zaproponuj uzupełnienie z szablonu.

## Protokół — 5 faz

```
0. RESUME    sprawdź, czy projekt ma rejestr sweepu ze `status: active` (przerwana runda).
             Jest → WZNÓW go: dokończ fazy od miejsca przerwania i domknij (CLOSE), zamiast
             otwierać nowy dated rejestr. Nowy rejestr tylko gdy brak aktywnego albo user
             explicit każe zacząć od nowa. (Audyt użycia 2026-07: 2 rejestry „round 2"
             wisiały jako active >2 tyg., kolejne sweepy otwierały nowe obok.)
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
4. ACT       Answer & close  → draft odpowiedzi (odpowiedz na pytanie)
             Do now          → wykonaj/zaproponuj zmianę designu (wg build-philosophy projektu)
             Needs decision  → zbuduj jasną część UI + draft Decision Ask dla Ownera
             Defer/Phase-2   → zaloguj + tag fazy (zaznacz intencję, nie tylko odłóż)
             Capture→Delight → dopisz wpis do Delight Registry (Kto·Co·Na czym·Dlaczego·Jak reużyć·Źródło);
                               tag per-osoba. To promocja do trwałej bazy, nie zamknięcie w tym rejestrze.
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
| ✨ | Inspiracja / referencja (podrzucony przykład „zróbmy jak tu", link do referencji) |

**Oś B · Dyspozycja** (co dzieje się dalej):

| Dyspozycja | Znaczenie |
|---|---|
| **Do now** | Jasne, low-risk → zadanie designowe, bez zewnętrznej decyzji. |
| **Answer & close** | Pytanie, na które odpowiadamy wprost. |
| **Needs decision** | Routuj do Ownera zanim zadziałasz. |
| **Defer / Phase-2** | Zalogowane, zaparkowane, otagowane fazą. |
| **Capture → Delight** | Pozytyw / pochwała / inspiracja z realną wartością → **promuj do Delight Registry** (trwała baza), nie zostawiaj w rotowanym rejestrze. |
| **No action** | Czysty kontekst / szum bez wartości do reużycia (odhacz i zostaw). |

> Kluczowa lekcja: **oddziel Typ od Dyspozycji.** Jeden łączony tag ukrywa, kto musi zadziałać.
> **Pozytyw ma teraz własną ścieżkę:** ✨/💬 z wartością → `Capture → Delight` (nie `No action`). Zasada
> podziału: da się z tego wyciągnąć *dlaczego zadziałało* i *jak reużyć*? → Delight. Zwykłe „ok, dzięki"
> bez treści → `No action`.

## Karta-wskaźnik na tablicy (po KAŻDYM sweepie — stała reguła)
Po wytworzeniu rejestru **utwórz lekką kartę-wskaźnik na tablicy zadań** (Kanban) z **linkiem `[[…]]` do rejestru** + 1-liniowym podsumowaniem (kto · ile wątków · klastry · routing). Cel: sweep widoczny i **odhaczalny jako trigger do pracy**, nie tylko w pipeline rejestrów.
- Karta = **pointer**, NIE źródło prawdy — rejestr w folderze pipeline'u zostaje źródłem.
- Frontmatter karty wg konwencji tablicy projektu (typowo `status` + tag `sweep-pointer`).
- **Wiele rejestrów z jednego sweepu** (np. owner-separate, Tom osobno) → **jedna karta** linkująca wszystkie.
- Lokalizacja/format karty + tag = **config per-projekt** (czytaj `CLAUDE.md` / `.claude/memory/`).

**Kolumna docelowa = robocza (`To-do`), NIGDY „To confirm" (TWARDE).** Świeża karta-wskaźnik = trigger do wzięcia → ląduje w kolumnie roboczej gotowej do pracy (`To-do`, kolejność = priorytet). **„To confirm" jest zarezerwowane** — status wchodzi TYLKO po tym, jak ktoś już nad kartą pracował, i wymaga **potwierdzenia** (user pisze wprost albo Ty rekomendujesz przejście). Nic nie wskakuje do „To confirm" samo, bez choćby zaczętej pracy. Gdy sweep to czekanie na cudzą decyzję, a robota po naszej stronie już ruszyła → `In progress` + tag `blocked` (co blokuje w treści), nie „To confirm". (Semantyka kolumn: skill `obsidian-kanban`.)

**Krok raportu (TWARDE — siatka bezpieczeństwa, żeby rezultaty nie umknęły).** Closeout sweepu **musi** zawierać wprost linię: „karta-trigger: `[[nazwa]]` → kolumna `To-do`". To human-notification niezależny od renderu tablicy. Powód: karta tworzona **zapisem pliku** (kanoniczny kanał — patrz `obsidian-kanban`) dostaje poprawny `status`, ale Bases wpina ją do `cardOrders` (`.base`) dopiero przy interakcji UI — do tego czasu renderuje się **nieuporządkowana na dole kolumny** i łatwo ją przeoczyć. Realny przypadek 2026-07-21: karta powstała 28 s po rejestrze, ale była jedyną z 109 nieobecną w `cardOrders`, wylądowała w „To confirm" i nie została zgłoszona w raporcie → user uznał, że nie powstała. Bez wypchnięcia w raporcie sweep może zniknąć.

## Krok zamykający — `done` + archiwizacja
Feedback-sweep żyje w pipeline rejestrów (źródło prawdy) i **zostawia własną kartę-wskaźnik na tablicy** (patrz wyżej) — ale **nie rusza/nie przesuwa innych kart zadań**. Domknięcie sweepu to dwie rzeczy w samym pipeline rejestrów:
1. **Wdrożone/odpowiedziane itemy → `status: done`** w rejestrze (źródło prawdy o stanie, nie nazwa pliku).
2. Gdy cały sweep domknięty → **przenieś rejestr do podfolderu `Done/`** (patrz Schemat rejestru i ⚠️ niżej o `mv`).

Leftovers (czekają na decyzję innych / na przyszłość) **wydziel do osobnych notatek tematycznych** (`Open items`, `type: concept-backlog`) z 1-liniowym pointerem + backlinkiem — żeby rejestr mógł zostać czysto domknięty.

## Delight Registry — trwała baza pozytywu
Osobna od rejestru feedbacku, bo ma **odwrotną naturę**: feedback rotuje i archiwizuje się (przepływ);
Delight **kumuluje się i nigdy nie jest archiwizowany** (baza wiedzy, która rośnie). Cel: zamiast gubić
pochwały i inspiracje w koszu „No action", zbierać je w profil **„co ląduje u kogo i jak to reużyć"** —
narzędzie do świadomego podnoszenia zadowolenia stakeholderów, nie pamiętnik anegdot.

**Gdzie:** osobny folder (config per-projekt, typowo `Delight/`), jedna **żywa kolekcja** (`type: delight-log`)
z widokiem `*.base` **grupowanym per-osoba** (`groupByProperty: person`) — profile budują się same.

**Dwa wejścia:**
1. **Auto — z fazy ACT sweepu.** Dyspozycja `Capture → Delight` dopisuje wpis. Źródło = link do node/wątku Figmy.
2. **Ręczny gest** — „zapisz do delight" (Slack, call, DM — kanały, których sweep nie czyta). Idź prosto tu,
   pomiń resztę protokołu; źródło = skąd sygnał (np. „Slack #design 07-21", „call z Tomem").

**Wpis (MUST — 6 pól; bez dwóch ostatnich to pamiętnik, nie narzędzie):**
| Pole | Co |
|---|---|
| **Kto** | osoba z teamu — tag `#osoba` (buduje profil; np. `#tom` `#dominique`) |
| **Co się spodobało** | verbatim komentarz (z żywego fetcha) lub zwięzły opis sygnału |
| **Na czym** | ekran / decyzja / element / deliverable (+ link do node Figmy jeśli jest) |
| **Dlaczego zadziałało** | interpretacja — sedno wartości, nie sam cytat |
| **Jak reużyć** | konkretny pattern do powtórzenia gdzie indziej |
| **Data + źródło** | `YYYY-MM-DD` + skąd (link Figma / kanał) |

**Zasady:**
- **Trwałość:** nigdy nie oznaczaj `done`, nie przenoś do `Done/`, nie kasuj. Kolekcja rośnie w nieskończoność.
- **Verbatim tylko z żywego fetcha** (ta sama reguła co w rejestrze — patrz Gotchas), nie z pamięci.
- **Frontmatter** wg schematu niżej; `person` jako property (nie tylko tag inline) → działa `groupByProperty`.
- **Propose-first** — wpis pokaż przed zapisem, jak każdy zapis do vaultu.
- Delight **nie** tworzy karty na Kanbanie (to nie trigger do pracy) i **nie** rusza rejestru feedbacku.

**Frontmatter kolekcji:**
```yaml
type: delight-log
scope: <projekt / zakres>        # np. "antisis — internal team"
updated: <ISO>                   # ostatni dopisany wpis
```
(Brak `status`/`last-swept`/`closed` — kolekcja nie ma cyklu życia; jest wieczna.)

## Propose-first (dyscyplina zapisu)
Każdy zapis do vaultu pokazuj **najpierw jako propozycję**, czekaj na OK.
- Pokaż diff/wstawkę zanim utworzysz lub nadpiszesz notatkę rejestru.
- **Nie** postuj odpowiedzi ani nie resolve'uj wątków w Figmie sam — to robi człowiek.
- Drafty odpowiedzi przygotuj w rejestrze; właściciel kanału decyduje, co i kiedy wklei.
- **Komentarz należący do aktywnego epica/wątku (otwarte sub-taski) → wstrzymaj draft opisujący rozwiązanie do KOŃCA wątku.** Zaloguj i sklasyfikuj item, ale finalny draft odpowiedzi (opis rozwiązania) twórz dopiero gdy cały wątek jest zbudowany — inaczej odpowiedź się zdezaktualizuje, gdy rozwiązanie się zmieni. (Reguła epica: skill `obsidian-kanban` → „Epiki".)
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
- **Cytat „verbatim" WYŁĄCZNIE z żywego fetcha** — nigdy z pamięci poprzedniego przebiegu, kontekstu
  po kompakcie ani z wcześniejszego rejestru. Przy wznowieniu rejestru re-fetchnij komentarze
  (`figma_get_comments`) ZANIM cokolwiek zacytujesz; każdy cytat musi mieć 1:1 odpowiednik w surowych
  danych. (Audyt użycia 2026-07: potwierdzona konfabulacja „verbatim" cytatów w rejestrze z 06-29.)
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
Jeśli sweep promował pozytyw → linia: „**Delight: N wpisów → `[[Delight — …]]`** (kto)", żeby te sygnały
nie umknęły tak samo jak karta-wskaźnik.
