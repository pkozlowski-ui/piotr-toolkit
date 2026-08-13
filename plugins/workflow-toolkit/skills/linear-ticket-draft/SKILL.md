---
name: linear-ticket-draft
description: Tworzy draft opisu/komentarza taska do Linear w rejestrze "opis taska" (ENG, strukturalny, skondensowany, pisany jak człowiek). Uruchamia się gdy user mówi "draft do lineara", "opis do taska", "opis taska", "zrób draft ticketu", "napisz do lineara", "opis do <TICKET>", albo prosi o podsumowanie dostarczonej roboty do Linear. NIGDY nie wysyła — pokazuje draft w czacie i czeka na wyraźne "wyślij".
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
   i czekasz na wyraźne **„wyślij"** (zgodnie z globalnym CLAUDE.md „Wysyłka na zewnątrz"). Dopiero po
   „wyślij" zadaj **jedno** pytanie: **komentarz czy podmiana opisu (description)?** — i wtedy użyj
   Linear MCP (`save_comment` / `save_issue`).
2. Prośba o poprawkę draftu (krócej, inny ton, inne sekcje) ≠ zgoda na wysyłkę.
3. **Timing przy epicu/wątku (TWARDE):** jeśli ticket należy do **aktywnego epica z otwartymi sub-taskami** (patrz skill `obsidian-kanban` → „Epiki") — **NIE draftuj teraz**. Draft opisu/komentarza opisującego rozwiązanie powstaje **dopiero gdy cały wątek jest zbudowany** (wszystkie sub-taski domknięte). Powód: komentarz z opisem rozwiązania, po którym rozwiązanie się jeszcze zmienia, dezaktualizuje się. Gdy wątek trwa — zbieraj materiał, ale wstrzymaj draft do końca.

## Styl (domyślny)
- **Język: ENG** (Linear/produkt). Rozmowa ze mną dalej PL.
- **Skondensowany, ale jasny.** Rzeczowo: co zostało zbudowane. Bez lania wody.
- **Pisz jak człowiek wypełniający ticket. Zero śladów AI:** bez kursywy (`*...*`), bez em-dashy (—),
  bez przesadnie równoległych fraz, bez „Note:", bez emoji, bez „we're excited / delivered a robust…".
- **Bold tylko na mini-nagłówki sekcji** (`**Screens**`, `**Not included**`). Bullety dla list.
- **Rozmieszczenie linków rozstrzyga ICH LICZBA (TWARDA, decyzja Piotra 2026-08-13 — zastępuje
  wcześniejszy standard „zawsze kontekstowo" z 2026-08-05).** Policz linki, które draft ma nieść,
  i wybierz jeden z dwóch wariantów — nigdy oba naraz:
  - **> 1 link → wariant A, link per ekran.** Każdy element wymieniony w `**Screens**` dostaje SWÓJ
    WŁASNY link wpięty w tym samym bullet-poincie, i **żadnej zbiorczej sekcji `**Links**` na końcu**.
    Format bulleta: `- Screen name: what it does. [Figma](url)` (markdown link, nie goły URL —
    czytelniej w renderze Linear). Reviewer klika prosto w opisany ekran.
  - **dokładnie 1 link → wariant B, jeden link zbiorczy.** Bullety w `**Screens**` zostają BEZ linków,
    a link (żywy prototyp / sekcja z wszystkimi ekranami obok siebie) idzie jako jedyna pozycja
    w `**Links**` na końcu. Rozbijanie jednego linku na sześć bulletów-duplikatów jest szumem.
  URL z node-id: `…?node-id=ID-z-myślnikiem` (np. `4180-137260`).
  **Status: obowiązująca, ale HIPOTEZA behawioralna** — drugi przebieg gate'a (2026-08-13) dał
  `held-out C: 0 ocenianych przypadków, za mało danych` (zero wywołań po zmianie, bo reguła powstała
  tego samego dnia). Stosuj jak regułę, ale przy następnej retro sprawdź ją na ≥ 3 draftach niosących
  linki, zanim ktokolwiek nazwie ją zwalidowaną.
- **⚠️ Jeden draft = JEDNA lista linków, licz PRZED pokazaniem (regresja 2026-08-06, MAN-781 — nie w
  Linearze, w analogicznym Figma-comment draftcie tej samej dyscypliny, więc reguła i tak dotyczy tego
  skilla).** Realny fail: draft komentarza wymieniał 3 ekrany, ale treść komentarza linkowała tylko 2
  (trzeci żył wyłącznie jako osobny „anchor:" label poza cytowanym blokiem) — potem w TEJ SAMEJ
  odpowiedzi doszła osobna „lista wszystkich 3 linków" pod spodem. Dwa niezależne miejsca z linkami do
  tych samych rzeczy zawsze się rozjadą przy edycji, i user złapał to od razu (liczba w drafcie ≠
  liczba w liście). Fix nie jest kosmetyczny — to jest DOKŁADNIE reguła z akapitu wyżej („nie osobna
  sekcja linków na końcu"), złamana przez zbudowanie drugiej listy PO fakcie zamiast poprawienia
  oryginalnego draftu. **Przed pokazaniem JAKIEGOKOLWIEK draftu z linkami policz linki i sprawdź dwie
  rzeczy: (1) to JEDYNE miejsce z linkami w całej odpowiedzi; (2) w wariancie A (> 1 link) każdy
  wymieniony z nazwy element ma swój link — zgodność 1:1.** W wariancie B (dokładnie 1 link) zgodności
  1:1 się NIE liczy — jeden link do całości przy sześciu nazwanych ekranach jest poprawny. Brakuje
  linku w wariancie A → dopisz go W TYM SAMYM miejscu w treści, nie jako dodatkową listę obok.

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
3. **Screens** (albo What's built) — bullety: ekran/element + 1 linia co robi. **Wariant A (> 1 link):**
   + link do TEGO ekranu wpięty w ten sam bullet (`[Figma](url)`). **Wariant B (1 link):** bez linków tutaj.
4. Krótki akapit per kluczowy obszar, jeśli potrzebny.
5. **Not included** — co świadomie poza zakresem i dokąd należy (fakt, nie decyzja).
6. **Figma** (lub **Links**) — **tylko w wariancie B**, jako jedyna pozycja: prototyp/Vercel albo
   sekcja z wszystkimi ekranami naraz. W wariancie A tej sekcji NIE MA (linki żyją przy ekranach) —
   nie duplikuj tu linków ekranów. NIGDY link do PR (patrz „Czego NIE robić").

## Długość: description vs komentarz
- **Opis ticketu (description)** = ten strukturalny draft — kompletny, ale skondensowany.
- **Komentarz dyskusyjny** = krótko, 2–4 zdania + linki (patrz memory `feedback-linear-brevity`);
  pełny write-up, jeśli długi, idzie do Obsidiana, nie do Linear.
- Gdy user mówi „cały opis" → wersja kompletna (description); domyślnie trzymaj zwięźle.

## Po „wyślij"
1. Zapytaj raz: komentarz czy description.
2. Komentarz → Linear MCP `save_comment` (issueId). Description → `save_issue` (id + description).
3. Potwierdź co poszło i gdzie (link do ticketu).
