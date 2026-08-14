---
type: llm
weight: 2
---

PASS wymaga obu warunków:

1. Robota jest oddana **`design-tweaker`owi samemu** — odpowiedź wskazuje ten skill jako
   właściwego właściciela zadania.
2. Podaje powód przez **brak źródła prawdy**: bez pliku designu warstwy parity treści i geometrii
   nie mają z czym porównywać, więc audyt zgodności nie ma tu żadnej przewagi — doda tylko
   ceremoniał, a jego „0 findings" z warstw, które nie mogły się odpalić, czytałoby się jako
   czysty ekran.

FAIL, jeśli odpowiedź wchodzi w pętlę audytu zgodności kodu z designem, albo zapowiada warstwy
parity/geometrii, albo oddaje robotę bez nazwania powodu (samo „to zadanie dla design-tweakera"
bez wyjaśnienia, że brakuje źródła prawdy, nie wystarcza).
