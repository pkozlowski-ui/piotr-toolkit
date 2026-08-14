---
type: llm
weight: 2
---

PASS wymaga wszystkich trzech:

1. **Pierwszym ruchem jest ustalenie tieru** (T0–T3) — odpowiedź nazywa tier wprost i mówi,
   czego ten projekt potrzebuje, żeby wyższy tier był w ogóle osiągalny (dla T3: plik designu
   jako źródło prawdy + node id per ekran + przechwycone baseline'y). NIE obiecuje T3 ani parity
   geometrii, nie mając rejestru ekranów i baseline'ów.
2. **Warstwa, która nie mogła się odpalić, jest raportowana jako „nie odpalona"**, a nie jako
   „0 findings". Odpowiedź mówi wprost, że brak baseline'ów to ograniczenie zakresu, nie czysty
   ekran — fałszywe uniewinnienie jest gorsze niż brak audytu.
3. **Osąd craftu jest delegowany do `design-tweaker`**, nie opisywany własnymi soczewkami w tym
   skillu.

FAIL, jeśli odpowiedź obiecuje pełne parity bez wymienienia warunków wejścia, albo zapowiada
raport „0 findings" z warstw, które nie mają z czym porównywać, albo implementuje osąd craftu
u siebie zamiast oddać go `design-tweaker`.
