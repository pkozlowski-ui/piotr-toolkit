#!/usr/bin/env bash
# guard-claudemd-bloat.sh — anty-bloat na plikach instrukcji (CLAUDE.md / AGENTS.md).
# Gasi awarię #1: agent puchnie plik instrukcji mimo reguły anty-bloat.
#
# Dwie warstwy, bo jedna nie wystarcza:
#   PreToolUse  (Write|Edit|MultiEdit|Bash) — BLOKUJE edycję powiększającą ponad limit.
#     Dla Write/Edit/MultiEdit zna dokladna delte. Dla Bash nie zna (payload niesie tylko
#     komende), wiec blokuje zapis do pliku, ktory JUZ jest nad limitem.
#   PostToolUse (te same narzedzia) — WYKRYWA przekroczenie, ktore weszlo mimo wszystko.
#     Potrzebne, bo komenda Bash moze pisac przez zmienna, skrypt albo heredoc w pythonie —
#     zadna heurystyka na tekscie komendy tego nie zlapie na pewno. Tu liczy sie realny stan
#     pliku po zapisie, nie zgadywanie z komendy.
#
# Edycje neutralne i skracające (fix typo, konsolidacja) przechodzą — blokujemy tylko WZROST.
# exit 2 = twardy blok (Pre) / feedback do modelu (Post).
LIMIT=240   # linii; podnieś jeśli za ciasno

payload=$(cat)
command -v jq >/dev/null 2>&1 || { exit 0; }   # bez jq nie blokujemy (fail-open)

tool=$(printf '%s' "$payload" | jq -r '.tool_name // ""')
event=$(printf '%s' "$payload" | jq -r '.hook_event_name // "PreToolUse"')
path=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""')

is_instr() { case "$1" in *CLAUDE.md|*AGENTS.md|*agent.md) return 0 ;; *) return 1 ;; esac; }
lines()    { printf '%s' "$1" | grep -c '' ; }
count()    { [ -f "$1" ] && wc -l < "$1" | tr -d ' ' || echo 0; }

# Pliki instrukcji, ktore realnie moga zostac ruszone w tej sesji. Symlink jest OK —
# `wc -l` czyta cel, a globalny CLAUDE.md wlasnie symlinkiem jest.
candidates() {
  printf '%s\n' \
    "$HOME/.claude/CLAUDE.md" \
    "${CLAUDE_PROJECT_DIR:-$PWD}/CLAUDE.md" \
    "${CLAUDE_PROJECT_DIR:-$PWD}/AGENTS.md" \
    "$PWD/CLAUDE.md" | sort -u
}

block() {
  echo "BLOK ANTY-BLOAT: $1 osiągnąłby ~$2 linii (limit $LIMIT). Nie dopisuj — skonsoliduj albo przenieś fakt do pliku pamięci (.claude/memory/). To Twoja reguła anty-bloat, egzekwowana deterministycznie." >&2
  exit 2
}

# ---- PostToolUse: realny stan po zapisie. Nie cofnie edycji, ale nie da jej przemilczec. ----
if [ "$event" = "PostToolUse" ]; then
  # Raportuj TYLKO pliki, ktore to narzedzie wlasnie ruszylo. Bez tego guard odzywa sie przy
  # kazdym `ls`, dopoki plik jest nad limitem — a guard, ktory szumi, zostaje wylaczony.
  # `stat` na symlinku czyta mtime CELU (-L), bo globalny CLAUDE.md wlasnie symlinkiem jest.
  now=$(date +%s)
  touched() {
    local m
    m=$(stat -L -f %m "$1" 2>/dev/null || stat -L -c %Y "$1" 2>/dev/null) || return 1
    [ $(( now - m )) -le 10 ]
  }
  over=""
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    touched "$f" || continue
    c=$(count "$f")
    [ "$c" -gt "$LIMIT" ] && over="${over}  · $f — $c linii (limit $LIMIT)"$'\n'
  done <<EOF
$( { is_instr "$path" && printf '%s\n' "$path"; candidates; } | sort -u )
EOF
  [ -z "$over" ] && exit 0
  echo "PRZEKROCZONY LIMIT ANTY-BLOAT (wykryte po zapisie):" >&2
  printf '%s' "$over" >&2
  echo "Nie dopisuj tam nic więcej. Skonsoliduj albo przenieś fakty do pliku pamięci (.claude/memory/)." >&2
  exit 2
fi

# ---- PreToolUse ----
if [ "$tool" = "Bash" ]; then
  cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
  # Interesuje nas tylko komenda, ktora WSPOMINA plik instrukcji I wyglada na zapis.
  # Samo czytanie (grep/cat/sed -n) ma przechodzic — inaczej guard blokuje wlasna diagnostyke.
  printf '%s' "$cmd" | grep -qE 'CLAUDE\.md|AGENTS\.md|agent\.md' || exit 0
  printf '%s' "$cmd" | grep -qE '>>?[[:space:]]*[^|&;]*(CLAUDE|AGENTS|agent)\.md|sed[[:space:]]+-i|tee[[:space:]]|open\(.*[wa]|\.write\(|writelines|truncate|dd[[:space:]]+of=' || exit 0
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    c=$(count "$f")
    [ "$c" -ge "$LIMIT" ] && block "$f" "$c"
  done < <(candidates)
  exit 0
fi

is_instr "$path" || exit 0
cur=$(count "$path")

case "$tool" in
  Write)
    new=$(lines "$(printf '%s' "$payload" | jq -r '.tool_input.content // ""')")
    [ "$new" -gt "$LIMIT" ] && block "$path" "$new"
    ;;
  Edit)
    old=$(lines "$(printf '%s' "$payload" | jq -r '.tool_input.old_string // ""')")
    neww=$(lines "$(printf '%s' "$payload" | jq -r '.tool_input.new_string // ""')")
    delta=$(( neww - old ))
    proj=$(( cur + delta ))
    [ "$delta" -gt 0 ] && [ "$proj" -gt "$LIMIT" ] && block "$path" "$proj"
    ;;
  MultiEdit)
    # nie liczymy delty per-edycja — jeśli plik już nad limitem, blokuj dalsze dopisywanie
    [ "$cur" -ge "$LIMIT" ] && block "$path" "$cur"
    ;;
esac
exit 0
