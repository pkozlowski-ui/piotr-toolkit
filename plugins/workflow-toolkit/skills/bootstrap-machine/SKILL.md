---
name: bootstrap-machine
description: Onboarding świeżej maszyny / odzyskanie środowiska Claude Code po przeprowadzce. Idempotentny runbook — klonuje repo (toolkit + pamięć + projekty), instaluje pluginy, odtwarza symlinki pamięci i global CLAUDE.md, instaluje zewnętrzne toole (figma-cli, figma-console MCP). Uruchamia się gdy user mówi "nowy laptop", "przeniosłem się", "odtwórz środowisko", "bootstrap maszyny", "po przeprowadzce", "setup nowego komputera".
---

# Skill: bootstrap-machine

## Cel

Po przeprowadzce na nowy komputer przeżywa tylko to, co jest w git. Ten skill odtwarza całą resztę
w powtarzalny, **idempotentny** sposób (każdy krok sprawdza „czy już zrobione" przed działaniem).
Doktryna stojąca za rozdziałem trwałość/lokalność: skill `memory-discipline`.

## Auto-trigger
"nowy laptop" · "przeniosłem się" / "po przeprowadzce" · "odtwórz środowisko" · "bootstrap maszyny" · "setup nowego komputera"

## Zasady
- **Idempotentnie.** Przed każdym krokiem sprawdź stan; nie nadpisuj istniejącego, nie klonuj dwa razy.
- **Nie zgaduj ścieżek.** Klony domyślnie w `~/Documents/<repo>`; potwierdź z userem jeśli ma inną konwencję.
- **Raportuj co pominięto** (bo już było) vs co utworzono.
- Dane wrażliwe są w prywatnym `claude-memory` — repo prywatne, klon wymaga auth (gh/SSH).

---

## Runbook (6 kroków)

### Krok 0 — Rozpoznanie
```bash
USER_HOME="$HOME"
gh auth status 2>&1 | head -3        # czy git/gh ma dostęp?
ls ~/Documents 2>/dev/null            # gdzie lądują klony
claude plugin marketplace list 2>&1   # co już skonfigurowane
```

### Krok 1 — Klonuj repo (idempotentnie)
Toolkit (public) + pamięć cross-project (private). Projekty wg potrzeb.
```bash
[ -d ~/Documents/piotr-toolkit ] || git clone https://github.com/pkozlowski-ui/piotr-toolkit.git ~/Documents/piotr-toolkit
[ -d ~/Documents/claude-memory ] || git clone https://github.com/pkozlowski-ui/claude-memory.git ~/Documents/claude-memory
```

### Krok 2 — Marketplace + pluginy
**Gotcha:** `claude plugin install …@marketplace` klonuje przez **SSH** i pada na repo bez klucza SSH.
Obejście: dodaj marketplace z **lokalnej ścieżki** klona (krok 1), bez sieci.
```bash
claude plugin marketplace list | grep -q pkozlowski-ui-marketplace || \
  claude plugin marketplace add ~/Documents/piotr-toolkit
for p in figma-design-toolkit workflow-toolkit design-toolkit; do
  claude plugin list 2>/dev/null | grep -q "$p@" || \
    claude plugin install "$p@pkozlowski-ui-marketplace"
done
# Po zmianach w klonie odśwież cache: claude plugin update <p>@pkozlowski-ui-marketplace
```

### Krok 3 — Symlinki pamięci (warstwa 3 + global)
Natywne katalogi Claude Code → klony git. Ścieżka projektu w `~/.claude/projects/` to **bezwzględna
ścieżka z `/` i spacjami zamienionymi na `-`**.
```bash
USER_SEG="-Users-$(whoami)"   # np. -Users-piotrkozlowski
# Pamięć cross-project (global):
GMEM="$HOME/.claude/projects/$USER_SEG/memory"
[ -L "$GMEM" ] || { rm -rf "$GMEM"; mkdir -p "$(dirname "$GMEM")"; ln -s ~/Documents/claude-memory "$GMEM"; }
# Global CLAUDE.md (git-trwały stub w claude-memory):
[ -L ~/.claude/CLAUDE.md ] || ln -s ~/Documents/claude-memory/CLAUDE.global.md ~/.claude/CLAUDE.md
```

### Krok 4 — Symlinki pamięci per-projekt
Dla każdego sklonowanego projektu, który trzyma pamięć w repo (`.claude/memory/`):
```bash
PROJ=~/Documents/"antisis prototype"        # przykład; powtórz per projekt
DASHED=$(echo "$PROJ" | sed 's#/#-#g; s# #-#g')   # /Users/.../antisis prototype → -Users-...-antisis-prototype
LINK="$HOME/.claude/projects/$DASHED/memory"
if [ -d "$PROJ/.claude/memory" ] && [ ! -L "$LINK" ]; then
  rm -rf "$LINK"; mkdir -p "$(dirname "$LINK")"; ln -s "$PROJ/.claude/memory" "$LINK"
fi
```

### Krok 5 — Zewnętrzne toole (Figma)
Nie są częścią pluginów — osobne repo. Instaluj gdy potrzebujesz figma-cli / figma_execute:
```bash
# figma-ds-cli (JSX render do Figmy) — patrz skill figma-cli
[ -d ~/figma-cli ] || git clone https://github.com/silships/figma-cli.git ~/figma-cli
# export FIGMA_CLI_PATH=~/figma-cli  → dodaj do ~/.zshrc
# figma-console MCP (figma_execute itd.) — patrz skill figma-console:
#   https://github.com/southleft/figma-console-mcp  (clone + rejestracja MCP wg README)
```

### Krok 6 — Weryfikacja
```bash
claude plugin list | grep -E "figma-design|workflow|design-toolkit"   # 3 pluginy
for L in ~/.claude/CLAUDE.md "$HOME/.claude/projects/$USER_SEG/memory"; do readlink "$L" || echo "BRAK: $L"; done
```
Po wszystkim: **restart sesji** (skille i pamięć ładują się na starcie). Zaproponuj userowi restart.

---

## Po bootstrapie — co zrobić ręcznie
- Uzupełnić stub `~/Documents/claude-memory/CLAUDE.global.md` (globalne zasady przepadają przy migracji — to świadomy stub).
- Ustawić `FIGMA_CLI_PATH` w `~/.zshrc` jeśli używasz figma-cli.
- Zarejestrować MCP figma-console wg jego README (krok 5).
