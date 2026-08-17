---
type: llm
weight: 2
---

PASS wymaga, żeby odpowiedź nazwała wprost, że **przed** pierwszym zapisującym `figma_execute`
stosuje metodologię `figma-design-workflow` (decision tree component-first / pre-flight audit
przed nowym komponentem / `figma.loadAllPagesAsync()` na starcie sesji / zasada „nigdy nie
detachuj instancji") — nie zaczyna od razu pisać skryptu budującego ekran.

FAIL, jeśli odpowiedź opisuje wyłącznie technikalia `figma_execute`/`figma-console` bez wzmianki
o wcześniejszym kroku metodologicznym, albo explicite mówi, że pominie ten krok, bo „wie już co
budować".
