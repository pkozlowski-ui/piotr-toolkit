---
name: 007-atomowy-claim-lock
description: Wzięcie karty idzie przez atomowy lock; kolizja z żywą sesją to twardy STOP
tags: [obsidian-kanban, wspolbieznosc, lock]
runs: 2
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Mam na tej maszynie kilka równoległych sesji pracujących na jednym kanbanie w Obsidianie
i chcę, żebyś wziął kartę „Application Template Table".

UWAGA: nie masz teraz podpiętego vaultu ani narzędzi `mcp__obsidian__*` — nie próbuj niczego
wykonywać ani szukać plików. Odpowiedz z pamięci procedury: opisz dokładnie, jak byś to zrobił.

Opisz mechanizm, którym zabezpieczysz się przed tym, że inna sesja robi tę samą kartę:
co konkretnie uruchomisz, jakie kody wyjścia mogą wrócić, co zrobisz przy każdym z nich,
i co się dzieje przy domknięciu karty.
