---
name: obsidian-kanban
description: Obsługa tablicy zadań w Obsidianie (Bases kanban-view) — digest stanu, tworzenie/przesuwanie/archiwizacja kart, triage inboxu, promocja itemów z backlogu na tablicę. Uruchamia się gdy user mówi (EN+PL) "co mam na kanbanie", "pokaż tablicę", "co in progress", "dodaj/przesuń kartę", "oznacz jako done", "zarchiwizuj kartę", "ztriażuj lab", "zrób porządek na tablicy", "kanban" — lub po angielsku "show the board", "what's in progress", "add/move a card", "mark done", "kanban".
---

# Skill: obsidian-kanban

## Cel
Pracować z tablicą zadań w Obsidianie (Obsidian **Bases**, `kanban-view`) tak, by Claude mógł ją czytać i
aktualizować: pokazać stan, założyć kartę, przesunąć ją między kolumnami, ztriażować inbox pomysłów,
podlinkować artefakty i **promować itemy z backlogu** (np. otwarte itemy z feedback-sweepu) na tablicę.

## Auto-trigger
- "co mam na kanbanie" / "pokaż tablicę" / "stan tablicy" / "co in progress"
- "dodaj zadanie" / "nowa karta" / "przesuń kartę" / "oznacz jako done"
- "ztriażuj lab" / "zrób porządek na tablicy" / "ogarnij inbox"
- "wrzuć te itemy na kanban" / promocja z backlogu/feedbacku

## Wymagania i kanał zapisu (TWARDY)
- Karty to **zwykłe pliki markdown** — kanon zapisu to **bezpośrednia edycja pliku na ścieżce vaultu** (Read/Edit/`mv`), nie REST API. Powód: udokumentowana historia korupcji frontmattera przez Local REST API/MCP (quoted-string bug → `status: '"Done"'`, kolumny-duchy w `.base`; research 2026-07-14) + zero kosztu tokenowego roundtripów.
- **MCP `obsidian`** (`mcp__obsidian__*`) zostaje jako kanał pomocniczy: search, `open_in_ui`, odczyt gdy wygodny. **Frontmattera (w tym `status`) NIGDY nie pisz przez `manage_frontmatter`.**
- Brak dostępu do plików vaultu → najpierw skill `obsidian-setup`.
- **`.base` edytuj tylko przy zamkniętym Obsidianie** — Bases trzyma stan widoku w pamięci i nadpisuje plik (edycja przy otwartej appce = po chwili cofnięta).
- **Tablica = plik `.base`** z `kanban-view`. Skill **odkrywa strukturę z `.base`** — nie zakłada wcześniej kolumn. Brak `.base` w projekcie → nie zgaduj; powiedz userowi i zaproponuj utworzenie boardu (propose-first).
- **Tryb chmurowy (Claude Code na web) — kanał zapisu to git, nie ścieżka vaultu.** Gdy vault jest sklonowanym repo git (brak Local REST API i lokalnej ścieżki vaultu), kartę tworzysz/przesuwasz **edycją pliku w klonie → commit → push → MERGE do `main`**. **Karta pojawi się na desktopie DOPIERO po merge do `main`** — sam push na gałąź `claude/...` nie wystarczy (Obsidian Git ciągnie tylko bieżącą gałąź desktopu i nie przełącza jej sam). Mechanika kanału chmurowego + ustawienia Obsidian Git: skill `obsidian-setup`.

## Krok 0 — odczytaj board z `.base` (NIE hardcoduj kolumn)
Tablice różnią się per-projekt. Zanim cokolwiek zrobisz, przeczytaj plik `.base` i ustal:
- **folder kart** (`filters: file.folder == "…"`) i co jest wykluczone (sam plik `.base`),
- **property grupujące** (`groupByProperty`, zwykle `note.status`),
- **słownik i kolejność kolumn** (`columnOrders.<prop>`) + kolory (`columnColors`).

Przykład (Manta): `KANBAN/-Kanban Board.base` · grupa `note.status` · kolumny `Lab → To-do → In progress → To confirm → Done`.
**Karta = notatka w folderze** z property grupującym we frontmatter. Brak property → karta wpada do „Uncategorized".

## Semantyka kolumn (czytaj z configu boardu — nie zakładaj)
Każdy board ma swoje znaczenia; dla danego boardu czytaj je z notatki semantyki / `CLAUDE.md`. Wzorzec (Manta):
- **Lab** — lodówka/inbox pomysłów: *do zbadania* · *przemyślenie* · *możliwy projekt*. **NIE backlog do zrobienia** — dopóki item nie jest gotowy do uruchomienia, zostaje w Lab.
- **To-do** — zadania **gotowe do uruchomienia**: opisane na tyle, że agent/sesja może wziąć i realizować **bez dopytywania** (jasny cel + zakres). Kolejność = priorytet. Tag `high-priority` = przed resztą. **Karta, która okazała się zablokowana, nie zostaje w `To-do` — idzie do `To confirm` z tagiem `blocked`** (patrz niżej). **Bramka Lab→To-do:** „czy da się to wziąć do pracy jak jest?" — jeśli nie, zostaje w Lab.
- **In progress** — **dopiero gdy karta jest wzięta do pracy lub realizowana.** Wzięcie = claim lockiem (`kanban-claim.sh`) + pole `claimed:` we frontmatterze → widać, że pracuje nad nią agent/sesja (wątek wieloagentowy). „Zaraz zacznę" ≠ In progress → trzymaj na **górze `To-do`**.
- **To confirm** — **wszystko, co czeka na czyjś ruch, a nie na mój**: potwierdzenie/decyzja Piotra lub stakeholdera, zebranie feedbacku, ORAZ **każda karta `blocked`** (zewnętrzna blokada, wysłane pytanie, cudza odpowiedź) — **niezależnie od tego, czy robota po naszej stronie jest domknięta**. W karcie **zawsze** dopisz *co/kto* blokuje. Dwa wyjścia z To confirm: potwierdzenie OK / blokada spadła → `Done` albo powrót do `To-do`/`In progress` (zdejmij wtedy tag `blocked`); „zmień X" → `To-do`/`In progress`.
  - **Dlaczego blocked NIE zostaje w `In progress`** (decyzja Piotra 2026-07-29, odwrócenie wcześniejszej reguły): `In progress` ma pokazywać **realny WIP**. Karty stojące na czyjejś odpowiedzi zaśmiecały widok tego, nad czym faktycznie się pracuje, i kolumna przestawała być wiarygodna. `To confirm` = jeden kubełek na „nie jest w moich rękach".
- **Done** — zrobione, karta **opisana rezultatem**: sekcja `## Rezultat` (co zrobione + link do artefaktu/PR/Figma). Przy przejściu na Done stempluj **`done_at: YYYY-MM-DD`**. Kandydat do **promocji do vaultu** (`obsidian-capture`). **Auto-archiwum:** karta Done starsza niż **30 dni** (od `done_at`) ma być przenoszona do folderu archiwum przez `kanban-archive.sh` — ale **na 2026-07-31 ten automat NIE DZIAŁA** (LaunchAgent zablokowany przez TCC, patrz operacja G); do czasu przepięcia na działający kanał archiwizuj ręcznie. Archiwizacja nieniszcząca (`mv`), notatka żyje. **Nie kasuj.**

## Współbieżność — protokół claim (TWARDY; sesje bywają równoległe)
Równolegle chodzi 2–4 sesje na jednej tablicy — digest boardu w kontekście sesji jest natychmiast przeterminowany. **Sama edycja frontmattera to za mało** (read-then-write race: dwie sesje czytają „wolne" i obie piszą claim; sesja która pominie claim — realny przypadek 2026-07-20 — omija protokół i robi duplikat). Dlatego mutex to **atomowy lock**, nie pole w YAML.

**Mechanizm = `kanban-claim.sh` (mkdir-lock we wspólnym vaultcie).** `mkdir` jest atomowy — druga sesja dostaje błąd, nie „obie widzą wolne". Frontmatter `claimed:` zostaje jako **czytelne lustro dla człowieka** (widok WIP w digest), ale ŹRÓDŁEM PRAWDY jest lock. Ścieżka helpera (absolutna, cross-project): `/Users/piotrkozlowski/Documents/piotr-toolkit/plugins/obsidian-toolkit/scripts/kanban-claim.sh`. `<kanban_dir>` = folder kart z Kroku 0. `<session_id>` = id tej sesji (hook zna je z `.session_id`; gdy odpalasz ręcznie — dowolny stabilny znacznik sesji).

- **Wzięcie karty (KAŻDE — „następne z kanban" I bezpośredni handoff):**
  1. `kanban-claim.sh claim "<kanban_dir>" "<nazwa karty bez .md>" "<session_id>" "krótki opis"`
  2. **exit 0** → lock Twój: ustaw `status: In progress` + `claimed: <YYYY-MM-DD HH:MM · sesja>` w pliku, pracuj.
  3. **exit 3** (TAKEN — cudzy żywy lock) → **STOP.** Nie bierz, nie proponuj. Powiedz userowi „karta zajęta przez inną sesję".
  4. **exit 4** (STALE — cudzy lock >2 dni) → pokaż userowi, zapytaj czy tamta sesja żyje; przejęcie tylko na jego OK: `kanban-claim.sh steal …`.
- **Karta, którą SAM tworzysz i od razu na niej pracujesz — też wymaga claima (TWARDA, 2026-07-31).** To jedyna ścieżka, której hook złapać NIE MOŻE: zakłada lock na podstawie nazwy karty **w promptcie usera**, a kartę utworzoną mid-session żaden prompt nigdy nie nazwał. Dla Ciebie to „autorstwo", nie „wzięcie karty", więc protokół wyżej się nie odpala — a dla innej sesji to zwykła, wolna karta w `To-do` i słusznie ją bierze. Stąd rozgałęzienie w momencie tworzenia karty:
  - **pracujesz na niej teraz** → `claim` + `status: In progress` + `claimed:`, zanim napiszesz pierwszą linię;
  - **parkujesz na później** → zostaw `To-do` BEZ claima; brak locka jest właśnie sygnałem „wolne, bierzcie".
  *Koszt pominięcia (2026-07-31, karta długu lintowego): utworzyłem kartę i zacząłem pracę bez claima; równoległa sesja wzięła ją z `To-do` i dostarczyła szerzej (#117/#120/#121), a moje dwa pełne cykle roboty poszły do kosza. Mutex nie zawiódł — nikt go nie założył.*
- **Enforcement (nie licz na dyscyplinę):** projekt wpina `kanban-claim-guard.sh` jako **UserPromptSubmit** hook — na 1. turze wykrywa kartę w promptcie handoffu i zakłada lock atomowo; kolizja z żywą sesją = twardy STOP zanim ruszysz. Skill dokłada claim dla pickupów mid-session i ścieżek, których hook nie złapie.
- **Karta z cudzym claimem/lockiem = nietykalna** — nie bierz i nie proponuj jako następnej. Wyjątek: user wprost każe przejąć.
- **Zdjęcie locka:** przy każdym domknięciu rundy (→ `Done` / `To confirm` / powrót do `To-do`) uruchom `kanban-claim.sh release "<kanban_dir>" "<karta>" "<session_id>"` **oraz** usuń pole `claimed` z frontmattera. Stop-hook projektu dodatkowo **auto-zwalnia własne locki** kart, które nie są już `In progress` (siatka bezpieczeństwa gdy zapomnisz). Krok `session-retro` egzekwuje to na koniec sesji.
- **Tryb chmurowy / inna maszyna:** lock jest lokalny na maszynie (gitignored `.claims/`). Chroni sesje na **tej samej maszynie** (główny przypadek Piotra). Równoległa edycja tej samej tablicy z DWÓCH maszyn naraz nie jest chroniona lockiem — tam polegaj na świeżym odczycie + kanale git-merge.

## Autonomia — proponuj następne zadanie (domyślnie, bez proszenia)
Kanban ma działać bez usera-operatora. **Po każdym domknięciu karty (`Done`/`To confirm`) — w tej samej odpowiedzi — zaproponuj następną:**
1. Kandydat: **jeśli domknięta karta należy do epica → najpierw następny otwarty sub-task TEGO epica** (patrz „Epiki" niżej). W przeciwnym razie: karta `In progress` **bez claima** (wisząca robota), potem **góra `To-do`** (kolejność = priorytet, `high-priority` przed resztą). Pomijaj `blocked` i cudze locki/claimy.
2. Dobierz kanał: temat pokrewny bieżącej sesji → kontynuacja tutaj; temat odległy → zaproponuj **świeżą sesję** (czysty, tańszy kontekst).
3. To propozycja (propose-first) — nie zaczynaj nowej karty bez OK usera.

## Epiki — łańcuchowanie sub-tasków i domknięcie (zadania wielowątkowe)
Epic = duży temat rozbity na kilka kart. Cel z perspektywy pracy agentów: **zachować wspólny kontekst między drobnymi zmianami i pozwolić kolejnym sesjom realizować zadania z jednego wątku** — bez re-odkrywania kontekstu za każdym razem.

**Kiedy tworzyć epic (bramka):** temat wymaga **> 2–3 kart** **lub** będzie realizowany przez **wiele sesji sekwencyjnie** **lub** chcesz **zachować wspólny kontekst** między powiązanymi drobnymi zmianami. Pojedynczy task → **nie** epic (nadmiarowy overhead). Zwykle epic wyłania się, gdy jedna karta pączkuje w kilka powiązanych — wtedy zakładasz kartę-epic i podpinasz istniejące pod nią.

**Model:**
- **Karta-epic** `EPIC · <nazwa>` (`status: In progress` dopóki żyje którykolwiek sub-task) = **indeks + wspólna pamięć wątku**, nie robota. W treści trzyma: **cel epica, listę sub-tasków w kolejności, wspólne decyzje i kontekst** — to jest to, co **czyta każda następna sesja** zanim weźmie kolejny sub-task (żeby nie odtwarzać kontekstu od zera). Aktualizuj tę treść przy domykaniu każdego sub-taska (co zrobione, co dalej).
- **Sub-task** = osobna karta z polem frontmattera **`epic: "[[EPIC · <nazwa>]]"`** (wikilink w cudzysłowach — patrz gotcha YAML) + backlink w treści. To pole czyni łańcuch **queryowalny** bez parsowania treści. Realna robota (i claim/lock) żyje **tu**, nie na karcie-epicu.
- Kolejność sub-tasków: jeśli karta-epic ma w treści listę/sekwencję — trzymaj się jej; inaczej priorytet = kolejność w `To-do` (`high-priority` pierwsze).
- **Drafty odpowiedzi na zewnątrz (Linear/Figma) = na KONIEC wątku, NIE per-sub-task (TWARDE).** Póki epic ma otwarte sub-taski, **nie** twórz draftu komentarza/opisu opisującego rozwiązanie — rozwiązanie może się jeszcze zmienić i komentarz się zdezaktualizuje. Draft powstaje **dopiero gdy cały wątek jest zbudowany** (wszystkie sub-taski domknięte). W trakcie: zbieraj materiał w karcie/epicu, ale wstrzymaj draft. Gate przy samym draftowaniu żyje w skillach `linear-ticket-draft` i `obsidian-feedback-sweep`.

**Przy domknięciu sub-taska (`Done`/`To confirm`) — w tej samej odpowiedzi:**
1. Odczytaj `epic:` z domykanej karty. Zbierz rodzeństwo: karty z tym samym `epic:`.
2. **Zostały otwarte sub-taski** (`To-do`/`In progress`, bez cudzego locka, nie `blocked`)? → zaproponuj **następny** (sekwencja epica lub góra `To-do`). Dobór kanału (kontynuacja vs świeża sesja) jak w „Autonomia".
3. **Wszystkie sub-taski domknięte** (brak otwartego rodzeństwa)? → zaproponuj **domknięcie epica**: karta-epic → `Done`/`To confirm`, potem rozstrzygnięcie promote/archive (operacja G). Propose-first — nie zamykaj epica sam.
4. Zdejmij lock sub-taska (release, patrz protokół claim).

**Gotchy epica:**
- Karta-epic nie jest „claimowalną robotą" — nie bierz jej jako zadania do wykonania; to indeks. Lock zakładaj na sub-taski.
- Nie zamykaj epica póki wisi choć jeden otwarty sub-task (nawet `blocked` — wtedy epic zostaje `In progress`, zgłoś blokadę).
- Sub-task bez pola `epic:` ale z `[[EPIC · …]]` tylko w treści → przy okazji dopisz `epic:` do frontmattera (łańcuch ma działać z pola, nie z parsowania prozy).

## Operacje

### A) Digest stanu (read-only, token-safe)
Czytaj **tylko frontmatter** kart (status, tags, tytuł) — nie całe treści (oszczędność tokenów).
Zbuduj podsumowanie **per kolumna** w kolejności z `.base`. Wyróżnij:
- **In progress** (realny WIP) i **To confirm** (kolejka usera — czeka na omówienie/feedback),
- karty z tagiem `high-priority` oraz **`blocked`** (te ostatnie wypisz osobno — co je blokuje),
- **Lab** = inbox (policz ile czeka na triage), **Done** = ilu kandydatów do promocji/archiwizacji,
- karty z `claimed` — wypisz kto/kiedy (widok WIP między sesjami).

**Lint statusów (obowiązkowa część digestu):** porównaj `status` każdej karty ze słownikiem `columnOrders` z `.base` — dokładny match, case-sensitive, bez cudzysłowów. Wartość spoza słownika → ⚠️ z propozycją poprawki; kolumny-duchy w `cardOrders` (np. `'"Done"'`, `To-Do`) → zaproponuj sprzątnięcie (przy zamkniętym Obsidianie).

### B) Utwórz kartę (propose-first)
Nowa notatka w folderze tablicy, frontmatter `status: <kolumna>` (+ opcjonalne `tags`). Tytuł = nazwa pliku.
Jeśli nadajesz **nowy** status (spoza słownika) — dopisz go do `columnOrders` w `.base`, inaczej nie pojawi się w kolejności.

### C) Przesuń kartę (propose-first)
Zmień **wartość property grupującego** we frontmatter (np. `status: To-do` → `In progress`).
**Nie zmieniaj nazwy pliku** do sygnalizacji stanu — stan żyje w property (rename psuje `[[linki]]`).
- **→ In progress:** karta jest wzięta do pracy → claim lockiem + ustaw `claimed:` (patrz protokół claim).
- **→ Done (TWARDE):** (1) wypełnij sekcję `## Rezultat` — co zrobione + link do artefaktu; (2) ustaw `done_at: <dziś>`; (3) zdejmij lock (release) i usuń `claimed`. Bez `## Rezultat` i `done_at` karta jest niekompletna — `done_at` napędza auto-archiwum, rezultat to pamięć zespołu.

### D) Triage inboxu „Lab" (3 kubełki)
Dla każdej wrzutki (często goły link) w jednej linii **co to jest** → przypisz kubełek + rekomendacja:
- *do zbadania* → akcjonowalne: **promuj do `To-do`** (z 1-liniowym „po co"),
- *przemyślenie* → referencja: **zostaw w Lab** (ewentualnie → vault, jeśli warte zapamiętania),
- *możliwy projekt* → kandydat na decyzję: **zostaw + oznacz do omówienia**, albo **odrzuć**.
Wzbogać kartę o 1-liniowy opis. Wszystko propose-first.

### E) Podlinkuj artefakty
Dodaj do karty backlinki: vault doc, plik/board Figma (URL), repo/PR. Wikilinki we frontmatter **tylko listą i w cudzysłowach** (patrz gotcha).

### F) Promuj z backlogu/feedbacku → tablica
Most między skillami: weź itemy z notatki backlogu (np. `Open items …` z feedback-sweepu) i załóż z nich karty
(`status: To-do`, tag jeśli priorytet), z backlinkiem do źródła. Propose-first; pokaż listę kart przed zapisem.

### G) Domknięcie karty „Done" → promote/archive (hook do `obsidian-capture`)
Gdy karta trafia/jest w `Done` i jest potwierdzona, zaproponuj rozstrzygnięcie (propose-first):
- **warte pamięci dla zespołu** (decyzja / spec / koncept) → **promuj do vaultu** (`obsidian-capture`) jako trwały dok we właściwym folderze, **potem zarchiwizuj kartę**;
- **pozostałe** → **zarchiwizuj kartę** od razu.

**Archiwizacja = przenieś plik karty do folderu archiwum boardu** (per-board config, np. `<folder boardu>/Archive`) — **nigdy nie kasuj do Trash ani nie usuwaj pliku**. Zasada: *archiwizuj, nie kasuj* — nie tracimy zapisu tego, co zrobione (karty Done często mają w treści cenny status realizacji).
- **Mechanizm:** board filtruje po **dokładnym** folderze (`file.folder == "<folder>"`), więc karta w podfolderze archiwum **automatycznie wypada z tablicy**, a notatka żyje. Status we frontmatter staje się wtedy martwy — ustaw go na `Done` (czytelny ślad), nie zostawiaj `Trash`.
- **⚠️ Jak przenieść — `mv` na filesystemie, NIE „write nowej ścieżki + delete starej".** MCP `obsidian` **nie ma operacji move/rename**; emulacja przez `write_note(nowa ścieżka)` + `delete_note(stara)` to dwa kroki i ryzyko **osieroconego duplikatu**, gdy destrukcyjny `delete` zostanie anulowany. Zamiast tego: najpierw ustaw `status: Done` bezpośrednią edycją pliku, **potem** `mv "<vault>/<folder>/Karta.md" "<vault>/<folder>/Archive/"` — jeden atomowy ruch (sync zrobi resztę). Mechanika dwóch kanałów: skill `obsidian-setup`.
- **Brak folderu archiwum** w configu boardu → zaproponuj jego utworzenie (propose-first), nie improwizuj.
- **Brak kolumny „Trash"** na boardzie — to relikt; domknięcie idzie do folderu archiwum, nie do kolumny.

**Egzekucja (twarda):** rozstrzygnięcie proponuj **od razu, w tej samej odpowiedzi**, w której karta
przechodzi na `Done` — konkretna rekomendacja per karta (promuj / archiwizuj + dlaczego), propose-first.
NIE otwarte „archiwizacja opcjonalna, daj znać jeśli chcesz posprzątać" (audyt użycia 2026-07: miękka
wersja = 0 promocji przez 6 tygodni, `Done` puchnie).

Cel: `Done` nie puchnie, a żaden zapis nie ginie.

**Auto-archiwum Done po 30 dniach (mechanizm cron — nie ręczny):** karty w `Done` z `done_at` starszym niż 30 dni są **automatycznie** przenoszone do folderu archiwum boardu. Realizuje to skrypt `kanban-archive.sh` (obok `kanban-claim.sh` w `…/obsidian-toolkit/scripts/`), odpalany codziennie przez cron/launchd na maszynie Piotra. Zasada działania:
- skanuje folder kart boardu, dla każdej `status: Done`:
  - **brak `done_at`** (karta legacy) → stempluje `done_at: <dziś>` (rusza zegar; NIE archiwizuje od razu),
  - **`done_at` starsze niż 30 dni** → `mv` do `<folder boardu>/Archive/` (nieniszcząco; karta wypada z tablicy przez filtr `file.folder`).
- **Skrypt jest nieniszczący** (tylko `mv` + stempel daty) i idempotentny — bezpieczny do codziennego runu. **Ręczna archiwizacja z operacji G nadal obowiązuje** dla świeżo domkniętych kart wartych natychmiastowego sprzątnięcia; cron to siatka bezpieczeństwa na to, co zostanie.
- Setup crona per-maszyna (crontab/launchd) + weryfikacja: patrz nagłówek skryptu `kanban-archive.sh`.
- **⚠️ LaunchAgent NIE JEST działającym kanałem dla vaultu w `~/Documents` (zmierzone 2026-07-31).**
  macOS TCC blokuje procesy odpalone przez `launchd` na katalogach chronionych — probe z realnymi
  operacjami (nie `[ -r ]`, które **kłamie** pod TCC) dał `read: DENIED`, `list dir: DENIED`.
  `com.piotr.kanban-archive.plist` był załadowany i odpalał się codziennie, a jego log zawiera
  wyłącznie `Operation not permitted` — czyli **auto-archiwum nigdy nie zadziałało**, wyglądając
  na skonfigurowane. To ta sama klasa co „martwy check": zaplanowany automat bez sprawdzonego
  logu jest nieodróżnialny od działającego-cichego.
  **Działający kanał = zadanie w `scheduled-tasks` aplikacji Claude** (aplikacja ma dostęp do
  dysku, więc czyta i zapisuje vault normalnie) albo nadanie Full Disk Access temu, co odpala
  skrypt — to drugie jest szerokim uprawnieniem i wymaga świadomej zgody, nie cichego obejścia.
  **Zakładasz automat na vault → sprawdź LOG po pierwszym odpaleniu, zanim uznasz go za zrobiony.**

**Promocja `Open items` z feedback-sweepu (opcjonalna, inicjowana z kanbana — NIE automatyczna):** feedback-sweep nie tworzy żadnych kart na tablicy. Jeśli chcesz, możesz **ręcznie** wziąć leftovers z notatki `Open items …` (`type: concept-backlog`) i wypromować je na board operacją F.

## Propose-first (dyscyplina zapisu)
To wspólny vault pracy — **każdy zapis pokazuj najpierw jako propozycję**, czekaj na OK:
- tworzenie/przesuwanie kart, triage, edycja `.base` — diff/lista przed zapisem,
- przy wielu kartach naraz pokaż zbiorczą listę „co powstanie / co się przesunie".

## Karta — schemat
```
---
status: <kolumna ze słownika boardu>
claimed: <YYYY-MM-DD HH:MM · sesja>   # lustro locka (źródło prawdy = kanban-claim.sh); zdejmij przy domknięciu
epic: "[[EPIC · <nazwa>]]"            # tylko sub-task epica — czyni łańcuch queryowalnym
related:                              # opcjonalnie — cross-cutting linki, patrz sekcja "Powiązania" niżej
  - "[[Inna karta]]"
linear: MAN-833                       # opcjonalnie — klucz ticketu Linear, NIE url, NIE kopia stanu
done_at: <YYYY-MM-DD>                 # tylko karta Done — stempel wejścia w Done; auto-archiwum liczy 30 dni od tej daty
tags: [high-priority]        # opcjonalnie; wikilinki we frontmatter → lista w cudzysłowach
---

<treść: 1-liniowy opis + linki do artefaktów ([[doc]], Figma URL, repo)>

## Rezultat        <!-- wypełniane przy przejściu na Done: co zrobione + link do artefaktu/PR/Figma -->
```

## Powiązania — `related:` i `linear:` (⚠️ hipoteza z jednej sesji, nie utwardzona doktryna)

**Status:** wzorzec wypróbowany na **jednym** boardzie (antisis-prototype, 2026-08-14, backfill na 5 kartach) bez obiektywnego checku, że jest ogólnie lepszy — zgodnie z regułą „ewolucja skilla tylko przez validation-gate" (globalny CLAUDE.md), traktuj to jako **do potwierdzenia**, nie jako zamknięty kanon. Zanim rozszerzysz to na kolejny board, sprawdź czy ten board w ogóle ma taki problem (rozproszone powiązania między kartami, ticket Linear wspominany tylko w prozie) — jeśli nie, nie wymuszaj pól „bo tak robi inny projekt".

**Motywacja (dowód, nie tylko intuicja):** `.base` boardu antisis-prototype ma już zdefiniowany drugi wymiar grupowania — klucz `"note.status\x1fnote.related"` w `cardOrders`/`swimlaneOrders` — ale żadna karta nigdy nie ustawiała property `related`, więc ten swimlane nigdy się nie aktywował. To **nie jest nowy mechanizm Bases** wymyślony tu — to odblokowanie już istniejącej konfiguracji przez wypełnienie pola, które dotąd było puste. Przed dodaniem tych pól na innym boardzie sprawdź analogicznie jego `.base` — może mieć ten sam martwy swimlane albo nie mieć go wcale (wtedy `related:` nadal wolno użyć jako czystego tekstowego pola, ale bez efektu na grupowanie).

- **`related:`** — lista wikilinków w cudzysłowach (ten sam gotcha co inne wikilinki w YAML — nigdy plain `[[A]], [[B]]`) do kart powiązanych tematycznie, ale **poza** relacją epic/sub-task: spun-off-from, blocks/unblocks, ten sam temat widziany z innej karty. Różnica względem `epic:` — `epic` koduje **hierarchię** (jedna karta-indeks + jej sub-taski, patrz sekcja „Epiki"); `related` koduje **płaską sieć** cross-cutting powiązań, która może przecinać epiki albo łączyć karty bez żadnego epika.
- **`linear:`** — plain string, **sam klucz** ticketu Linear (`MAN-833`), NIE cały URL i NIE kopia tytułu/stanu ticketu. Klucz się nie starzeje; skopiowany stan tak — gdy potrzebny aktualny stan ticketu, query Linear MCP po tym kluczu w danym momencie, nie czytaj z karty.

**Kiedy dopisywać (dziś osąd, nie zautomatyzowany check):** gdy treść karty już zawiera `[[wikilink]]` do innej karty w roli spun-off-from/blocker/ten-sam-temat i nie jest to epic-relacja → przenieś referencję też do `related:`, żeby była queryowalna, nie tylko czytelna w prozie. Gdy karta ma odpowiadający ticket Linear, a pola `linear:` jeszcze nie ma → dopisz klucz.

**Kiedy NIE dodawać (żeby nie rozjechać się z `epic:`):** jeśli powiązanie to epic↔sub-task, zostaje w `epic:` — nie duplikuj tego samego linku też w `related:`.

## Gotchas
- **Odkryj kolumny z `.base`** — nie hardcoduj; boardy różnią się słownikiem (Manta: Lab/To-do/In progress/To confirm/Done).
- **Status = frontmatter, nie nazwa pliku.** Rename do sygnalizacji stanu psuje linki.
- **Słownik statusów jest ZAMKNIĘTY — nie wymyślaj nowych kolumn.** Karta dostaje status wyłącznie ze słownika `columnOrders` w `.base`. „Zrobię później / de facto backlog" = **`To-do`** (kolejność = priorytet), NIE nowy status typu „Backlog" (realny przypadek 2026-07-14: sesja dodała kolumnę `Backlog` samowolnie). Nową kolumnę wolno dodać tylko na wyraźne polecenie usera — wtedy status + wpis do `columnOrders` (inaczej nie pojawi się w kolejności).
- **Wikilinki w YAML** — `klucz: [[A]], [[B]]` to niepoprawny YAML → notatka traci property → wypada z boardu.
  Zawsze listą: `klucz:\n  - "[[A]]"`.
- **Karta bez property grupującego** → „Uncategorized". Na create zawsze ustaw status.
- **`#` w NAZWIE PLIKU karty = zakaz** (i szerzej `^ [ ] |` — znaki, których Obsidian nie dopuszcza w nazwach notatek, bo łamią linki i anchory). Numer PR/issue zapisuj jako `(po PR 131)`, nie `(po #131)`. Powód nie jest kosmetyczny: ścieżka z `#` **wpisana bez cudzysłowów** do `cardOrders` w `.base` to dla YAML komentarz — `- KANBAN/Karta (po #131).md` parsuje się jako `KANBAN/Karta (po`, więc kolejny czytający produkuje kartę-widmo pod uciętą nazwą. Zmierzone 2026-07-31 na boardzie Manta: jedna karta wystąpiła jako **3 pliki** — realny `(po #131).md`, stub `(po.md` (22 B, sam `status:` → drugi kafel w To-do) i `(po 1.md` (0 B, bez frontmattera → kolumna Uncategorized); w tym samym commicie backupu vaultu doszedł niecytowany wpis w `.base`. Napotkasz `#` w nazwie → przemianuj kartę (`mv`) i popraw wpis w `.base`, nie tylko posprzątaj duplikaty. Wpis w `.base` pisany skryptem musi być **cytowany**, gdy nazwa nie jest plain-safe (`kanban-place-card.sh` to robi; eval 009).
  - **Nazwę karty przepuść przez `kanban-card-name.sh` PRZED utworzeniem pliku** — `kanban-card-name.sh sanitize "<tytuł>"` zwraca bezpieczną nazwę (`#488` → `PR 488`), `check` zwraca exit 2 na niebezpiecznej. `kanban-place-card.sh` **odmawia** umieszczenia karty o niebezpiecznej nazwie (exit 1 + gotowa komenda `mv`), zamiast obejść problem cytowaniem. **Why:** sama reguła nie wystarczyła — 2026-08-25 powstała karta `Ogon po #488 …` **z poprawnie cytowanym** wpisem w `.base`, a i tak dała 0-bajtową kartę-widmo `Ogon po.md` i wikilink, który Obsidian czytał jako notatkę „Ogon po " + anchor „488 …". Cytowanie ratuje `.base`, nie nazwę — dwa z trzech objawów siedzą poza tym plikiem.
- **Digest stosuje filtry z `.base`** (np. `file.name != "…"`) — nie listuj folderu na ślepo, bo pokażesz wykluczone notatki jako fałszywe „Uncategorized".
- **Notatka nie-karta w folderze boardu** (np. referencyjna „jak pracuję") → **wyklucz w filtrze `.base`** (`file.name != "…"`, bez rozszerzenia), nie zostawiaj jako Uncategorized.
- **Archiwizacja przenosi plik — `mv` na filesystemie, nie REST copy+delete** (MCP nie ma move; copy+delete grozi osieroconym duplikatem — patrz sekcja archiwizacji + `obsidian-setup`). `mv` nie aktualizuje `[[backlinków]]` do karty (Obsidian robi to tylko przy move w UI). Karty Done zwykle są liśćmi (nikt do nich nie linkuje) — wtedy OK; jeśli karta jest celem linków, przenieś ją w UI Obsidiana.
- **Token-safety:** do digestu czytaj frontmatter, nie pełne treści kart.
- **Bases bywa wrażliwe** — po zmianach strukturalnych w `.base` zweryfikuj render w UI.
- **Adresowanie notatek w MCP `obsidian_*` — ZAWSZE obiekt `target`**: `{"target":{"type":"path","path":"KANBAN/Karta.md"}}`, nigdy płaskie `{"path":...}` — płaski kształt to gwarantowany `MCP error -32602 Input validation error` i pusty przebieg (audyt użycia 2026-07: 0/8 operacji udanych za 1. podejściem przez ten błąd, rekord 5 nieudanych `write_note` z rzędu). Dotyczy `get_note`/`write_note`/`patch_note`/`append_to_note`/`replace_in_note`.
- **Frontmatter (w tym `status`) pisz WYŁĄCZNIE bezpośrednią edycją pliku — NIGDY `manage_frontmatter set`.** Udokumentowany bug REST API zapisuje quoted string (`status: '"To confirm"'`) → wartość nie matchuje słownika, karta wypada z grupy, a Bases utrwala kolumnę-ducha w `.base` (sprzątane 2026-07-14). Kanał zapisu: sekcja „Wymagania".

## Raport
Po operacji: co się zmieniło (utworzone/przesunięte karty, ztriażowane wrzutki), nowy rozkład kolumn,
co czeka na Twoją decyzję (kolumna „To confirm" / itemy wymagające inputu).
