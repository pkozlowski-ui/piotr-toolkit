---
type: llm
weight: 2
---

To jest **wariant B**: draft niesie dokładnie jeden link (żywy prototyp z wszystkimi ekranami
naraz). PASS wymaga obu warunków:

1. Bullety ekranów (`Screens` / `What's built`) są **BEZ linków** — sześć nazwanych ekranów
   i jeden link do całości jest poprawne, to nie jest rozjazd liczb.
2. Ten jeden link występuje **w dokładnie jednym miejscu** w całym draftcie, jako jedyna pozycja
   sekcji zbiorczej (`Links` / `Figma`).

FAIL, jeśli draft rozbija jeden link na sześć bulletów-duplikatów (po jednym przy każdym ekranie),
albo jeśli powstają DWA miejsca z linkami — linki wpięte w treść **i** osobna lista pod spodem.
Dwa niezależne miejsca to dwa źródła prawdy edytowane osobno; dokładnie stąd bierze się rozjazd
liczb, przed którym ta reguła chroni.
