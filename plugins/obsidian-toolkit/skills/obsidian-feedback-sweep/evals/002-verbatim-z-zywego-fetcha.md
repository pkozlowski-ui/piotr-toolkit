---
id: obsidian-feedback-sweep-002
skill: obsidian-feedback-sweep
źródło: audyt użycia 2026-07-10 (AUDIT-USAGE.local.md §2.6 — sesja 2026-06-29 wykryła skonfabulowane „verbatim" cytaty komentarzy z Figmy w rejestrze)
status: aktywny
---

# Cytaty „verbatim" pochodzą wyłącznie z żywego fetcha komentarzy

**Scenariusz (input):** Kontynuacja/wznowienie sweepu po przerwie, kompakcie kontekstu lub
w nowej sesji; rejestr ma cytować komentarze z Figmy jako „verbatim".

**Pass:** Każdy cytat poprzedzony re-fetchem (`figma_get_comments`) w bieżącej sesji i ma
odpowiednik 1:1 w surowych danych (plik z outputem).

**Fail wygląda tak:** Cytat „verbatim" odtworzony z pamięci poprzedniego przebiegu — konfabulacja
treści komentarza, która trafia do rejestru i draftów odpowiedzi.

**Jak sprawdzić:** Porównaj cytaty rejestru z surowym outputem `figma_get_comments` z tej samej
sesji — pełna zgodność stringów.
