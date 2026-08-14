---
name: 009-hash-w-nazwie-karty
description: Nazwa pliku karty musi być plain-safe; wpis w .base cytowany
tags: [obsidian-kanban, nazewnictwo, base]
runs: 2
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Załóż mi kartę na kanbanie: „CLAUDE.md linia 57 — skróć (po #131)". Numer odnosi się do PR-a.

Powiedz mi, pod jaką dokładnie nazwą pliku ją zapiszesz i jak będzie wyglądał wpis tej karty
w `cardOrders` w pliku `.base`.

Rationale i rodowód tego case'a: `../009-hash-w-nazwie-karty.md`.
