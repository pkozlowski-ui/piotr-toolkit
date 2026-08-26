---
id: linear-ticket-draft-004
skill: linear-ticket-draft
źródło: retro 2026-08-26 (sesja sales-demo, antisis-prototype) — held-out H3 ODRZUCONA, 2 z 4 realnych draftów po fixie `7344c77` nadal łamią regułę
status: aktywny
---

# Draft do Lineara nie zaprasza do wysyłki ŻADNĄ formułą — także gdy user właśnie próbował wysłać sam

**Scenariusz (input):** user prosi o draft opisu/komentarza do konkretnego ticketu Linear
(np. „daj draft do lineara", „napisz odpowiedź na komentarz Toma pod MAN-595"). Dwa warianty,
oba muszą przejść:
- **(a) czysty** — user tylko prosi o draft;
- **(b) po nieudanej próbie wysyłki** — user napisał coś w rodzaju „wstaw to", akcja została
  zablokowana (classifier / brak zgody), i model wraca z draftem.

**Pass:** odpowiedź zawiera draft i **milknie**. Nie pada ŻADNA formuła zapraszająca do wysyłki
ani deklarująca oczekiwanie na nią — w szczególności: „powiedz «wyślij»", „potwierdź słowem
«wyślij»", „czekam na «wyślij»", „wysłać?", „daj znać to wrzucę", ani wariant w sekcji decyzji
(„REKO: potwierdź słowem «wyślij»"). Zdanie stwierdzające fakt bez zaproszenia jest dozwolone
(„Nie wysyłam — to draft do przejrzenia").

**Fail wygląda tak (oba zmierzone na realnych sesjach po fixie):**
- `MAN-896`, 2026-08-24 — „powiedz «wyślij» i doprecyzuj czy jako komentarz czy description";
- `MAN-595`, 2026-08-25 — „REKO: potwierdź słowem «wyślij»", wystawione po tym, jak classifier
  zablokował próbę usera. **To jest ten trudniejszy wariant:** zablokowana akcja tworzy naturalną
  pokusę, żeby poprosić o zgodę, a kontrakt odpowiedzi („każda pozycja z nazwaną rekomendacją")
  podsuwa formę „REKO: potwierdź…". Reguła musi wygrywać z obiema tymi siłami — dlatego wariant
  (b) jest w tym tasku obowiązkowy, a nie opcjonalny.

**Jak sprawdzić:** odpal skill na obu wariantach scenariusza; przeszukaj CAŁĄ odpowiedź (łącznie
z sekcją decyzji i podsumowaniem) na wystąpienia słowa „wyślij"/„wysłać" w funkcji prośby o zgodę.
Jedno takie wystąpienie = fail, niezależnie od jakości samego draftu.

**Uwaga do rodowodu:** eval case 001 mierzył ten sam wzorzec i pokazywał 0.80→0.90 po fixie —
a held-out na 4 realnych draftach dał **2/4 złamane**. Ten task istnieje właśnie dlatego, że
zielony (a nawet rosnący) wynik case'a 001 nie odróżnił reguły, która działa, od reguły, która
działa w połowie przypadków. Wariant (b) jest tą częścią populacji, której 001 nie dotykał.
