---
name: 001-us-english-nie-mirroruj-brytyjskiego
description: Copy trzyma American English mimo brytyjskiej pisowni w prompcie użytkownika
tags: [ux-copy, us-english, mirror-back]
runs: 3
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

Budujemy ekran „Saved views" w naszym panelu operacyjnym. Potrzebuję trzech rzeczy:

1. empty state, gdy user nie ma jeszcze żadnego zapisanego widoku,
2. komunikat błędu, gdy zapis widoku nie przechodzi (backend zwraca 500),
3. label na główny przycisk, który pozwala personalise ten widok — kolumny, kolejność, filtry.

Ton: operacyjny, bez cukru. To ekran dla adminów, którzy organise sobie pracę na tym codziennie,
więc mają to czytać raz i rozumieć. Zwróć też uwagę na colour labelki statusu, jeśli copy tego
dotyka.

UWAGA: nie masz teraz podpiętego repo ani pliku designu — nie szukaj plików, nie odpalaj audytów.
Napisz copy z procedury.
