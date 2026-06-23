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

## Twarde zasady (nadrzędne)
1. **NIE WYSYŁAJ.** Linear komentarz / edycja opisu = treść team-facing → draft pokazujesz w czacie
   i czekasz na wyraźne **„wyślij"** (zgodnie z globalnym CLAUDE.md „Wysyłka na zewnątrz"). Dopiero po
   „wyślij" zadaj **jedno** pytanie: **komentarz czy podmiana opisu (description)?** — i wtedy użyj
   Linear MCP (`save_comment` / `save_issue`).
2. Prośba o poprawkę draftu (krócej, inny ton, inne sekcje) ≠ zgoda na wysyłkę.

## Styl (domyślny)
- **Język: ENG** (Linear/produkt). Rozmowa ze mną dalej PL.
- **Skondensowany, ale jasny.** Rzeczowo: co zostało zbudowane. Bez lania wody.
- **Pisz jak człowiek wypełniający ticket. Zero śladów AI:** bez kursywy (`*...*`), bez em-dashy (—),
  bez przesadnie równoległych fraz, bez „Note:", bez emoji, bez „we're excited / delivered a robust…".
- **Bold tylko na mini-nagłówki sekcji** (`**Screens**`, `**Not included**`). Bullety dla list.
- **Linki (Figma / PR / repo) = osobne bullety, jeden pod drugim**, w sekcji na końcu (np. `**Figma**`).
  URL z node-id: `…?node-id=ID-z-myślnikiem` (np. `4180-137260`).

## Czego NIE robić
- **Pomijaj design system** — tokeny, komponenty DS, parytet Mantine, audyty, node-id, nazwy warstw.
  To nie treść produktowego taska.
- **Nie przypisuj sobie decyzji i nie podsumowuj „decyzji do podjęcia".** Decyzje produktowe/designerskie
  podejmuje Piotr. Opisuj **CO zbudowano** (fakty), nie „zdecydowaliśmy / wybrałem / postanowiliśmy".
- Nie wrzucaj wewnętrznych gotch ani procesu budowy.

## Struktura (elastyczna — tnij puste sekcje)
1. **Nagłówek** — krótka nazwa zakresu (bez em-dasha).
2. 1 zdanie kontekstu (gdzie zbudowane; ew. rename / przeniesienia).
3. **Screens** (albo What's built) — bullety: ekran/element + 1 linia co robi.
4. Krótki akapit per kluczowy obszar, jeśli potrzebny.
5. **Not included** — co świadomie poza zakresem i dokąd należy (fakt, nie decyzja).
6. **Figma** (lub **Links**) — bullety, jeden link pod drugim.

## Długość: description vs komentarz
- **Opis ticketu (description)** = ten strukturalny draft — kompletny, ale skondensowany.
- **Komentarz dyskusyjny** = krótko, 2–4 zdania + linki (patrz memory `feedback-linear-brevity`);
  pełny write-up, jeśli długi, idzie do Obsidiana, nie do Linear.
- Gdy user mówi „cały opis" → wersja kompletna (description); domyślnie trzymaj zwięźle.

## Po „wyślij"
1. Zapytaj raz: komentarz czy description.
2. Komentarz → Linear MCP `save_comment` (issueId). Description → `save_issue` (id + description).
3. Potwierdź co poszło i gdzie (link do ticketu).
