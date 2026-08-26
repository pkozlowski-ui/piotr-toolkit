---
name: linear-ticket-draft
description: Tworzy draft opisu/komentarza taska do Linear w rejestrze "opis taska" (ENG, strukturalny, skondensowany, pisany jak człowiek). Uruchamia się gdy user mówi "draft do lineara", "opis do taska", "opis taska", "zrób draft ticketu", "napisz do lineara", "opis do <TICKET>", albo prosi o podsumowanie dostarczonej roboty do Linear. NIGDY nie wysyła i nigdy nie zaprasza do wysyłki — pokazuje draft w czacie i milknie, user inicjuje sam.
---

# Skill: linear-ticket-draft

## Cel
Złożyć czysty, ludzki opis taska do Linear z tego, co zostało dostarczone — w rejestrze
**"opis taska"** (ustrukturyzowany, rzeczowy), NIE "wiadomość" (Slack, konwersacyjna). Pokazać draft
w czacie. Nic nie wysyłać.

## Auto-trigger
- "draft do lineara" / "zrób draft ticketu" / "napisz do lineara"
- "opis do taska" / "opis taska" / "opis do <TICKET-ID>"
- prośba o podsumowanie dostarczonej roboty pod kątem Linear (komentarz albo description)
- **draft komentarza do wątku w Figmie** (odpowiedź na komentarz Toma/stakeholdera przy designie) —
  patrz „Zakres" niżej

## Zakres — co należy do tego rejestru (domknięte 2026-08-13)
Skill obejmuje **każdy draft team-facing odpowiedzi o dostarczonym designie**, niezależnie od kanału:
**komentarz/description w Linear ORAZ komentarz w wątku Figma.** Oba idą do tego samego zespołu, w tym
samym rejestrze „opis taska" (ENG, strukturalny), i obowiązuje w nich ta sama dyscyplina linków —
reguła jednej listy linków powstała właśnie na Figma-comment draftcie (MAN-781), a nie w Linearze.
**Nie należą tu:** wiadomość na Slacku i mail (rejestr „wiadomość" — konwersacyjny, patrz globalny
CLAUDE.md) ani notatka do vaultu.

Powód domknięcia: przy pierwszym przebiegu held-out gate'a (2026-08-13) jedyny kandydat na pominięty
trigger okazał się draftem komentarza do Figmy i **werdykt był nierozstrzygalny**, bo skill nakazywał
sobie dyscyplinę linków w takich draftach, nie mówiąc, czy sam ma w nie wchodzić. Otwarty zakres =
niemierzalny skill (`held-out-gate.md` → „Czego NIE robić").

## Twarde zasady (nadrzędne)
1. **NIE WYSYŁAJ.** Linear komentarz / edycja opisu = treść team-facing → draft pokazujesz w czacie
   i **milkniesz na temat wysyłki** (zgodnie z globalnym CLAUDE.md „Wysyłka na zewnątrz" — „przygotuj
   draft, pokaż, zamilknij"). **Nie zapraszaj do wysyłki żadną formułą oczekiwania** — nie pisz
   „powiedz «wyślij», to zapostuję", nie pisz „czekam na «wyślij»", nie pytaj „wysłać?". Zaproszenie
   jest naruszeniem samo w sobie, nawet jeśli poprawnie deklarujesz, że sam nie wysyłasz — user
   inicjuje wysyłkę sam, nieproszony pytaniem. Dopiero gdy user **sam** to zainicjuje, zadaj **jedno**
   pytanie: **komentarz czy podmiana opisu (description)?** — i wtedy użyj Linear MCP (`save_comment` /
   `save_issue`).

   **1a. Dwie luki, przez które ta reguła realnie przecieka (zmierzone held-outem 2026-08-26:
   2 z 4 draftów po fixie `7344c77` nadal ją łamały — dlatego są wypisane osobno, a nie „wynikają"
   z akapitu wyżej).**
   - **Sekcja decyzji NIE jest wyjątkiem.** Kontrakt odpowiedzi wymaga nazwanej rekomendacji przy
     każdej pozycji, i model wypełnia ją prośbą o zgodę: **„REKO: potwierdź słowem «wyślij»"** —
     realny fail na `MAN-595`. Zakaz obowiązuje w CAŁEJ odpowiedzi: w prozie, w podsumowaniu,
     w sekcji decyzji, w podpisie. Draft nie jest pozycją do decyzji — jest dostarczonym
     artefaktem, więc **nie wystawiaj go jako decyzji do potwierdzenia**. Jeśli nic innego nie ma
     do rozstrzygnięcia, napisz wprost „nic ode mnie nie potrzebujesz" i skończ.
   - **Zablokowana próba wysyłki nie odblokowuje pytania.** Gdy user napisał „wstaw to" i akcja
     padła (classifier, brak zgody, błąd MCP), naturalny odruch to poprosić o zgodę jeszcze raz —
     to jest ten sam zakaz. **Powiedz, CO zablokowało i CO user może zrobić sam, w trybie
     oznajmującym, bez pytania i bez formuły oczekiwania.**
   - Nie łącz też pytania o kanał z zaproszeniem: **„powiedz «wyślij» i doprecyzuj czy jako
     komentarz czy description"** (realny fail na `MAN-896`) to jedno i drugie w jednym zdaniu.
     Pytanie „komentarz czy description?" pada **wyłącznie po** tym, jak user sam zainicjował.

   **Status reguły 1: HIPOTEZA — NIE zwalidowana.** Held-out 2026-08-26 dał 2/4 (`ODRZUCONA`),
   punkt 1a jest odpowiedzią na te dwa faile. Wywoływacz: `skills/session-retro/hipotezy-otwarte.md`
   (H3); specyfikacja: `evals/004-nigdy-nie-zapraszaj-do-wyslania.md`. Nie zdejmuj tej adnotacji,
   dopóki nowy przebieg nie da ≥ 3 ocenianych draftów z zerem złamań.
2. Prośba o poprawkę draftu (krócej, inny ton, inne sekcje) ≠ zgoda na wysyłkę.
3. **Timing przy epicu/wątku (TWARDE):** jeśli ticket należy do **aktywnego epica z otwartymi sub-taskami** (patrz skill `obsidian-kanban` → „Epiki") — **NIE draftuj teraz**. Draft opisu/komentarza opisującego rozwiązanie powstaje **dopiero gdy cały wątek jest zbudowany** (wszystkie sub-taski domknięte). Powód: komentarz z opisem rozwiązania, po którym rozwiązanie się jeszcze zmienia, dezaktualizuje się. Gdy wątek trwa — zbieraj materiał, ale wstrzymaj draft do końca.

## Styl (domyślny)
- **Język: ENG** (Linear/produkt). Rozmowa ze mną dalej PL.
- **Skondensowany, ale jasny.** Rzeczowo: co zostało zbudowane. Bez lania wody.
- **Pisz jak człowiek wypełniający ticket. Zero śladów AI:** bez kursywy (`*...*`), bez em-dashy (—),
  bez przesadnie równoległych fraz, bez „Note:", bez emoji, bez „we're excited / delivered a robust…".
- **Bold tylko na mini-nagłówki sekcji** (`**Screens**`, `**Not included**`). Bullety dla list.
- **Link idzie DO ekranu, którego dotyczy — nigdy do zbiorczej sekcji na końcu (TWARDA,
  decyzja Piotra 2026-08-13, uproszczona 2026-08-26 po zamknięciu held-outu).** Każdy element
  wymieniony w `**Screens**` dostaje SWÓJ WŁASNY link wpięty w tym samym bullet-poincie, i
  **żadnej zbiorczej sekcji `**Links**` na końcu**. Format bulleta:
  `- Screen name: what it does. [Figma](url)` (markdown link, nie goły URL — czytelniej
  w renderze Linear). Reviewer klika prosto w opisany ekran.
  URL z node-id: `…?node-id=ID-z-myślnikiem` (np. `4180-137260`).
  **Status: ZWALIDOWANA** — held-out 2026-08-26, 3/3 czyste przypadki (`MAN-848` 2 linki,
  `MAN-825` 2 URL-e, ticket Family Portal 3 linki), zero kontrprzykładów.
  **Wariant B USUNIĘTY 2026-08-26 — nie odtwarzaj go.** Przez cztery przebiegi held-outu
  („1 link → bullety bez linków + jeden link zbiorczy w `**Links**`") nie znalazł ani jednego
  przypadku, w którym mógłby się odpalić: **każdy realny draft z dokładnie jednym linkiem
  okazywał się jednoakapitową odpowiedzią, nie listą ekranów w bulletach** (`MAN-896` —
  ogłoszenie reskinu; `MAN-595` — odpowiedź na komentarz Toma). To była reguła bez populacji,
  nie reguła bez danych, więc zamiast czekać na materiał — zdjęta. Jeden link przy jednym
  ekranie i tak trafia w ten sam bullet co ekran; jeden link przy jednym akapicie zostaje
  w akapicie. *Wraca do rozważenia dopiero, gdy pojawi się realny draft z dokładnie 1 linkiem
  opisujący WIELE ekranów w bulletach — wtedy populacja istnieje i pytanie jest otwarte na nowo.*
- **⚠️ Jeden draft = JEDNA lista linków, licz PRZED pokazaniem (regresja 2026-08-06, MAN-781 — nie w
  Linearze, w analogicznym Figma-comment draftcie tej samej dyscypliny, więc reguła i tak dotyczy tego
  skilla).** Realny fail: draft komentarza wymieniał 3 ekrany, ale treść komentarza linkowała tylko 2
  (trzeci żył wyłącznie jako osobny „anchor:" label poza cytowanym blokiem) — potem w TEJ SAMEJ
  odpowiedzi doszła osobna „lista wszystkich 3 linków" pod spodem. Dwa niezależne miejsca z linkami do
  tych samych rzeczy zawsze się rozjadą przy edycji, i user złapał to od razu (liczba w drafcie ≠
  liczba w liście). Fix nie jest kosmetyczny — to jest DOKŁADNIE reguła z akapitu wyżej („nie osobna
  sekcja linków na końcu"), złamana przez zbudowanie drugiej listy PO fakcie zamiast poprawienia
  oryginalnego draftu. **Przed pokazaniem JAKIEGOKOLWIEK draftu z linkami policz linki i sprawdź dwie
  rzeczy: (1) to JEDYNE miejsce z linkami w całej odpowiedzi; (2) każdy wymieniony z nazwy element
  ma swój link — zgodność 1:1.** Brakuje linku → dopisz go W TYM SAMYM miejscu w treści, nie jako
  dodatkową listę obok.

## Czego NIE robić
- **Nigdy link do GitHub PR (TWARDA, recurring — Piotr poprawiał to wielokrotnie, ostatnio na
  MAN-825, 2026-08-10).** PR to mechanika budowy repo, nie treść produktowa — ta sama zasada co
  „pomijaj design system" niżej. Zostaje: link do prototypu/Vercel (deliverable, nie mechanizm),
  link Figma per-ekran/sekcja. `**Links**`/`**Figma**` z punktu 6 struktury NIGDY nie zawiera PR,
  nawet jako przykład użycia.
- **Pomijaj design system** — tokeny, komponenty DS, parytet Mantine, audyty, node-id, nazwy warstw.
  To nie treść produktowego taska.
- **Nie przypisuj sobie decyzji i nie podsumowuj „decyzji do podjęcia".** Decyzje produktowe/designerskie
  podejmuje Piotr. Opisuj **CO zbudowano** (fakty), nie „zdecydowaliśmy / wybrałem / postanowiliśmy".
- Nie wrzucaj wewnętrznych gotch ani procesu budowy.

## Struktura (elastyczna — tnij puste sekcje)
1. **Nagłówek** — krótka nazwa zakresu (bez em-dasha).
2. 1 zdanie kontekstu (gdzie zbudowane; ew. rename / przeniesienia).
3. **Screens** (albo What's built) — bullety: ekran/element + 1 linia co robi, + link do TEGO ekranu
   wpięty w ten sam bullet (`[Figma](url)`).
4. Krótki akapit per kluczowy obszar, jeśli potrzebny.
5. **Not included** — co świadomie poza zakresem i dokąd należy (fakt, nie decyzja).
6. ~~**Figma** / **Links** — sekcja zbiorcza na końcu~~ 🗑️ **usunięta 2026-08-26 razem z wariantem B.**
   Linki żyją przy ekranach, których dotyczą; jeden link do żywego prototypu, który nie należy do
   żadnego pojedynczego ekranu, wchodzi w zdanie kontekstu (punkt 2). NIGDY link do PR (patrz
   „Czego NIE robić").

## Długość: description vs komentarz
- **Opis ticketu (description)** = ten strukturalny draft — kompletny, ale skondensowany.
- **Komentarz dyskusyjny** = krótko, 2–4 zdania + linki (patrz memory `feedback-linear-brevity`);
  pełny write-up, jeśli długi, idzie do Obsidiana, nie do Linear.
- Gdy user mówi „cały opis" → wersja kompletna (description); domyślnie trzymaj zwięźle.

## Korekta z edycji przed wysyłką (pętla dla sygnału POZA formalnymi regułami)

Reguły stylu tego skilla (1, link-placement) mają już pełną obsługę held-out gate'em — to NIE jest
luka. Luka jest gdzie indziej: gdy user **edytuje draft przed wklejeniem** (skraca, zmienia opis
zakresu, poprawia faktyczny błąd o tym co zbudowano) — to jest darmowy sygnał zwrotny o trafności
treści, nie tylko stylu, i dziś nic go nie zbiera. Pojedyncza edycja to nie dowód wzorca — ale gdy
**ten sam typ poprawki powtórzy się** (np. dwa razy z rzędu user dopisuje coś, co skill pominął, albo
usuwa coś, co skill dodał mimo „Czego NIE robić") → to już kandydat na hipotezę, nie przypadek.

Gdy zauważysz powtórkę: dopisz nową hipotezę do `../session-retro/hipotezy-otwarte.md` wg wzorca
istniejących wpisów (co, kiedy, soczewka, warunek wznowienia) — **nie** utwardzaj reguły w tym pliku
od razu na podstawie dwóch przypadków (to złamałoby validation-gate, ten sam błąd, przed którym
ostrzega `session-retro`). Jedna edycja bez powtórki → nic nie rób, to szum.

## Po „wyślij"
1. Zapytaj raz: komentarz czy description.
2. Komentarz → Linear MCP `save_comment` (issueId). Description → `save_issue` (id + description).
3. Potwierdź co poszło i gdzie (link do ticketu).
