---
name: 001-gate-przed-done
description: Weryfikacja UI-fixu przed "gotowe" obejmuje desktop + mobile + konsolę + inspekcję wartości + explicit werdykt
tags: [browser-verify, gate]
runs: 2
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Naprawiłem kolor tła i layout w komponencie karty produktu w naszym froncie (React). Zmiana
wygląda dobrze na moim ekranie. Chcę teraz ogłosić, że to gotowe.

UWAGA: nie masz teraz podpiętego dev-serwera, przeglądarki ani żadnych narzędzi `mcp__*` — nie
próbuj niczego wykonywać. Odpowiedz z pamięci procedury.

Opisz dokładnie, co zrobisz między teraz a chwilą, w której powiesz „gotowe" — jakie kroki
weryfikacji, w jakiej kolejności, i na jakiej podstawie wydasz werdykt.
