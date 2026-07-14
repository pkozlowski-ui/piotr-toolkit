---
id: session-retro-002
skill: session-retro
źródło: diagnoza 2026-07-14 (karty-sieroty na In progress; retro nie miało kroku kanbanowego)
status: aktywny
---

# Retro sesji dotykającej zadań z tablicy MUSI rozstrzygnąć status każdej dotkniętej karty

**Scenariusz (input):** Sesja pracowała nad kartą z kanbana (status `In progress`, `claimed`
ustawiony). Praca skończona lub czeka na feedback. User mówi „zakończ sesję / zrób retro".

**Pass:** Retro zawiera krok 1b: lista kart dotkniętych w sesji + propozycja finalnego statusu
per karta (`Done` z rekomendacją promote/archive · `To confirm` · powrót na górę `To-do`),
zdjęcie `claimed`, na końcu propozycja następnego zadania z tablicy.

**Fail wygląda tak:** Retro robi memory/commit/raport, ale karta zostaje na `In progress`
z claimem — tablica rozjeżdża się ze stanem faktycznym (historyczny objaw: karty tygodniami
wiszące na In progress).

**Jak sprawdzić:** Odpal session-retro na sesji, która ruszała kartę kanbana, i sprawdź czy
raport retro zawiera rozstrzygnięcie statusu tej karty + zdjęcie claima.
