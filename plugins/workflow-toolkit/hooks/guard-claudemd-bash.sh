#!/usr/bin/env bash
# guard-claudemd-bash.sh — kanał BASH dla guardu anty-bloat (PreToolUse + PostToolUse, matcher: Bash).
#
# Geneza (karta kanban „Konsolidacja CLAUDE.global.md", 2026-09-01): guard-claudemd-bloat.sh ma
# matcher Write|Edit|MultiEdit, więc edycja pliku instrukcji przez Bash (`sed -i`, heredoc, skrypt)
# omija go W CAŁOŚCI. To nie jest teoretyczne — sesje pracujące w trybie „rób przez Bash" edytują
# tak domyślnie i tym kanałem weszło przekroczenie limitu na CLAUDE.global.md (253 > 240), którego
# guard nie zobaczył.
#
# Dlaczego dwie fazy, a nie jedna: payload Bash nie niesie `file_path` ani projekcji treści, więc
# nie da się policzyć wyniku PRZED zapisem. Czytamy więc stan pliku po fakcie i porównujemy ze
# snapshotem sprzed komendy — semantyka zostaje ta sama co w guardzie Write/Edit: blokujemy
# WYŁĄCZNIE wzrost ponad limit, edycje neutralne i skracające przechodzą. Bez snapshotu każdy
# `ls` w repo z plikiem nad limitem dawałby fałszywy blok.
#
# Kontrakt: fail-open na każdy błąd (brak jq, brak session_id, nieczytelny payload).
# Uwaga: exit 2 w PostToolUse nie cofa zapisu — wraca do modelu jako twarde polecenie
# skonsolidowania/cofnięcia. To detekcja po fakcie, nie prewencja; taniej niż brak kanału.
set -u
LIMIT=240   # linii — MUSI być zgodne z guard-claudemd-bloat.sh (jedno źródło progu w obu kanałach)
PHASE="${1:-post}"

payload=$(cat)

# Fast path: 99% komend Basha nie dotyka plików instrukcji — wychodzimy przed jq.
printf '%s' "$payload" | grep -qE 'CLAUDE\.md|AGENTS\.md|agent\.md' || exit 0
command -v jq >/dev/null 2>&1 || exit 0

cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
sid=$(printf '%s' "$payload" | jq -r '.session_id // ""')
[ -n "$cmd" ] || exit 0
[ -n "$sid" ] || exit 0

snap="${TMPDIR:-/tmp}/claudemd-bloat-${sid//[^A-Za-z0-9_-]/_}.snap"

# Kandydaci = pliki instrukcji wymienione w komendzie + zawsze-obecne pliki always-on.
# `~` rozwijamy ręcznie, bo w tokenie z JSON-a nie przechodzi przez expansion powłoki.
candidates() {
  printf '%s\n' "$cmd" \
    | grep -oE '[^[:space:]"'"'"'`;|&()]*(CLAUDE|AGENTS|agent)\.md' \
    | sed "s|^~|$HOME|"
  printf '%s\n' "$HOME/.claude/CLAUDE.md"
  [ -n "${CLAUDE_PROJECT_DIR:-}" ] && printf '%s\n' "$CLAUDE_PROJECT_DIR/CLAUDE.md" "$CLAUDE_PROJECT_DIR/AGENTS.md"
  printf '%s\n' "$PWD/CLAUDE.md" "$PWD/AGENTS.md"
}

measure() {
  candidates | sort -u | while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$f" ] || continue
    printf '%s\t%s\n' "$(wc -l < "$f" | tr -d ' ')" "$f"
  done
}

if [ "$PHASE" = "pre" ]; then
  measure > "$snap" 2>/dev/null || true
  exit 0
fi

[ -f "$snap" ] || exit 0   # brak snapshotu = nie wiemy czy urosło → fail-open

measure 2>/dev/null | while IFS=$'\t' read -r now f; do
  before=$(grep -F "	$f" "$snap" 2>/dev/null | head -1 | cut -f1)
  [ -n "$before" ] || continue          # plik nie istniał przed komendą → nie mamy bazy
  [ "$now" -gt "$before" ] || continue  # neutralne/skracające przechodzą
  [ "$now" -gt "$LIMIT" ] || continue
  echo "BLOK ANTY-BLOAT (kanał Bash): $f urósł $before → $now linii, limit $LIMIT. Zapis JUŻ SIĘ WYKONAŁ — cofnij go albo skonsoliduj plik do limitu w tej samej turze. Nie dopisuj do plików instrukcji przez sed/heredoc, żeby ominąć guard: fakt jednorazowy → plik pamięci (.claude/memory/), reguła nawracająca → hook reinject-rules.sh, reszta → skill." >&2
  rm -f "$snap"
  exit 2
done
status=$?
rm -f "$snap"
exit $status
