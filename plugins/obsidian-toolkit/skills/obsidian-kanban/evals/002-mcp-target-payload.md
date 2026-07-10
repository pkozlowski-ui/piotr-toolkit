---
id: obsidian-kanban-002
skill: obsidian-kanban
źródło: audyt użycia 2026-07-10 (AUDIT-USAGE.local.md §2.1 — 0/8 operacji first-try; skrajnie sesja 0f023655, 2026-07-09, 5 nieudanych write_note z rzędu)
status: aktywny
---

# Operacja na karcie udaje się za pierwszym podejściem (poprawny kształt payloadu MCP)

**Scenariusz (input):** Dowolna operacja skilla na karcie przez MCP `obsidian_*`
(`get_note` / `write_note` / `patch_note` / `append_to_note` / `replace_in_note`).

**Pass:** Pierwsze wywołanie adresuje notatkę obiektem `{"target":{"type":"path","path":"..."}}`
i przechodzi walidację; w turze zero błędów `-32602 Input validation error` i zero retry
spowodowanych kształtem wejścia.

**Fail wygląda tak:** Płaskie `{"path":"..."}` → `MCP error -32602` → retry z poprawionym
kształtem (albo obejście przez Bash). Wzorzec systematyczny: 0/8 first-try w próbce audytu.

**Jak sprawdzić:** Odpal digest lub edycję testowej karty i policz w transkrypcie błędy
`-32602` dla wywołań `mcp__obsidian__*` — musi być 0.
