---
id: design-tweaker-001
skill: design-tweaker
źródło: realna sesja 2026-07 (commit 3d9a112 — taste-skill słaby na skondensowany UI)
status: aktywny
---

# Routing egzekucji: dashboard / skondensowany UI NIE idzie do taste-skill

**Scenariusz (input):** Audyt dashboardu (gęsty, data-heavy UI: tabele, KPI, wykresy) kończy się
listą fixów look&feel; skill routuje egzekucję do innego skilla.

**Pass:** Egzekucja routowana do frontend-design / DS-driven build (lub wykonanie w ramach DS);
w rekomendacji pada ostrzeżenie, że taste-skill jest słaby na skondensowany UI.

**Fail wygląda tak:** Dashboard routowany do taste-skill → wynik rozjeżdża gęstą siatkę
informacji (taste-skill optymalizuje marketing/landing estetykę, nie information-dense UI).

**Jak sprawdzić:** Odpal design-tweaker na ekranie dashboardu i sprawdź sekcję routingu
w raporcie audytu.
