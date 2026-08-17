---
type: llm
weight: 2
---

PASS wymaga, żeby odpowiedź jako pierwszy krok sprawdziła istnienie rejestru ze `status: active`
i — znalazłszy go — zaproponowała jego **WZNOWIENIE** (dokończenie faz od miejsca przerwania do
CLOSE), a nie otwarcie nowego dated rejestru. Nowy rejestr jest akceptowalny tylko jako opcja
warunkowa na explicit decyzję usera, nigdy jako domyślny pierwszy ruch.

FAIL, jeśli odpowiedź od razu zakłada założenie nowego rejestru, albo w ogóle nie wspomina o
sprawdzeniu istniejącego aktywnego stanu przed rozpoczęciem pracy.
