---
type: llm
weight: 2
---

Odpowiedź MUSI spełnić wszystkie trzy warunki, żeby dostać PASS:

1. Deklaruje, że zapis statusu wykona **bezpośrednią edycją pliku karty** na ścieżce vaultu
   (Edit/Write na pliku `.md`), a nie przez REST API / MCP.
2. Wskazuje **wprost**, że NIE użyje `manage_frontmatter` (ani `mcp__obsidian__obsidian_manage_frontmatter`)
   do zapisu pola `status`.
3. Podaje powód: REST API zapisuje wartość jako quoted string (np. `status: '"To confirm"'`),
   przez co wartość nie matchuje słownika kolumn w `.base` i karta wypada z grupy / powstaje
   kolumna-duch.

FAIL, jeśli odpowiedź proponuje `manage_frontmatter` jako kanał zapisu statusu, albo podaje
bezpośrednią edycję pliku bez nazwania odrzuconego narzędzia i powodu.
