#!/usr/bin/env bash
# guard-claudemd-bloat.sh — PreToolUse (matcher: Write|Edit|MultiEdit)
# Gasi awarię #1: agent puchnie CLAUDE.md/AGENTS.md mimo reguły anty-bloat.
# Blokuje TYLKO edycje POWIĘKSZAJĄCE plik ponad limit — edycje neutralne
# i skracające (fix typo, konsolidacja) przechodzą. exit 2 = twardy blok.
LIMIT=240   # linii; podnieś jeśli za ciasno

payload=$(cat)
command -v jq >/dev/null 2>&1 || { exit 0; }   # bez jq nie blokujemy (fail-open)

tool=$(printf '%s' "$payload" | jq -r '.tool_name // ""')
path=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""')

case "$path" in
  *CLAUDE.md|*AGENTS.md|*agent.md) : ;;   # tylko pliki instrukcji
  *) exit 0 ;;
esac

cur=0; [ -f "$path" ] && cur=$(wc -l < "$path" | tr -d ' ')

block() {
  echo "BLOK ANTY-BLOAT: $path osiągnąłby ~$1 linii (limit $LIMIT). Nie dopisuj — skonsoliduj albo przenieś fakt do pliku pamięci (.claude/memory/). To Twoja reguła anty-bloat, egzekwowana deterministycznie." >&2
  exit 2
}

lines() { printf '%s' "$1" | grep -c '' ; }

case "$tool" in
  Write)
    content=$(printf '%s' "$payload" | jq -r '.tool_input.content // ""')
    new=$(lines "$content")
    [ "$new" -gt "$LIMIT" ] && block "$new"
    ;;
  Edit)
    old=$(printf '%s' "$payload" | jq -r '.tool_input.old_string // ""')
    neww=$(printf '%s' "$payload" | jq -r '.tool_input.new_string // ""')
    delta=$(( $(lines "$neww") - $(lines "$old") ))
    proj=$(( cur + delta ))
    [ "$delta" -gt 0 ] && [ "$proj" -gt "$LIMIT" ] && block "$proj"
    ;;
  MultiEdit)
    # nie liczymy delty per-edycja — jeśli plik już nad limitem, blokuj dalsze dopisywanie
    [ "$cur" -ge "$LIMIT" ] && block "$cur"
    ;;
esac
exit 0
