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
- **Linki KONTEKSTOWO, nie zbiorczo (TWARDA, standard od 2026-08-05).** Każdy ekran/element wymieniony
  w `**Screens**` dostaje SWÓJ WŁASNY link Figma wpięty w tym samym bullet-poincie — nie osobna sekcja
  linków na końcu. Powód: reviewer klika prosto w opisany ekran, zamiast szukać go w zbiorczej liście.
  Format bulleta: `- Screen name: what it does. [Figma](url)` (markdown link, nie goły URL — czytelniej
  w renderze Linear). Zbiorcza sekcja `**Figma**` na końcu zostaje TYLKO gdy link dotyczy całego
  flow/sekcji jako całości (np. link do sekcji z wszystkimi ekranami obok siebie) — nie duplikuj tam
  linków już wpiętych przy screenach. URL z node-id: `…?node-id=ID-z-myślnikiem` (np. `4180-137260`).
- **⚠️ Jeden draft = JEDNA lista linków, licz PRZED pokazaniem (regresja 2026-08-06, MAN-781 — nie w
  Linearze, w analogicznym Figma-comment draftcie tej samej dyscypliny, więc reguła i tak dotyczy tego
  skilla).** Realny fail: draft komentarza wymieniał 3 ekrany, ale treść komentarza linkowała tylko 2
  (trzeci żył wyłącznie jako osobny „anchor:" label poza cytowanym blokiem) — potem w TEJ SAMEJ
  odpowiedzi doszła osobna „lista wszystkich 3 linków" pod spodem. Dwa niezależne miejsca z linkami do
  tych samych rzeczy zawsze się rozjadą przy edycji, i user złapał to od razu (liczba w drafcie ≠
  liczba w liście). Fix nie jest kosmetyczny — to jest DOKŁADNIE reguła z akapitu wyżej („nie osobna
  sekcja linków na końcu"), złamana przez zbudowanie drugiej listy PO fakcie zamiast poprawienia
  oryginalnego draftu. **Przed pokazaniem JAKIEGOKOLWIEK draftu z linkami: policz linki w treści vs
  policz wymienione z nazwy elementy — muszą się zgadzać 1:1, i to ma być JEDYNE miejsce z linkami w
  całej odpowiedzi.** Jeśli czegoś brakuje — dopisz link W TYM SAMYM miejscu w treści, nie jako
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
3. **Screens** (albo What's built) — bullety: ekran/element + 1 linia co robi + **link Figma DO TEGO
   EKRANU wpięty w ten sam bullet** (`[Figma](url)`), nie zbiorczo na końcu.
4. Krótki akapit per kluczowy obszar, jeśli potrzebny.
5. **Not included** — co świadomie poza zakresem i dokąd należy (fakt, nie decyzja).
6. **Figma** (lub **Links**) — TYLKO jeśli zostaje link do czegoś, co nie jest pojedynczym ekranem z
   punktu 3 (np. cała sekcja/flow widziany na canvasie naraz, prototyp/Vercel). NIGDY link do PR
   (patrz „Czego NIE robić"). Nie duplikuj tu linków ekranów.

## Długość: description vs komentarz
- **Opis ticketu (description)** = ten strukturalny draft — kompletny, ale skondensowany.
- **Komentarz dyskusyjny** = krótko, 2–4 zdania + linki (patrz memory `feedback-linear-brevity`);
  pełny write-up, jeśli długi, idzie do Obsidiana, nie do Linear.
- Gdy user mówi „cały opis" → wersja kompletna (description); domyślnie trzymaj zwięźle.

## Po „wyślij"
1. Zapytaj raz: komentarz czy description.
2. Komentarz → Linear MCP `save_comment` (issueId). Description → `save_issue` (id + description).
3. Potwierdź co poszło i gdzie (link do ticketu).
