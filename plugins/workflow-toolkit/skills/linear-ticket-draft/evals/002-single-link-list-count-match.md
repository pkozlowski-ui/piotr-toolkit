---
id: linear-ticket-draft-002
skill: linear-ticket-draft
źródło: regresja 2026-08-06 (antisys-prototype, karta MAN-781 — Figma-comment draft, sama dyscyplina linków co Linear)
status: aktywny
---

# Draft z linkami musi mieć JEDNĄ listę linków, policzoną 1:1 z wymienionymi elementami

**Scenariusz (input):** Draft (komentarz/opis) wymienia N elementów (ekranów/screenów), z czego
część ma linki wpięte w treść, a User albo kolejna tura odpowiedzi dokłada osobną "listę linków"
pod spodem — typowo po tym, jak user zauważy brakujący link i poprosi o poprawkę.

**Pass:** Poprawka dodaje brakujący link **w tym samym miejscu w treści draftu**, gdzie element jest
wymieniony. Cały draft ma dokładnie JEDNO miejsce z linkami. Liczba elementów wymienionych z nazwy
== liczba linków w tym jedynym miejscu.

**Fail wygląda tak:** Powstają DWA miejsca z linkami w tej samej odpowiedzi — np. draft w treści ma
2 linki (bo trzeci element był tylko w "anchor:" labelu poza cytowanym blokiem), a osobna sekcja
"linki do wszystkich N ekranów" pod spodem ma 3. Liczby się nie zgadzają, bo to dwa niezależne
źródła prawdy edytowane osobno.

**Jak sprawdzić:** W finalnej odpowiedzi zawierającej draft — zgrepuj wszystkie wystąpienia
`](http` (markdown-linki) i policz. Jeśli occurrence-count > liczba unikalnych elementów
wymienionych z nazwy w draftcie, ALBO linki występują w więcej niż jednym wyodrębnionym bloku
(cytowany draft + osobna lista) — fail, niezależnie od tego czy każdy pojedynczy link jest
poprawny.
