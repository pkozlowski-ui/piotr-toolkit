---
id: obsidian-feedback-sweep-003
skill: obsidian-feedback-sweep
źródło: sesja 2026-07-21 (Staff Record Detail + People, Tom) — karta-wskaźnik powstała 28 s po rejestrze, ale była jedyną z 109 nieobecną w cardOrders `.base`, wylądowała w „To confirm" i nie została zgłoszona w raporcie → user uznał, że nie powstała, rezultaty sweepu mogły umknąć
status: aktywny
---

# Karta-wskaźnik ląduje w kolumnie roboczej i jest wypchnięta w raporcie

**Scenariusz (input):** Sweep domyka rejestr z akcjonowalnymi/blokującymi itemami. Skill tworzy
kartę-wskaźnik zapisem pliku (kanoniczny kanał). Board = Bases (`.base` trzyma `cardOrders` jako
stan UI, uzupełniany dopiero przy interakcji).

**Pass:**
1. Karta dostaje `status: To-do` (kolumna robocza — trigger do wzięcia), NIGDY „To confirm".
   Wariant dozwolony: `In progress` + `blocked` tylko gdy robota po naszej stronie realnie ruszyła
   a czeka na cudzą decyzję.
2. Closeout sweepu zawiera wprost linię „karta-trigger: `[[…]]` → To-do" (human-notification
   niezależny od renderu tablicy).

**Fail wygląda tak:** Karta ląduje w „To confirm" (kolumna zarezerwowana — wchodzi tylko po pracy +
potwierdzeniu usera) i/lub sweep kończy się bez wypchnięcia karty w raporcie. Świeża karta z zapisu
pliku bywa nieuporządkowana (dół kolumny do czasu reconcile Bases) → user jej nie widzi → uznaje, że
nie powstała → rezultaty sweepu umykają.

**Jak sprawdzić:** Odpal sweep na próbnym rejestrze; sprawdź (a) `status` utworzonej karty = `To-do`
(nie „To confirm"), (b) czy odpowiedź zamykająca zawiera jawną linię z linkiem karty i kolumną.
