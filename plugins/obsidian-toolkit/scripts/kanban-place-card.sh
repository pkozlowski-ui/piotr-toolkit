#!/usr/bin/env bash
# Place a kanban card at a chosen position inside its column's `cardOrders` list in the
# board's `.base` file.
#
# Why this exists as a script and not as "do it next time you have the board open":
# Bases keeps the view state in memory and rewrites `.base` on its own, so editing that file
# while Obsidian is running gets silently reverted a moment later. The edit therefore has to
# wait for a moment nobody can predict — which is exactly the kind of deferred, conditional
# chore that rots when it lives in someone's head. This runs on a timer, does nothing while
# Obsidian is up, and applies the change the first time it finds the app closed.
#
# Idempotent by construction: if the card already sits at the requested end of the column, it
# exits 0 without writing. Safe to run daily forever.
#
# Usage:
#   kanban-place-card.sh <base-file> <column> <card-path> [top|bottom]
#
# Exit codes:
#   0  applied, or already in place, or nothing to do (Obsidian running)
#   1  bad usage / board or card not found
set -euo pipefail

BASE_FILE="${1:-}"
COLUMN="${2:-}"
CARD="${3:-}"
WHERE="${4:-bottom}"

if [[ -z "$BASE_FILE" || -z "$COLUMN" || -z "$CARD" ]]; then
  echo "usage: $(basename "$0") <base-file> <column> <card-path> [top|bottom]" >&2
  exit 1
fi
[[ -f "$BASE_FILE" ]] || { echo "board not found: $BASE_FILE" >&2; exit 1; }
[[ "$WHERE" == "top" || "$WHERE" == "bottom" ]] || { echo "position must be top|bottom" >&2; exit 1; }

# The card file itself must exist — placing an entry for a card that is not there would put a
# dangling path into the board, which is the same class of silent staleness the repo's
# node-ID registry check exists to catch.
VAULT_ROOT="$(cd "$(dirname "$BASE_FILE")/.." && pwd)"
[[ -f "$VAULT_ROOT/$CARD" ]] || { echo "card not found: $VAULT_ROOT/$CARD" >&2; exit 1; }

# Refuse a card whose FILE NAME is not plain-safe, instead of merely quoting around it. Quoting
# the `.base` entry (further down) keeps that file parseable, but it does nothing about the two
# other symptoms of the same name: Obsidian materialises a phantom note at the truncation point,
# and a `[[wikilink]]` containing `#` resolves to "note + heading anchor" instead of the card
# (both measured — Manta board 2026-07-31, and again 2026-08-25 on a card that HAD a correctly
# quoted `.base` entry). The defect lives in the name, so this is a hard stop with the rename
# spelled out, not a warning that a session can read past.
NAME_GUARD="$(dirname "${BASH_SOURCE[0]}")/kanban-card-name.sh"
if [[ -x "$NAME_GUARD" ]]; then
  CARD_BASENAME="$(basename "$CARD")"
  if ! SAFE_BASENAME="$("$NAME_GUARD" check "$CARD_BASENAME" 2>/dev/null)"; then
    echo "refusing to place a card with an unsafe name: $CARD_BASENAME" >&2
    echo "  rename it first:" >&2
    echo "    mv \"$VAULT_ROOT/$CARD\" \"$VAULT_ROOT/$(dirname "$CARD")/${SAFE_BASENAME}.md\"" >&2
    echo "  then fix any [[wikilinks]] pointing at the old name and re-run this script." >&2
    exit 1
  fi
fi

if pgrep -x Obsidian >/dev/null 2>&1; then
  echo "obsidian running — skipping (Bases would revert the edit)"
  exit 0
fi

python3 - "$BASE_FILE" "$COLUMN" "$CARD" "$WHERE" <<'PY'
import re, sys, pathlib

base_file, column, card, where = sys.argv[1:5]
p = pathlib.Path(base_file)
text = p.read_text()
lines = text.split("\n")

# Walk to `cardOrders:` → `note.status:` → `<column>:` and collect that column's list.
# Deliberately positional rather than a YAML round-trip: the file is written by Bases, and
# re-emitting it through a YAML dumper would reformat parts nobody asked to touch.
def find(pred, start=0):
    for i in range(start, len(lines)):
        if pred(lines[i]):
            return i
    return -1

i_card_orders = find(lambda l: re.match(r'^\s*cardOrders:\s*$', l))
if i_card_orders < 0:
    print("no cardOrders block — nothing to do"); sys.exit(0)

i_status = find(lambda l: re.match(r'^\s*note\.status:\s*$', l), i_card_orders)
if i_status < 0:
    print("no note.status under cardOrders — nothing to do"); sys.exit(0)
status_indent = len(lines[i_status]) - len(lines[i_status].lstrip())

# The column key, at one level deeper than note.status.
i_col = -1
for i in range(i_status + 1, len(lines)):
    l = lines[i]
    if not l.strip():
        continue
    ind = len(l) - len(l.lstrip())
    if ind <= status_indent:
        break
    if re.match(rf'^\s*{re.escape(column)}:\s*$', l):
        i_col = i
        break
if i_col < 0:
    print(f"column {column!r} has no cardOrders list — nothing to do"); sys.exit(0)

col_indent = len(lines[i_col]) - len(lines[i_col].lstrip())

# Entries are `- KANBAN/Foo.md`, sometimes quoted when the name contains a colon.
entries, i_end = [], i_col + 1
for i in range(i_col + 1, len(lines)):
    l = lines[i]
    if not l.strip():
        i_end = i
        continue
    ind = len(l) - len(l.lstrip())
    if ind <= col_indent or not l.lstrip().startswith("- "):
        break
    entries.append((i, l))
    i_end = i + 1

def value_of(line):
    v = line.lstrip()[2:].strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
        v = v[1:-1]
    return v

existing = [value_of(l) for _, l in entries]
target_index = 0 if where == "top" else len(existing) - 1

if card in existing:
    if existing.index(card) == target_index:
        print(f"already at {where} of {column} — no write")
        sys.exit(0)
    # Present but in the wrong place: drop it, then re-insert below.
    drop_at = existing.index(card)
    del lines[entries[drop_at][0]]
    entries = [(i if i < entries[drop_at][0] else i - 1, l)
               for k, (i, l) in enumerate(entries) if k != drop_at]
    i_end -= 1

item_indent = " " * (col_indent + 2)

# Quote unless the path is plain-safe. `:` is the obvious one, but `#` is the dangerous one:
# an unquoted `- KANBAN/Card (po #131).md` is a YAML comment from `#` onward, so the next
# reader gets the path truncated to `KANBAN/Card (po` and can materialise a phantom card
# under that name (measured on the Manta board 2026-07-31 — one card, three files).
UNSAFE = set(':#"\'[]{},&*?|>!%@`\n\t')
quoted = f'"{card}"' if (UNSAFE & set(card) or card.strip() != card) else card
new_line = f"{item_indent}- {quoted}"

insert_at = (entries[0][0] if entries else i_col + 1) if where == "top" else i_end
lines.insert(insert_at, new_line)

p.write_text("\n".join(lines))
print(f"placed at {where} of {column}: {card}")
PY
