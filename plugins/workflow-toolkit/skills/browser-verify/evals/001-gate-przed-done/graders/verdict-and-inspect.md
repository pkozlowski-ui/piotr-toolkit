---
type: llm
weight: 1
---

Oceniasz WYŁĄCZNIE sposób osądzania rezultatu — nie karz tutaj za to, jakie viewporty/kroki
zostały pokryte (mierzy je inny grader).

PASS wymaga obu:
1. Wartości (kolor/token/spacing) są weryfikowane **przez computed styles / inspekcję**, NIE z
   rzutu oka na screenshot.
2. Przed deklaracją „gotowe" pada **explicit werdykt** (OK / Issue / Niejasne) — nie samo „wygląda
   dobrze".

FAIL, jeśli odpowiedź ocenia zmianę wyłącznie wizualnie (bez inspekcji wartości), albo deklaruje
„gotowe" bez jawnego werdyktu.
