---
name: 002-reference-lazy-load
description: Kanon przeniesiony z SKILL.md do reference/ jest nadal osiagalny — agent doczytuje plik referencyjny zamiast odpowiadac z pamieci
tags: [figma-design-workflow, lazy-load, reference]
runs: 2
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Pracuj wedlug skilla `figma-design-toolkit:figma-design-workflow` — zaladuj go i zastosuj jego
metodologie do ponizszego pytania.

Buduje karte w Figmie i chce, zeby padding 16 px i gap 16 px byly zwiazane z tokenami spacingu,
a nie wpisane na sztywno. Nie mam teraz mostka do Figmy — nie odpalaj zadnego `mcp__*` i niczego
nie wykonuj.

Napisz mi, jak poprawnie znalezc zmienna spacingu o wartosci 16 px i zwiazac ja z paddingiem oraz
gapem. Zaznacz wprost, czy jest tu jakas pulapka, na ktora mam uwazac.
