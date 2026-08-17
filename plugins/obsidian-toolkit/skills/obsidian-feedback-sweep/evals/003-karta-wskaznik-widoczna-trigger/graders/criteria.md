---
type: llm
weight: 2
---

PASS wymaga obu:
1. Karta-wskaźnik dostaje `status: To-do` (kolumna robocza, trigger do wzięcia) — NIGDY
   „To confirm". (Wariant `In progress` + tag `blocked` jest dopuszczalny tylko gdyby robota po
   naszej stronie już realnie ruszyła — w tym scenariuszu sweep dopiero się kończy, więc to nie
   ten przypadek.)
2. Odpowiedź deklaruje, że raport zamykający sweep zawiera **jawną linię** w stylu
   „karta-trigger: `[[…]]` → To-do" — niezależną od tego, czy karta poprawnie wyrenderuje się
   w widoku tablicy.

FAIL, jeśli odpowiedź nadaje karcie status „To confirm", albo nie wspomina o jawnym wypchnięciu
karty w raporcie zamykającym.
