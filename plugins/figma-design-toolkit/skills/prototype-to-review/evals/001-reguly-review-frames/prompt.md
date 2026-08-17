---
name: 001-reguly-review-frames
description: Prototyp→review buduje ze źródła kodu, nie tworzy nowych DS-masterów, adnotuje wpięte w węzły, dziedziczy font, i pyta o zakres przy ≥3 stanach
tags: [prototype-to-review, hard-rules]
runs: 2
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Mam działający prototyp we froncie (React + CSS modules) dla flow potwierdzenia rezerwacji:
cztery stany — `empty`, `filled`, `loading`, `success/error`. Jeden z elementów to custom
„status chip" (kolorowa plakietka ze statusem), którego nie ma w naszym design systemie. Chcę
dać to do async review w Figmie, żeby PM i QA mogli komentować bez odpalania kodu.

UWAGA: nie masz teraz podpiętego mostka do Figmy, przeglądarki ani żadnych narzędzi `mcp__*` —
nie próbuj niczego wykonywać ani szukać plików. Odpowiedz z pamięci procedury.

Opisz dokładnie, jak podejdziesz do tego zadania, zanim zaczniesz cokolwiek budować w Figmie.
