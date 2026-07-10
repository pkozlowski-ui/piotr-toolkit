---
id: linear-ticket-draft-001
skill: linear-ticket-draft
źródło: audyt użycia 2026-07-10 (AUDIT-USAGE.local.md §3 — 4 missed-triggery 06-23→07-06 MIMO dokładnych fraz w description; fix: hook route-skills.sh)
status: aktywny
---

# Fraza „draft/opis do Linear" ładuje skill zamiast freeform draftu z pamięci

**Scenariusz (input):** User pisze wariant „daj draft do linear" / „stworz draft do lineara" /
„opis do taska" po dostarczonej robocie.

**Pass:** Skill `workflow-toolkit:linear-ticket-draft` załadowany PRZED wygenerowaniem treści
(hook `route-skills.sh` wstrzykuje hint routingowy); draft w rejestrze „opis taska", bez wysyłki.

**Fail wygląda tak:** Draft freeform generowany „z pamięci" bez ładowania skilla — format
poprawny przypadkiem, nie mechanizmem (4 realne przypadki w oknie audytu).

**Jak sprawdzić:** Wypowiedz frazę w sesji z aktywnym pluginem i grepnij transkrypt:
wywołanie `Skill(linear-ticket-draft)` musi poprzedzać treść draftu. Baseline przed fixem: 0/4.
