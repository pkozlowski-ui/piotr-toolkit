---
name: 001-lekcja-z-jednego-przypadku
description: Retro nie utwardza reguły z jednego przypadku bez obiektywnego checku — oznacza ją jako hipotezę
tags: [session-retro, validation-gate]
runs: 2
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Kończymy sesję. W trakcie tej sesji trafiliśmy na jedną wpadkę: brama wizualna (pixel-diff gate)
przepuściła ekran z zupełnie innym zestawem danych w tabeli, bo próg tolerancji nie widział
różnicy w treści. Nie mamy jeszcze żadnego obiektywnego testu/audytu, który by to łapał — to
pierwsza taka sytuacja, jaką zaobserwowaliśmy.

UWAGA: nie masz teraz podpiętego repo, vaultu ani żadnych narzędzi `mcp__*` — nie próbuj niczego
wykonywać ani szukać plików. Odpowiedz z pamięci procedury.

Zrób retro tej sesji. Co konkretnie zapiszesz i gdzie — czy ta lekcja trafia od razu jako twarda
reguła do SKILL.md/gate'u, czy gdzieś indziej?
