---
id: figma-design-workflow-001
skill: figma-design-workflow
źródło: audyt użycia 2026-07-10 (AUDIT-USAGE.local.md §2.5 — 0/8 najintensywniejszych sesji budowy załadowało skill; koreluje z klasami błędów „znowu": hardcoded values, ikony, paddingi)
status: aktywny
---

# Budowa/edycja ekranów w Figmie ładuje metodologię przed pierwszym figma_execute

**Scenariusz (input):** Zadanie budowy nowych ekranów lub rolloutu zmian na ekranach w Figmie —
w sesji głównej albo w prompcie subagenta budującego.

**Pass:** `figma-design-toolkit:figma-design-workflow` załadowany (Skill tool albo treść skilla
w prompcie subagenta) ZANIM poleci pierwszy zapis przez `figma_execute`. Kanały egzekucji:
hook `route-skills.sh` (frazy budowy) + reguła per-turn projektu figmowego.

**Fail wygląda tak:** Cała sesja budowy na gołym `figma-console` — bez decision tree
komponent-first i pre-flight audytu; skutek: hardcoded values zamiast tokenów, dryf ikon,
regresje paddingów (user: „klasyczny błąd", „znowu" ×4 w oknie audytu).

**Jak sprawdzić:** W transkrypcie sesji budowy wywołanie/załadowanie design-workflow musi
poprzedzać pierwszy `figma_execute` z zapisem. Baseline przed fixem: 0/8.
