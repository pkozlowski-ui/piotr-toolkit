#!/usr/bin/env bash
# heldout_split.sh <plugin:skill> <CHANGE_DATE[THH:MM]> [DEV_WINDOW_DAYS=60] [MIN_HELDOUT=3]
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
#
# GRANICA JEST GODZINOWA, NIE DZIENNA (naprawione 2026-09-01 po zmierzonej wpadce).
# `skill_trigger_context.py` filtruje z dokładnością do DNIA, więc `CHANGE_DATE=2026-08-31`
# wrzucało do held-outu CAŁY ten dzień — także wywołania sprzed zmiany. Zmierzony przypadek:
# fix `design-tweaker` wszedł 2026-08-31 o 13:31, a skrypt raportował „✓ held-out ma 15 wywołań
# (≥ 3)" — gdy wszystkie 15 bylo z przedzialu 09:14-13:04, czyli SPRZED zmiany. Realny held-out: 0.
# Bramka mowila „przeszlo" o probce, ktorej zmiana nie mogla dotyczyc — dokladnie ta awaria,
# przed ktora ostrzega akapit wyzej, tyle ze na calym dniu zamiast na jednym case'ie.
# Prozaiczne ostrzezenie („odejmij case bedacy zrodlem fixa") tego nie lapalo: mowi o JEDNYM
# case'ie, a tu pre-change byl caly kubelek.
#
# Dlatego:
#   • `CHANGE` przyjmuje `YYYY-MM-DD` albo `YYYY-MM-DDTHH:MM` (czas LOKALNY, jak `git log`),
#   • sama data = zmiana traktowana jako wchodzaca na KONIEC tego dnia (23:59). Caly dzien
#     graniczny idzie do dev-setu. To wybor ZACHOWAWCZY: gate ma zanizac held-out, nie zawyzac,
#     bo zawyzony przepuszcza niezwalidowana zmiane.
#   • godzine podaj, gdy chcesz precyzji — skrypt wtedy tnie co do minuty.
set -euo pipefail

SKILL="${1:?usage: heldout_split.sh <plugin:skill> <CHANGE_DATE> [DEV_WINDOW_DAYS] [MIN_HELDOUT]}"
CHANGE_IN="${2:?brakuje CHANGE_DATE (YYYY-MM-DD[THH:MM]) — momentu, w którym reguła się zmieniła}"
CHANGE="${CHANGE_IN%%T*}"                       # sama data — do filtrów dziennych CTX
CHANGE_CLOCK="${CHANGE_IN#*T}"
if [ "$CHANGE_CLOCK" = "$CHANGE_IN" ]; then
  CHANGE_CLOCK="23:59"; CHANGE_PRECISE=0        # sama data → koniec dnia (zachowawczo)
else
  CHANGE_PRECISE=1
fi
# Znacznik odciecia w UTC — timestampy w transkryptach sa w UTC ('...Z'), a `git log` pokazuje
# czas lokalny. Bez tej konwersji granica przesuwalaby sie o offset strefy.
CUT_UTC="$(python3 -c "
import datetime,sys
d=datetime.datetime.fromisoformat(sys.argv[1]+' '+sys.argv[2]).astimezone()
print(d.astimezone(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%S'))" "$CHANGE" "$CHANGE_CLOCK")"
WINDOW="${3:-60}"
MIN_HELDOUT="${4:-3}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTX="$HERE/skill_trigger_context.py"

back() { # date - N days, portable
  date -j -v-"$2"d -f %Y-%m-%d "$1" +%Y-%m-%d 2>/dev/null \
    || date -d "$1 - $2 days" +%Y-%m-%d
}
DEV_FROM="$(back "$CHANGE" "$WINDOW")"

tmp_dev="$(mktemp)"; tmp_ho="$(mktemp)"; tmp_all="$(mktemp)"
trap 'rm -f "$tmp_dev" "$tmp_ho" "$tmp_all"' EXIT

# CTX tnie po dniach, wiec dzien graniczny bierzemy w CALOSCI, a potem rozdzielamy go
# po znaczniku czasu — inaczej wywolania sprzed zmiany wyladowalyby w held-oucie.
# HELDOUT_ROOT — katalog transkryptów zamiast ~/.claude/projects. Istnieje dla selftestu:
# bez tego granicy czasowej nie da się sprawdzić inaczej niż na żywych danych, które się zmieniają.
python3 "$CTX" "$SKILL" "$DEV_FROM" ${HELDOUT_ROOT:+"$HELDOUT_ROOT"} >"$tmp_all" 2>/dev/null || true
awk -v cut="$CUT_UTC" -F' \\| ' '$1 <  cut' "$tmp_all" >"$tmp_dev"
awk -v cut="$CUT_UTC" -F' \\| ' '$1 >= cut' "$tmp_all" >"$tmp_ho"

n_dev=$(grep -c . "$tmp_dev" || true)
n_ho=$(grep -c . "$tmp_ho" || true)

echo "== $SKILL · zmiana $CHANGE $CHANGE_CLOCK (odcięcie $CUT_UTC UTC) =="
if [ "$CHANGE_PRECISE" = "0" ]; then
  echo "   (podałeś samą datę → zmianę liczę jako wchodzącą na KONIEC $CHANGE."
  echo "    Cały dzień graniczny idzie do dev-setu. Podaj ${CHANGE}THH:MM, żeby uciąć co do minuty.)"
fi
echo
echo "-- dev-set: $DEV_FROM .. odcięcie  ($n_dev wywołań) --"
cat "$tmp_dev"
echo
echo "-- HELD-OUT: odcięcie .. dziś  ($n_ho wywołań) --"
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
