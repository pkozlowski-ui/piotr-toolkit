---
type: llm
weight: 2
---

Oceniasz **wyłącznie pisownię i formę stringów przeznaczonych do interfejsu** (nie jakość
perswazyjną, nie kompletność sekcji outputu, nie długość odpowiedzi).

**Co jest stringiem interfejsowym:** wartości w kolumnie `Copy` / po `Nagłówek:` / `Body:` / `CTA:`,
labelki przycisków i chipów, nazwy tokenów i identyfikatorów w kodzie. **Czym NIE jest:** proza
wyjaśniająca, uzasadnienia, notatki lokalizacyjne, sekcja open questions, ani brytyjskie słowo
**cytowane z promptu** („twój prompt ma *personalise*, ja piszę *personalize*").

PASS wymaga wszystkich trzech:

1. **Zero brytyjskiej pisowni w stringach interfejsowych**: żadnego `personalise`, `organise`,
   `customise`, `colour`, `cancelled`, `behaviour`, `centre`, `judgement`. Amerykański odpowiednik
   (`personalize`, `organize`, `color`, `canceled`) albo przeformułowanie omijające słowo
   (`Configure view`) — oba PASS.
2. **Sentence case** w nagłówkach i labelkach (Title Case dopuszczalny tylko dla nazwy własnej lub
   formalnej labelki pola danych).
3. **CTA verb-first i nazywa efekt** (np. `Customize view`, `Configure view`, `Retry save`), nie
   `Submit` / `OK` / samo `Personalise`.

FAIL tylko w dwóch sytuacjach:

- którykolwiek string interfejsowy używa brytyjskiej pisowni, ALBO
- odpowiedź **wstrzymuje copy** i odbija do użytkownika pytanie, czy stosować UK czy US English,
  zamiast zastosować domyślne US (prompt nie wskazuje klienta UK-based, więc domyślne US obowiązuje
  bez pytania).

**To NIE jest FAIL:** odpowiedź, która **już napisała copy po amerykańsku** i przy okazji zaznacza
warunek odwrócenia („piszę US; jeśli klient jest UK-based, powiedz i przerzucę całość"). To jest
zachowanie WYMAGANE przez skill (reguła mówi wprost: przy kliencie UK-based mówisz o tym na głos),
a nie odbicie decyzji. Rozstrzyga jedno pytanie: **czy stringi już są w odpowiedzi?** Jeśli tak —
nota o warunku jest neutralna.
