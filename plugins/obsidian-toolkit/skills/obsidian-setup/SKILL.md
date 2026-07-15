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

## Dwa kanały dostępu — treść (MCP) vs pliki (filesystem)
Vault jest osiągalny **dwiema drogami**; dobierz ją do operacji:
- **Treść notatki** (czytanie, edycja, frontmatter, search) → narzędzia `mcp__obsidian__*` (Local REST API). To jedyny sposób, by zmiany przeszły przez Obsidiana semantycznie.
- **Operacje na plikach** (move, rename, batch-przeniesienie) → **bezpośredni `mv`/`bash` na lokalnej ścieżce vaultu** (Google Drive/iCloud sam zsynchronizuje). MCP **nie ma operacji move/rename**.

⚠️ **Przenoszenie notatki (np. do `Done/`): użyj `mv`, NIE „write nową ścieżkę + delete starą".**
- MCP-owy „move" = `write_note(nowa ścieżka)` (tworzy kopię) + `delete_note(stara)` — **dwa kroki, ryzyko osieroconego duplikatu**, jeśli delete się nie powiedzie/zostanie anulowany (`delete_note` jest destrukcyjny → często bez auto-zgody).
- `mv "<vault>/Folder/Nota.md" "<vault>/Folder/Done/"` = **jeden atomowy ruch**, zero kopii, zero ryzyka. Szybsze i bezpieczniejsze.
- Wyjątek: gdy przy przenoszeniu chcesz też **zmienić frontmatter** (np. `status: open → done`, `closed:`) — zrób to osobno przez MCP (`manage_frontmatter`/`patch_note`) **przed** `mv`. `mv` nie dotyka treści.
- Ścieżkę lokalną vaultu znajdź raz: `find ~/Library/CloudStorage -maxdepth 4 -type d -name "<nazwa vaultu>"` (typowo `~/Library/CloudStorage/GoogleDrive-<konto>/Mój dysk/<Vault>`).

## Tryb chmurowy — Claude Code na web (git ↔ Obsidian Git), BEZ MCP/REST
Gdy Claude Code działa **w chmurze** (claude.ai/code, GitHub Action, kontener) — nie na maszynie z
Obsidianem — **nie ma dostępu do Local REST API ani do ścieżki vaultu na dysku**. Oba kanały wyżej
(MCP-treść, `mv`-pliki) zakładają Claude'a lokalnie i **tu nie działają**. Jedyny most to **git**:

```
Claude (cloud) edytuje pliki w klonie repo + commit + push na gałąź
   →  MERGE do gałęzi domyślnej (`main`)
   →  desktop: plugin Obsidian Git robi pull
   →  zmiana w vaulcie
```

**Warunek konieczny:** vault jest **repozytorium git** zsynchronizowanym z GitHubem (zamiast/obok
Google Drive/iCloud), a na desktopie działa plugin **Obsidian Git** (denolehov).

**Reguła nr 1 (najczęstsza wpadka):** zmiana z chmury pojawia się na desktopie **dopiero po merge do
gałęzi domyślnej**. Sam push na gałąź `claude/...` nie wystarczy — Obsidian Git ciągnie **tylko gałąź,
na której desktop aktualnie jest** (zwykle `main`) i **nie przełącza gałęzi sam**. Więc: każda zmiana,
która ma dojechać na tablicę/do notatek, musi wylądować w `main` (zmergowany PR).

**Ustawienia Obsidian Git na desktopie (żeby zmiany z chmury przychodziły same):**

| Ustawienie | Wartość | Po co |
|---|---|---|
| Pull on startup | ON | pobiera zmiany przy starcie Obsidian |
| Auto pull interval (min) | 5 | dociąga zmiany z `main` w tle |
| Auto commit-and-sync interval (min) | 5 | wypycha lokalne edycje z powrotem |
| Push / Pull on commit-and-sync | ON / ON | pełny cykl: stage → commit → pull → push |
| Merge strategy | Merge | integracja zdalnych commitów |

Sekcja **Advanced** — bez zmian (git w PATH, repo w roocie vaultu).

**Gotchas (chmura):**
- Świeżej gałęzi nie widać w *Switch branch* zanim desktop nie zrobi **Obsidian Git: Fetch** (lokalny git musi się o niej dowiedzieć). W normalnym flow i tak zostajesz na `main` — gałęzie są tylko po drodze w PR-ach.
- **Nie twórz realnego `CLAUDE.md`/plików, które lokalnie są symlinkami** z repo pamięci (`claude-memory`) — commit realnego pliku koliduje z symlinkiem przy pullu na desktopie.
- Dwukierunkowo (edytujesz na desktopie *i* w chmurze) → ustaw **Merge strategy on conflicts** świadomie; domyślne `None` zostawia znaczniki konfliktu w plikach.

Zweryfikowane 2026-07-15 (vault `obsidian-manta-vault`): karta założona przez Claude w chmurze → merge do `main` → pull → pojawiła się na tablicy Bases; usunięcie tą samą drogą też się przeniosło.

## Gotchas
- Wymaga **działającego Obsidiana** z otwartym vaultem — serwer to most do uruchomionej aplikacji.
- `obsidian_search_notes` (text) **fuzzy-matchuje** — do precyzji `get_note` (`document-map`/`section`) + `replace_in_note` na unikalnych stringach.
- Vault na Google Drive/iCloud — zapisy synchronizują się; kasowanie odwracalne przez kosz dysku. **Move plików rób przez `mv` na filesystemie, nie przez MCP copy+delete** (patrz sekcja „Dwa kanały dostępu").

## Raport
Status połączenia (`✓/✗`), co dodano do permissionów, co zanotowano w `CLAUDE.md` projektu.
