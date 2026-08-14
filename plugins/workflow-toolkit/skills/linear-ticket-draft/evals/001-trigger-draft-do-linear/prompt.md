---
name: 001-trigger-draft-do-linear
description: Fraza „draft do Linear" ładuje skill przed napisaniem treści; rejestr „opis taska", bez wysyłki
tags: [linear-ticket-draft, trigger, rejestr]
runs: 2
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Skończyliśmy robotę nad ticketem MAN-812 — filtrowanie listy aplikacji. Dostarczone:

- panel filtrów w drawerze, z licznikiem aktywnych filtrów na przycisku,
- zapisywane widoki („moje widoki" i widoki współdzielone z zespołem),
- pusty stan listy, gdy filtry nic nie zwracają, z akcją wyczyszczenia filtrów.

Prototyp: https://man-812-filters.vercel.app

Otwarte pytanie, którego sami nie rozstrzygnęliśmy: czy widoki współdzielone może edytować
każdy, kto je widzi, czy tylko autor.

Daj draft opisu do Lineara.
