---
name: 007-atomowy-claim-lock
description: Wzięcie karty idzie przez atomowy lock; kolizja z żywą sesją to twardy STOP
tags: [obsidian-kanban, wspolbieznosc, lock]
runs: 2
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Mam na tej maszynie kilka równoległych sesji pracujących na jednym kanbanie w Obsidianie.
Weź kartę „Application Template Table".

Opisz mi mechanizm, którym zabezpieczysz się przed tym, że inna sesja robi tę samą kartę —
konkretnie: co uruchomisz, jakie kody wyjścia mogą wrócić i co zrobisz przy każdym z nich.

Rationale i rodowód tego case'a: `../007-atomowy-claim-lock.md`.
