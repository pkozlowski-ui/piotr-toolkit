#!/usr/bin/env bash
# heldout_split.sh <plugin:skill> <CHANGE_DATE> [DEV_WINDOW_DAYS=60] [MIN_HELDOUT=3]
#
# Dzieli realne wywołania skilla na dwa kubełki wokół daty, w której zmieniono
# regułę/skill:
#
#   dev-set   [CHANGE_DATE-DEV_WINDOW .. CHANGE_DATE)   — na tym zmiana powstała
#   held-out  [CHANGE_DATE .. dziś]                     — tego nikt nie widział, pisząc regułę
#
# Po co skrypt, a nie oko: „przykłady nieużyte do wymyślenia zmiany" jest
# rozstrzygalne TYLKO po czasie. Kubełek wybierany z pamięci zawsze zawiera to,
# co zmianę zainspirowało — i wtedy gate przechodzi zawsze, czyli nie jest gate'em.
#
# Wypisuje oba kubełki i WERDYKT o wielkości held-outu. Poniżej MIN_HELDOUT
# kończy exit 1 — „za mało danych, żeby cokolwiek stwierdzić" to legalny wynik,
# a „przeszło na jednym przykładzie" nie.
set -euo pipefail

SKILL="${1:?usage: heldout_split.sh <plugin:skill> <CHANGE_DATE> [DEV_WINDOW_DAYS] [MIN_HELDOUT]}"
CHANGE="${2:?brakuje CHANGE_DATE (YYYY-MM-DD) — daty, w której reguła się zmieniła}"
WINDOW="${3:-60}"
MIN_HELDOUT="${4:-3}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTX="$HERE/skill_trigger_context.py"

back() { # date - N days, portable
  date -j -v-"$2"d -f %Y-%m-%d "$1" +%Y-%m-%d 2>/dev/null \
    || date -d "$1 - $2 days" +%Y-%m-%d
}
DEV_FROM="$(back "$CHANGE" "$WINDOW")"

tmp_dev="$(mktemp)"; tmp_ho="$(mktemp)"
trap 'rm -f "$tmp_dev" "$tmp_ho"' EXIT

python3 "$CTX" "$SKILL" "$DEV_FROM" "$CHANGE" >"$tmp_dev" 2>/dev/null || true
python3 "$CTX" "$SKILL" "$CHANGE" >"$tmp_ho" 2>/dev/null || true

n_dev=$(grep -c . "$tmp_dev" || true)
n_ho=$(grep -c . "$tmp_ho" || true)

echo "== $SKILL · zmiana $CHANGE =="
echo
echo "-- dev-set: $DEV_FROM .. $CHANGE  ($n_dev wywołań) --"
cat "$tmp_dev"
echo
echo "-- HELD-OUT: $CHANGE .. dziś  ($n_ho wywołań) --"
cat "$tmp_ho"
echo

if [ "$n_ho" -lt "$MIN_HELDOUT" ]; then
  echo "✗ HELD-OUT ZA MAŁY: $n_ho < $MIN_HELDOUT."
  echo "  Zmiany NIE wolno uznać za zwalidowaną behawioralnie. Dwa legalne wyjścia:"
  echo "  (1) oznacz ją jako HIPOTEZĘ i poczekaj na ruch w realnych sesjach;"
  echo "  (2) dołóż syntetyczne triggery (held-out-gate.md → źródło B) i oceń je ślepo —"
  echo "      pamiętając, że syntetyk waliduje ROZPOZNAWANIE triggera, nie wartość reguły."
  exit 1
fi

echo "✓ held-out ma $n_ho WYWOŁAŃ (≥ $MIN_HELDOUT) — ale to GÓRNA GRANICA, nie wielkość held-outu."
echo
echo "  Zanim uznasz bramkę za przeszłą, odejmij od $n_ho:"
echo "   • case'y 'nie dotyczy' — testowana reguła nie miała w nich zastosowania"
echo "     (reguła o linkach, a draft bez linków). 'Nie dotyczy' nie jest dowodem."
echo "   • case będący ŹRÓDŁEM fixa — wpadka, po której regułę napisano, wpada tu, gdy fix"
echo "     poszedł tego samego dnia. To dev-set, nie held-out."
echo "  Zostało < $MIN_HELDOUT ocenianych → werdykt to 'za mało danych', mimo zielonej bramki wyżej."
echo
echo "  RUBRYKA zależy od tego, CO zmieniłeś (held-out-gate.md, 'dwie soczewki'):"
echo "   • zmiana TRIGGERA (T)  → per wywołanie: trafiony / pominięty / fałszywy alarm"
echo "   • zmiana TREŚCI  (C)  → per wymaganie: spełnione / złamane / nie dotyczy"
echo "  Nie mieszaj ich. Gdy trigger wymusza hook (route-skills.sh), soczewka T mierzy regex hooka,"
echo "  nie treść SKILL.md — i zmiany treści nie mogą jej przesunąć."
