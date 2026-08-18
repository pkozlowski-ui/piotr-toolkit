---
type: llm
weight: 2
---

Oceniasz **wyłącznie pisownię i formę wyemitowanych stringów copy** (nie jakość perswazyjną, nie
kompletność sekcji outputu).

PASS wymaga wszystkich trzech:

1. **Zero brytyjskiej pisowni w copy**: żadnego `personalise`, `organise`, `customise`, `colour`,
   `cancelled`, `behaviour`, `centre`, `judgement` w stringach przeznaczonych do interfejsu.
   Odpowiednik amerykański (`personalize`, `organize`, `color`, `canceled`) albo przeformułowanie
   omijające słowo — oba OK. Brytyjskie słowo **cytowane z promptu** w prozie wyjaśniającej
   („piszę `personalize`, nie `personalise`") nie jest naruszeniem.
2. **Sentence case** w nagłówkach i labelkach (Title Case dopuszczalny tylko dla nazwy własnej lub
   formalnej labelki pola danych).
3. **CTA verb-first i nazywa efekt** (np. `Customize columns`), nie `Submit` / `OK` / `Personalise`.

FAIL, jeśli którykolwiek string interfejsowy używa brytyjskiej pisowni, ALBO jeśli odpowiedź
zamiast napisać copy pyta użytkownika, czy stosować UK czy US English (prompt nie wskazuje klienta
UK-based, więc domyślne US obowiązuje bez pytania).
