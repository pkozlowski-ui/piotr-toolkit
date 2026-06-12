---
name: obsidian-setup
description: Podłączenie Claude Code do vaultu Obsidian (read/write notatek) przez Local REST API + MCP server, ustawienie permissionów i wpięcie vaultu w projekt. Uruchamia się gdy user mówi "podłącz obsidian", "skonfiguruj vault", "ustaw obsidian mcp", "połącz z vaultem", lub gdy skill obsidian-* nie ma narzędzi mcp__obsidian__*.
---

# Skill: obsidian-setup

## Cel
Jednorazowo podłączyć vault Obsidian do Claude Code, żeby działały skille `obsidian-*`
(`feedback-sweep`, `kanban`, `capture`). Infra — komplementarne do `init-project`/`bootstrap-machine`.

## Auto-trigger
- "podłącz obsidian" / "skonfiguruj vault" / "ustaw obsidian mcp" / "połącz z vaultem"
- gdy skill `obsidian-*` startuje, a narzędzia `mcp__obsidian__*` są niedostępne

## Wymagania wstępne
- Obsidian uruchomiony z otwartym vaultem.
- Plugin **Local REST API** (coddingtonbear) zainstalowany i włączony → skopiuj **API key** z jego ustawień.
- `node`/`npx` dostępne.

## Przepis (macOS)
```bash
claude mcp add obsidian --scope user \
  --env OBSIDIAN_API_KEY=<klucz z pluginu> \
  --env OBSIDIAN_BASE_URL=https://127.0.0.1:27124 \
  --env OBSIDIAN_VERIFY_SSL=false \
  -- npx -y obsidian-mcp-server
```
- Klucz trafia **tylko** do `~/.claude.json` (user scope) — **nigdy do repo**.
- HTTPS `27124` jest always-on (self-signed cert → `OBSIDIAN_VERIFY_SSL=false`); HTTP `27123` opcjonalny, domyślnie off.
- Narzędzia `mcp__obsidian__*` pojawiają się **po restarcie** Claude Code.

## ⚠️ GOTCHA — nazwa pakietu
README cyanheads reklamuje scoped `@cyanheads/obsidian-mcp-server`, ale **scoped 404-uje na npm**.
Działa **unscoped `obsidian-mcp-server`**. Gdy `claude mcp list` pokazuje `✗ Failed` — uruchom serwer wprost przez
`npx` z env i przeczytaj stderr (szybsze niż zgadywanie).

## Weryfikacja
- `claude mcp list | grep obsidian` → `✓ Connected`.
- Szybki test REST: `curl -sk https://127.0.0.1:27124/vault/ -H "Authorization: Bearer <klucz>"`.

## Permissiony (mniej klikania)
Dodaj do `settings.local.json` bezpieczne, powtarzalne narzędzia odczytu/edycji:
`mcp__obsidian__obsidian_get_note`, `…_list_notes`, `…_search_notes`, `…_manage_frontmatter`,
`…_replace_in_note`, `…_patch_note`, `…_write_note`, `…_open_in_ui`.
(`…_delete_note` zostaw bez auto-zgody — destrukcyjne.)

## Wpięcie vaultu w projekt
W `CLAUDE.md` projektu zanotuj: ścieżkę vaultu, które skille `obsidian-*` dotyczą, oraz configi
(`feedback-sweep`: folder rejestrów + macierz decydentów; `kanban`: plik `.base` + semantyka kolumn).
Vault bywa **cross-project** (np. osobisty board) — wtedy semantyka żyje w notatce w vaulcie, nie w jednym repo.

## Gotchas
- Wymaga **działającego Obsidiana** z otwartym vaultem — serwer to most do uruchomionej aplikacji.
- `obsidian_search_notes` (text) **fuzzy-matchuje** — do precyzji `get_note` (`document-map`/`section`) + `replace_in_note` na unikalnych stringach.
- Vault na Google Drive/iCloud — zapisy synchronizują się; kasowanie odwracalne przez kosz dysku.

## Raport
Status połączenia (`✓/✗`), co dodano do permissionów, co zanotowano w `CLAUDE.md` projektu.
