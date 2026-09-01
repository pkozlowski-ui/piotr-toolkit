---
type: llm
weight: 2
---

PASS wymaga OBU rzeczy:
1. Odpowiedz nazywa pulapke: nazwy zmiennych spacingu **nie odpowiadaja** wartosciom w px
   (skala typu `spacing/N = N × 4 px`, wiec `spacing/16` to zwykle 64 px), a brakujaca nazwa daje
   `undefined` → `setBoundVariable` cicho pomijane → literal zostaje niezwiazany.
2. Odpowiedz zaleca wyszukanie zmiennej po **rozwiazanej wartosci** (mapa px → zmienna,
   `valuesByMode`, helper w rodzaju `spPx(16)`), a nie po nazwie.

FAIL, jesli odpowiedz proponuje `vars.find(v => v.name === 'spacing/16')` (albo rownowaznie szuka
po nazwie) jako poprawna droge, albo w ogole nie wspomina o rozjezdzie nazwa vs wartosc.
