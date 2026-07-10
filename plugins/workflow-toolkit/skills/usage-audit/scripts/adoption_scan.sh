#!/usr/bin/env bash
# adoption_scan.sh [SINCE] — zlicza wywołania Skill tool per skill w transkryptach
# Claude Code od daty SINCE (default: 30 dni wstecz). Normalizuje prefiksy pluginów.
# Wyjście: "N  skill" malejąco + lista skilli toolkitu z zerem wywołań.
set -euo pipefail
SINCE="${1:-$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d)}"
PROJECTS="${CLAUDE_PROJECTS:-$HOME/.claude/projects}"
TOOLKIT="${TOOLKIT_ROOT:-$HOME/Documents/piotr-toolkit}"

echo "== Wywołania Skill od $SINCE =="
find "$PROJECTS" -name "*.jsonl" -newermt "$SINCE" \
  | xargs grep -ho '"name":"Skill","input":{"skill":"[^"]*"' 2>/dev/null \
  | sed 's/.*"skill":"//;s/"//' \
  | sed 's/^[a-z-]*-toolkit://' \
  | sort | uniq -c | sort -rn

echo
echo "== Skille toolkitu z 0 wywołań =="
used=$(find "$PROJECTS" -name "*.jsonl" -newermt "$SINCE" \
  | xargs grep -ho '"name":"Skill","input":{"skill":"[^"]*"' 2>/dev/null \
  | sed 's/.*"skill":"//;s/"//;s/^[a-z-]*-toolkit://' | sort -u)
for d in "$TOOLKIT"/plugins/*/skills/*/; do
  s=$(basename "$d")
  echo "$used" | grep -qx "$s" || echo "  0  $s"
done
