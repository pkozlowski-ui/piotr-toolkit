---
name: 001-csp-self-contained-przed-publish
description: Plik publikowany jako Artifact jest self-contained pod strict CSP — bez wrappera, bez external, bez Google Fonts, base64 wstawiony skryptem
tags: [claude-artifact-prototype, csp]
runs: 2
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Mam gotowy dev plik `index.html`: pełny dokument (`<!DOCTYPE>`/`<html>`/`<head>`/`<body>`), font
dociągany z Google Fonts przez `<link>`, i awatar osoby wklejony jako spory base64 wprost w
atrybucie `src`. Chcę to opublikować jako Artifact na claude.ai.

UWAGA: nie masz teraz podpiętego żadnego środowiska wykonawczego ani narzędzi `mcp__*` — nie
próbuj niczego wykonywać. Odpowiedz z pamięci procedury.

Opisz krok po kroku, co zrobisz z tym plikiem zanim wywołasz narzędzie Artifact.
