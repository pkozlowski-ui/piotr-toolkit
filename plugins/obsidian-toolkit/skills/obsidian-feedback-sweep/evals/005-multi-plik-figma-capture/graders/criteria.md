---
type: llm
weight: 2
---

PASS wymaga, żeby odpowiedź explicite sprawdziła/wymieniła **wszystkie znane pliki Figma
projektu** (tu: główny design file ORAZ FigJam „Collaboration Board") i pociągnęła komentarze
z KAŻDEGO z nich, zanim uzna, że nie ma nowej aktywności do triażu — nie ograniczy się do jednego
domyślnego/aktualnie otwartego pliku.

FAIL, jeśli odpowiedź czyta/planuje czytać tylko jeden plik (domyślny) i na tej podstawie
wnioskuje o braku nowości, albo w ogóle nie wspomina o istnieniu drugiego pliku (FigJam board).
