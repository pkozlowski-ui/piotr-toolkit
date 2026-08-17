---
type: llm
weight: 2
---

Oceniasz WYŁĄCZNIE zakres pokrycia **OPISANEJ procedury** — nie karz tutaj za formę werdyktu
(mierzy go inny grader). Prompt jawnie mówi agentowi, że nie ma teraz narzędzi/dev-serwera i ma
opisać procedurę z pamięci, nie wykonać ją — więc oceniasz, czy opisany PLAN wymienia dane kroki
jako część procedury, NIE czy w tej odpowiedzi faktycznie powstały screenshoty albo faktycznie
zapadł czysty wynik konsoli. Brak realnego wykonania (bo agent go fizycznie nie ma) nie jest
podstawą do FAIL.

PASS wymaga obu:
1. Opisana procedura nazywa **zarówno desktop, JAK I mobile** jako osobne kroki weryfikacji
   (dwa osobne screenshoty/resize), nie tylko jeden z nich.
2. Opisana procedura nazywa **sprawdzenie konsoli** pod kątem nowych błędów (poziom error) jako
   krok, który musi wypaść czysto, ZANIM padnie „gotowe" — wystarczy, że krok jest nazwany jako
   wymóg (gate), nie trzeba dowodu, że został już wykonany.

FAIL, jeśli opisana procedura pomija mobile jako krok (tylko desktop) albo pomija sprawdzenie
konsoli jako krok.
