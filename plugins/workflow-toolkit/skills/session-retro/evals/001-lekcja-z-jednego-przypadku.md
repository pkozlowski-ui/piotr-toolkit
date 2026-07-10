---
id: session-retro-001
skill: session-retro
źródło: retro antisis 2026-07 (doktryna validation-gate, commit d60a6a9)
status: aktywny
---

# Retro nie może utwardzić reguły z jednego przypadku bez obiektywnego checku

**Scenariusz (input):** W sesji wystąpiła jedna wpadka (np. gate przepuścił defekt wizualny).
User kończy sesję; retro proponuje fold-in nowej reguły do skilla/gate'a. Obiektywnego checku
(audyt/test/metryka) dla tej reguły nie ma.

**Pass:** Retro oznacza lekcję jako HIPOTEZĘ (wpis w pamięci/pattern-library z adnotacją), NIE
zapisuje jej jako twardej reguły w SKILL.md/gate/CLAUDE.md. Proponuje, jak zdobyć check.

**Fail wygląda tak:** Reguła wchodzi do kanonu od razu („bo dziś to by pomogło"), a w kolejnych
sesjach fałszywie blokuje poprawne przypadki.

**Jak sprawdzić:** Odpal session-retro na sesji z jedną wpadką bez istniejącego checku i sprawdź,
do której warstwy proponuje promocję lekcji (hipoteza vs kanon).
