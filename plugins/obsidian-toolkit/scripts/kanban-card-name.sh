#!/usr/bin/env bash
# Turn a card TITLE into a filesystem- and YAML-safe kanban card name, or verify that one is
# already safe.
#
# Why this exists as a script and not as a rule in the skill: the rule already existed (skill
# gotcha + eval 009, written 2026-07-31) and was violated again on 2026-08-25 — a card was
# created as `Ogon po #488 — resztki sales-demo w Staff Experience.md`, which produced a 0-byte
# phantom note (`Ogon po.md`) and a wikilink that Obsidian read as note "Ogon po " + heading
# anchor "488 — …". A rule a session has to remember is not a gate. This is the gate: one place
# that owns the sanitizing, callable before the card file is written.
#
# The rule it encodes, and why each part:
#   `#`              — YAML comment marker. An unquoted `.base` entry truncates at it, and inside
#                      a `[[wikilink]]` everything after it is parsed as a heading anchor.
#   `^ [ ] |`        — Obsidian rejects or mangles these in note names (links and anchors break).
#   `#<digits>`      — rewritten to `PR <digits>` rather than just stripped, because the number is
#                      the useful part of a PR/issue reference and dropping the marker silently
#                      would lose the "which PR" reading.
#   leading/trailing
#   whitespace       — invisible, and a trailing space makes two visually identical names.
#
# Usage:
#   kanban-card-name.sh sanitize "<title>"   # prints the safe name (no .md), exit 0
#   kanban-card-name.sh check    "<name>"    # exit 0 safe; exit 2 unsafe + prints safe form
#
# Exit codes:
#   0  safe (check), or sanitized name printed (sanitize)
#   1  bad usage
#   2  check found an unsafe name — stderr says what and prints the safe form on stdout
set -euo pipefail

MODE="${1:-}"
INPUT="${2:-}"

if [[ -z "$MODE" || -z "$INPUT" ]]; then
  echo "usage: $(basename "$0") sanitize|check \"<title>\"" >&2
  exit 1
fi
[[ "$MODE" == "sanitize" || "$MODE" == "check" ]] || {
  echo "mode must be sanitize|check" >&2; exit 1; }

safe_name() {
  python3 - "$1" <<'PY'
import re, sys
name = sys.argv[1]
# Strip a .md the caller may have passed; it is re-added by whoever writes the file.
name = re.sub(r'\.md$', '', name)
# `#123` carries meaning (a PR/issue number) — keep the number, drop the marker.
name = re.sub(r'#\s*(\d+)', r'PR \1', name)
# Everything else Obsidian/YAML cannot carry in a note name just goes.
name = re.sub(r'[#^\[\]|]', '', name)
# Collapse the double spaces the substitutions above can leave behind.
name = re.sub(r'\s{2,}', ' ', name).strip()
if not name:
    sys.exit("sanitizing left an empty name")
print(name)
PY
}

SAFE="$(safe_name "$INPUT")"

if [[ "$MODE" == "sanitize" ]]; then
  echo "$SAFE"
  exit 0
fi

# check
BARE="${INPUT%.md}"
if [[ "$BARE" == "$SAFE" ]]; then
  exit 0
fi
echo "unsafe card name: ${INPUT}" >&2
echo "  reason: contains one of # ^ [ ] | or padding whitespace — breaks Obsidian links/anchors and YAML in .base" >&2
echo "$SAFE"
exit 2
