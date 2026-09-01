---
name: session-retro
description: Retrospektywa sesji — podsumowanie co zrobiono, aktualizacja memory projektu, wyłapanie cross-project lessons learned. Uruchamia się gdy użytkownik mówi "zakończ sesję", "kończymy", "tyle na dziś".
---

# Skill: session-retro

## Cel
Na koniec sesji: zapisać to co warto zapamiętać do memory, wyłapać cross-project lessons,
zasugerować commit jeśli są zmiany. Nie pozwolić żeby wiedza z sesji przepadła.

## Auto-trigger
Uruchamia się gdy użytkownik mówi:
- "zakończ sesję" / "kończymy" / "tyle na dziś"
- "skończmy" / "kończę na dziś" / "koniec"
- "zrób retro" / "podsumuj sesję"

## Protokół (5 kroków)

Jesteś wykonawcą doktryny pamięci — schemat wpisu, typy i reguła promocji są w `memory-discipline`.
Zastosuj je tutaj; nie wymyślaj własnego formatu.

### 1 — Podsumuj sesję
2–4 zdania: co zrobiono, co zostało otwarte. Bez lania wody.

### 1b — Sync kanbana (OBOWIĄZKOWY, jeśli sesja dotykała zadań z tablicy)
Retro bez tego kroku = główna przyczyna kart-sierot na `In progress` (diagnoza 2026-07-14).
Dla **każdej karty dotkniętej w tej sesji** zaproponuj rozstrzygnięcie wg semantyki kolumn
(skill `obsidian-kanban`):
- zrobione → `Done` (od razu z rekomendacją promote/archive),
- nasza część gotowa, czeka na kogoś/feedback → `To confirm`,
- niedokończone → `In progress` zostaje TYLKO gdy praca realnie wraca; inaczej **góra `To-do`**.
Zdejmij `claimed` z każdej domykanej karty. Na końcu zaproponuj następne zadanie z tablicy
(sekcja „Autonomia" w `obsidian-kanban`). User akceptuje całość w ramach retro — pokaż listę zmian, wykonaj po OK.

### 2 — Wyłap kandydatów do zapamiętania
Przejrzyj sesję pod kątem wiedzy, która przepadnie jeśli jej nie zapiszesz: nowe konwencje,
gotchy, decyzje „dlaczego tak", preferencje usera, nieoczywiste ścieżki/URL-e. Pomiń to, co repo
już zapisuje (struktura kodu, historia git, treść CLAUDE.md).

### 3 — Promuj każdy kandydat do WŁAŚCIWEJ warstwy (reguła promocji z `memory-discipline`)
- **stabilna reguła / konwencja projektu** → `CLAUDE.md` projektu
- **decyzja „dlaczego tak"** → nowy ADR w `docs/decisions/` (jeśli projekt go ma)
- **cross-project lesson / preferencja / dane wrażliwe** → warstwa 3 (prywatny `claude-memory`)
- **ulotny kontekst projektu** → `.claude/memory/` (wpis wg schematu `metadata.type`, linia w `MEMORY.md`)

Aktualizuj istniejący wpis zamiast tworzyć duplikat; usuń wpis, który okazał się błędny.

### 3b — Sweep odpływu (retirement — lustro promocji, z `memory-discipline`)
Promocja przesuwa wiedzę w górę; bez tego kroku pamięć tylko rośnie. Przejrzyj `MEMORY.md` i:
- **Build-log zakończony** (`flow-*`/`man-*`/`fp-*`, shipped, brak open-items) → `mv` do `.claude/memory/_archive/` + usuń linię z indeksu.
- **Pointer-only / restatement** (treść już kanonem w docs/CLAUDE.md) → usuń.
- **„Pending" rozstrzygnięte** → zamknij/usuń.
- **Cap:** aktywnych wpisów > ~40 → wymuś konsolidację zanim dodasz nowe.

Build-logi **archiwizuj (`mv`), nie kasuj**. Propose-first przy niejasnych (czy na pewno brak open-items?).

### 4 — Zaproponuj commit
Jeśli są zmiany w repo (`git status`) — pokaż skrót i **zaproponuj** commit (nie commituj sam, chyba że
user prosił). Pamięć w `.claude/memory/` i ADR-y też idą do commita (są git-trwałe).

### 4a — Miesięczny sweep trafności decyzji (warunkowy — nie każde retro)
Cel: zamknąć pętlę „decyzja → efekt", której `memory-discipline` i held-out gate nie pokrywają (te
oceniają trafność reguł/skilli, nie tego, czy konkretna decyzja z przeszłości się opłaciła).

Uruchom TYLKO gdy od ostatniego przebiegu minęło ~30 dni. Datę ostatniego przebiegu trzymaj w
`.claude/memory/_decision-sweep-log.md` (jedna linia na przebieg: data + liczba przejrzanych). Brak
pliku = nigdy nie odpalany → odpal teraz.

Jeśli due:
1. Znajdź wpisy typu `project`/`feedback` starsze niż 30 dni, które zawierają jednoznaczną decyzję
   (nie samą obserwację) i nie były jeszcze oznaczone jako zweryfikowane.
2. Dla każdego: sprawdź obserwowalny efekt (czy warunek unieważnienia się spełnił, czy podejście
   nadal jest stosowane bez tarcia, czy zostało po cichu porzucone). Nie zgaduj — jeśli nie widać
   dowodu, zostaw jako „bez rozstrzygnięcia" i nie fałszuj wyniku.
   - **Trafna i nadal aktualna** → zostaw, dopisz krótko „potwierdzona (data)" jeśli to nietrywialne.
     Jeśli wpis ma `metadata.status`, podnieś go do `fakt`/`decyzja` (dowód już jest).
   - **Nietrafna / porzucona** → dopisz do TEGO SAMEGO wpisu (nie osobny rejestr — patrz niżej)
     linię **Korekta:** jedno zdanie, co zrobić inaczej następnym razem w tej samej sytuacji, potem
     albo zaktualizuj treść na zgodną z korektą, albo usuń wpis jeśli korekta go w pełni zastępuje.
     Domyka to pętlę decyzja→wynik→ocena→korekta — bez tej linii sweep tylko odnotowuje porażkę,
     nie karmi nią przyszłych decyzji.
   - **Brak dowodu** → pomiń, wróć przy następnym przebiegu.
3. Dopisz linię do `_decision-sweep-log.md`: data, liczba przejrzanych, liczba zaktualizowanych.

**Warunek unieważnienia tego kroku:** liczba aktywnych wpisów decyzyjnych urośnie na tyle (patrz cap
z kroku 3b), że ręczny przegląd całości przestaje się skalować — wtedy zamień na losowy sampling N
zamiast przeglądu wszystkich kandydatów. To hipoteza (brak jeszcze obiektywnego checku, że sweep
faktycznie łapie porzucone decyzje) — dopisana do `hipotezy-otwarte.md`, gate przy pierwszej realnej
okazji do potwierdzenia/obalenia.

### 4a2 — Sweep rejestru „external-blocked" (miesięczny, warunkowy, HIPOTEZA H22)

Domyka lukę znalezioną 2026-09-01 (audyt karty kanban „Waiting on weryfikacja", Manta): doktryna
`memory-discipline` mówi „review at retro" dla rejestru external-blocked (np. Obsidian `Waiting
On.md`), ale żaden krok retro faktycznie tego nie robił — 4 z 13 wierszy okazały się rozwiązane
(ticket Linear Done/Live tygodnie wcześniej), a rejestr stał nietknięty 5 tygodni.

Uruchom TYLKO gdy: (a) od ostatniego przebiegu minęło ~30 dni (log jak w kroku 4a, osobna linia)
ORAZ (b) projekt/sesja ma dostęp do rejestru external-blocked (ścieżka we `.claude/memory/` lub
CLAUDE.md projektu) i do Linear MCP. Brak (b) → nic nie rób, nie zgaduj ścieżki.

Jeśli due: dla każdego wiersza rejestru z linkiem do ticketu (`MAN-XXX` itp.) sprawdź jego status
przez `get_issue` — `Done/Live` (albo `statusType: completed`) **nie oznacza automatycznie
rozwiązania**, bo pytanie z rejestru bywa osobne od tego, co zamknęło ticket (zmierzone: MAN-483,
MAN-489 pozostały realnie otwarte mimo że ich tickety są Done). Dociągnij też ostatnie komentarze
(`list_comments`) i sprawdź, czy pytanie z wiersza dostało odpowiedź PO dacie wiersza. Usuń/zaktualizuj
wiersz tylko gdy dowód jest jednoznaczny; niejasne przypadki zostają, nie zgaduj.

**Ryzyko odwrotne:** sweep zamienia się w rytualne „wszystko aktualne" bez realnej weryfikacji — pilnuj,
żeby faktycznie sprawdzać Linear, nie tylko datę wiersza.

### 4b — Przejrzyj rejestr otwartych hipotez (OBOWIĄZKOWY, każde retro)
Otwórz `hipotezy-otwarte.md` **w repo źródłowym toolkitu** (`piotr-toolkit/plugins/workflow-toolkit/skills/session-retro/`), NIE w katalogu, z którego skill się załadował — ten jest kopią w `~/.claude/plugins/cache/<marketplace>/<plugin>/<wersja>/` i bywa STARSZY od repo (zmierzone 2026-08-25: `cp cache → repo` wywalił 93 linie werdyktów z poprzedniego przebiegu, w tym zamknięty branch wariantu A; złapane tylko dlatego, że `git diff --stat` pokazał `28 insertions, 93 deletions`). Cache jest read-only z definicji — nadpisuje go każda aktualizacja pluginu, więc zapis tam ginie cicho. Po każdej edycji pliku skilla sprawdź `git diff --stat` w repo: liczba usunięć większa od dodań przy „dopisuję jedną linię" znaczy, że piszesz starą wersję na nowszą.

Dla **każdej** pozycji z sekcji „Otwarte" odpal jej **Komendę**. Warunek wznowienia spełniony → przeprowadź gate wg `held-out-gate.md` i zapisz werdykt
z liczbą i nazwaną soczewką; niespełniony → nic nie rób i idź dalej (to kosztuje jedno odpalenie skryptu).
Bez tego kroku hipoteza cicho awansuje na kanon — w `SKILL.md` wygląda jak każda inna reguła, a nikt
do niej nie wraca. Nową hipotezę (zmiana wdrożona bez pełnego gate'a) **dopisz tu w tym samym retro**.

### 5 — Krótki raport
Wypunktuj: co zapisano i gdzie (warstwa), co zaproponowano do commita, co zostaje otwarte na następną sesję.

## Validation-gate — ewolucja skilla / reguły / gate'u

Źródło: Microsoft SkillOpt (https://github.com/microsoft/SkillOpt).

Retro to miejsce, gdzie lekcje z sesji foldują się w skille, gate'y i reguły — więc ta bramka
rządzi krokiem fold-inu. Nie promuj lekcji do kanonu tylko dlatego, że jedna sesja sprawiła, że
„wydaje się słuszna".

- **Utwardzaj zmianę w skillu / gate'cie / regule DOPIERO gdy masz obiektywny check, że nowa wersja
  jest lepsza od starej — nie „wydaje się lepsza".**
- **Gdy check istnieje** (audyt, test, metryka): waliduj na przykładach NIEUŻYTYCH do wymyślenia
  zmiany (held-out) i akceptuj tylko jeśli nie pogarsza reszty.
- **Gdy checku brak**: to osąd, nie kanon — oznacz jako hipotezę, nie zapisuj jako regułę **i wpisz ją
  do `hipotezy-otwarte.md`** (rejestr + wywoływacz, czytany w kroku 4b). Samo słowo „HIPOTEZA" w treści
  skilla nie jest mechanizmem — nikt po nie nie wraca.
- **Każda foldowana reguła niesie warunek unieważnienia** — jedno zdanie „przestaje obowiązywać,
  gdy X", z X obserwowalnym (zmiana narzędzia, wynik gate'a, przekroczony próg). Reguła bez tego jest
  nieusuwalna: sweep odpływu (krok 3b) nie ma po czym poznać, że wygasła, więc kanon rośnie i nigdy
  nie maleje. Nie umiesz nazwać X → to sygnał, że nie masz jeszcze reguły, tylko obserwację.
- **Cel:** domknięcie pętli retro→fold-in — nie foldować reguły z jednego przypadku bez sprawdzenia,
  że nie psuje innych.
- **Wpadka z sesji → task w `evals/` skilla.** Gdy w sesji realnie zawiódł skill lub reguła
  (nie jednorazowy błąd ludzki), dopisz task do `skills/<skill>/evals/` wg schematu z
  `evals-convention.md` (katalog tego skilla). To materializuje held-out: przy następnej zmianie
  skilla przechodzisz jego `evals/` ZANIM utwardzisz — a zbiór rośnie z życia, bez osobnego wysiłku.
