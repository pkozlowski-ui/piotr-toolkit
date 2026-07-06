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
| 3. Cross-project | wpisy między-projektowe, **dane wrażliwe**, **globalny `CLAUDE.md`** (always-on reguły) | prywatny repo `claude-memory` ← symlink z globalnego `memory/` (+ `CLAUDE.global.md` ← symlink `~/.claude/CLAUDE.md`) | git (prywatny) |

**Zasada przewodnia:** trwała wiedza → git; lokalna pamięć → cache roboczy, promowany do git.

**Dwa kanały na warstwie 3 — nie myl ich** (lustro rozróżnienia z warstwy 1):
- **Globalny `CLAUDE.md`** (`claude-memory/CLAUDE.global.md`, symlink `~/.claude/CLAUDE.md`) = instrukcje
  **ładowane zawsze**, co sesję — stabilne reguły work-style / komunikacji / workflow obowiązujące we
  wszystkich projektach.
- **Pliki pamięci** (`type: user/feedback/reference`) = fakty **przywoływane na trafność**, gdy pasują do zadania.
- Reguła „stosuj zawsze, wszędzie" → globalny `CLAUDE.md`; fakt sytuacyjny → plik pamięci.
  (Analogicznie warstwa 1: projektowy `CLAUDE.md` always-on vs `.claude/memory/` retrieved.)

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
- **stabilna reguła/konwencja projektu** → projektowy `CLAUDE.md`,
- **stabilna reguła cross-project / work-style (always-on, dotyczy wszystkich projektów)** → **globalny `CLAUDE.md`** (`claude-memory/CLAUDE.global.md`),
- **decyzja "dlaczego tak"** → nowy ADR w `docs/decisions/`,
- **cross-project lesson / fakt sytuacyjny** → plik pamięci w warstwie 3 (`claude-memory`),
- **ulotny kontekst projektu** → zostaje w `.claude/memory/`.

Rozróżnienie projekt vs globalny `CLAUDE.md`: reguła ważna tylko w jednym repo → projektowy; reguła
work-style obowiązująca wszędzie → globalny.

**Bramka na promocję do kanonu (validation-gate):** utwardzaj regułę/skill/gate w kanonie DOPIERO
gdy masz obiektywny check, że nowa wersja jest lepsza (waliduj na przykładach held-out, nie regresuj
reszty); bez checku to hipoteza, nie kanon. Pełna doktryna → `session-retro` („Validation-gate —
ewolucja skilla / reguły / gate'u", wg Microsoft SkillOpt).

## Reguła odpływu / retirement (lustro promocji)

Promocja przesuwa wiedzę W GÓRĘ; bez odpływu pamięć tylko rośnie — cache nigdy się nie opróżnia, index
(`MEMORY.md`) puchnie, a dobre reguły toną w always-on. Dlatego na każdym retro rób też **sweep odpływu**:

- **Build-log zakończony** (`flow-*`/`man-*`/`fp-*` — praca shipped, zweryfikowana, **brak otwartych itemów**)
  → `mv` pliku do `.claude/memory/_archive/` + usuń linię z `MEMORY.md`. Zostaje w aktywnych tylko gdy ma żywe open-items.
- **Wpis pointer-only / restatement** (treść jest już kanonem w docs/registry/CLAUDE.md; wpis tylko „reguła żyje w X")
  → **usuń** — kanon + wskaźnik wystarczą.
- **„Pending decision" rozstrzygnięte** → zamknij/usuń (lub `_archive/` jeśli ma wartość historyczną).
- **Stale liczby/statusy inline** (np. „55 vs 74 wariantów") → przytnij do aktualnej; historia żyje w git.

Mechanika: `_archive/` jest poza filtrem indeksu, więc wpis wypada z always-on, a treść żyje (git-trwała).
**Archiwizuj (`mv`), nie kasuj** build-logów (zapis zrobionej roboty); pointer-only można usunąć (kanon istnieje).
**Cap:** gdy aktywnych (poza `_archive/`) wpisów > ~40 → wymuś sweep konsolidacji ZANIM dodasz nowe.

Symetria: promocja = w górę (trwała warstwa), odpływ = w bok (`_archive/`) lub usunięcie (gdy zredundowane).

### Wewnątrz `CLAUDE.md`: always-on vs on-demand (anti-bloat)

`CLAUDE.md` (projektowy i globalny) jest **always-on** — ładowany co sesję, kosztuje kontekst. Docs
(`components.md`, `registry`, ADR, blueprinty) ładują się **on-demand**, gdy je czytasz. Stąd, już
po zakwalifikowaniu reguły do warstwy CLAUDE.md, podziel ją dalej po **zasięgu**:

- **Przekrojowa** (dotyczy wielu obszarów / potrzebna ~każdej sesji: konwencje work-style, token-compliance,
  „buduj z instancji nie raw-frame", naming canon, bramki jakości) → **pełna treść w CLAUDE.md** (musi być
  always-on, inaczej zgubisz egzekwowanie).
- **Wąsko-specyficzna** (jeden komponent / obszar / plik; potrzebna tylko gdy go dotykasz: drabina
  wariantów komponentu, anatomia, konkretny wzorzec) → **pełny kanon w docs on-demand**, a w CLAUDE.md
  zostaw **skrócony imperatyw + wskaźnik** (`→ <docs> → <sekcja>`).

Nie duplikuj pełnej treści w obu miejscach: CLAUDE.md skrót + wskaźnik, kanon w docs. Przy zmianie reguły
edytuj **kanon** (docs) i ewentualnie skrót. Dotyczy też globalnego `CLAUDE.md` (always-on work-style
pełny; szczegóły jednego narzędzia/przepływu → osobny skill + wskaźnik).

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
