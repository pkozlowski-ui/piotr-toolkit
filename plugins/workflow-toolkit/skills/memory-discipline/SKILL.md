---
name: memory-discipline
description: Kanoniczna doktryna pamięci Claude Code — trwałość oparta na git (3 warstwy), schemat wpisu pamięci, reguła promocji i zasada danych wrażliwych. Wczytaj gdy zapisujesz/porządkujesz pamięć, zakładasz pamięć projektu, albo pytanie dotyczy "jak prowadzić pamięć / gdzie to zapisać / czemu pamięć przepadła".
---

# Skill: memory-discipline

Jedno źródło prawdy o tym **jak prowadzić pamięć** w ekosystemie Piotra. Inne skille
(`session-retro`, `init-project`) wykonują czynności; ten skill mówi **gdzie i w jakim formacie**.

## Dlaczego (lekcja)

Pamięć Claude Code domyślnie żyje w `~/.claude/projects/<ścieżka>/memory/` — **lokalnie, nie w git**,
kluczowana **bezwzględną ścieżką** projektu. Przy przeprowadzce na nowy laptop (albo przeniesieniu
repo) przepada. Przeżywa tylko to, co jest w git. Stąd doktryna: **trwałość = git**, a lokalna
pamięć to tylko cache roboczy.

Rozdzielamy dwa problemy, które łatwo pomylić:
- **Trwałość** (przeżyje migrację) → rozwiązuje git.
- **Retrieval** (szybkie znajdowanie) → na razie płaskie pliki + grep; semantyczny silnik (np. MemPalace)
  dopiero gdy skala tego wymaga, i zawsze **nad** git-trwałymi plikami, nie zamiast nich.

## Model 3 warstw

| Warstwa | Co | Gdzie | Trwałość |
|---|---|---|---|
| 1. Kanon projektu | reguły, decyzje, blueprinty, pamięć projektu | `CLAUDE.md` + `docs/` + **`.claude/memory/` w repo projektu** | git (repo projektu) |
| 2. Konwencje | "jak prowadzić pamięć" (ten skill) | `workflow-toolkit` (piotr-toolkit) | git (toolkit, public) |
| 3. Dane cross-project | osobiste / między-projektowe wpisy, **dane wrażliwe** | prywatny repo `claude-memory` ← symlink z globalnego `memory/` | git (prywatny) |

**Zasada przewodnia:** trwała wiedza → git; lokalna pamięć → cache roboczy, promowany do git.

## Trwałość przez symlink (warstwa 1 i 3)

Pamięć żyje w repo git, a natywny katalog Claude Code jest **symlinkiem** do niej — dzięki temu
zapisy pamięci automatycznie trafiają do repo (commit = backup).

- **Projekt:** `.claude/memory/` w repo ← symlink z `~/.claude/projects/<repo-path-z-myślnikami>/memory`.
- **Cross-project:** klon prywatnego `claude-memory` ← symlink z `~/.claude/projects/-Users-<user>/memory`.

**Odtworzenie po świeżym klonie / nowej maszynie:**
```bash
ln -s "<repo>/.claude/memory" "$HOME/.claude/projects/<repo-path-z-myślnikami>/memory"
```
(`<repo-path-z-myślnikami>` = bezwzględna ścieżka repo z `/` i spacjami zamienionymi na `-`).

## Schemat wpisu pamięci (kanoniczny)

Jeden plik = jeden fakt. Frontmatter:

```markdown
---
name: <krótki-slug-kebab-case>
description: <jedno zdanie — służy do oceny trafności przy recall>
metadata:
  type: user | feedback | project | reference
---

<treść; dla feedback/project dodaj linie **Why:** i **How to apply:**>
Linkuj powiązane: [[inny-slug]].
```

- `type=user` — kim jest użytkownik (rola, preferencje).
- `type=feedback` — jak mam pracować (korekty/potwierdzenia) + dlaczego.
- `type=project` — bieżąca praca/cele/ograniczenia nieoczywiste z kodu; daty względne → bezwzględne.
- `type=reference` — wskaźniki do zasobów (URL, dashboardy, ścieżki, ID).

**Kanon to `metadata.type`** (zgodnie z natywnym systemem pamięci Claude Code). Starsze warianty
(`type:` na top-levelu w template, `node_type:` w globalnej pamięci) traktuj jako legacy —
przy edycji migruj do `metadata.type`. Indeks: jedna linia w `MEMORY.md` (`- [Tytuł](plik.md) — hook`).

## Reguła promocji (retro)

Lokalna/projektowa pamięć to cache. Na koniec sesji (patrz `session-retro`):
- **stabilna reguła/konwencja** → `CLAUDE.md` projektu,
- **decyzja "dlaczego tak"** → nowy ADR w `docs/decisions/`,
- **cross-project lesson** → warstwa 3 (`claude-memory`),
- **ulotny kontekst projektu** → zostaje w `.claude/memory/`.

## Czego NIE zapisywać

- Tego, co repo już zapisuje: struktura kodu, historia git, treść CLAUDE.md, przeszłe fixy.
- Tego, co liczy się tylko w tej rozmowie.
- Jeśli proszą o zapis takiej rzeczy — zapytaj co było nieoczywiste i zapisz to.

## Dane wrażliwe

Hasła, dane klientów, sekrety, wewnętrzne URL-e → **wyłącznie warstwa 3** (prywatny `claude-memory`).
**Nigdy** do pamięci projektu współdzielonego repo ani do publicznego toolkitu.

## Relacja do innych skilli (do wyrównania)

- `session-retro` — wykonuje promocję wg tej doktryny.
- `init-project` — bootstrap pamięci powinien tworzyć `.claude/memory/` w repo + symlink (model warstwy 1),
  nie tylko lokalny `~/.claude/projects/<cwd>/memory/`. Jeśli jeszcze tego nie robi — to znany dług.
