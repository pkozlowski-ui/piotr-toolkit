#!/usr/bin/env bash
# Selftest granicy czasowej held-outu. Buduje syntetyczne transkrypty o ZNANYCH godzinach
# i sprawdza, po ktorej stronie odciecia ladują — na zywych danych tego sprawdzic nie mozna,
# bo zmieniaja sie z kazda sesja.
#
# Po co ten test istnieje (zmierzona wpadka 2026-09-01): granica byla DZIENNA, wiec zmiana
# wchodzaca 2026-08-31 o 13:31 dostawala do held-outu caly ten dzien — 15 wywolan z przedzialu
# 09:14-13:04, czyli SPRZED zmiany. Skrypt raportowal „✓ held-out ma 15 (≥3)" o probce, ktorej
# zmiana nie mogla dotyczyc. Bramka mowila „przeszlo" tam, gdzie nie bylo czego mierzyc.
#
# Uruchomienie: bash heldout_split.selftest.sh   (exit 0 = zielone)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SPLIT="$HERE/heldout_split.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FAIL=0
SKILL="design-toolkit:design-tweaker"

# Jedno wywolanie skilla o zadanej godzinie LOKALNEJ; w transkrypcie zapisane jako UTC.
mk() { python3 - "$TMP" "$SKILL" "$1" <<'PYX'
import datetime, json, os, sys, uuid
tmp, skill, when = sys.argv[1:4]
d = datetime.datetime.fromisoformat(when).astimezone()
ts = d.astimezone(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")
proj = os.path.join(tmp, "projects", "fixture"); os.makedirs(proj, exist_ok=True)
rows = [
  {"type":"user","timestamp":ts,"message":{"role":"user","content":[{"type":"text","text":"zrob audyt"}]}},
  {"type":"assistant","timestamp":ts,"message":{"role":"assistant","content":[
      {"type":"tool_use","id":"t","name":"Skill","input":{"skill":skill}}]}},
]
with open(os.path.join(proj, uuid.uuid4().hex + ".jsonl"), "w") as f:
    for r in rows: f.write(json.dumps(r) + "\n")
PYX
}

run() { HELDOUT_ROOT="$TMP/projects" bash "$SPLIT" "$SKILL" "$1" 2>&1; }
nho() { run "$1" | sed -n 's/.*HELD-OUT: .* (\([0-9]*\) wywołań).*/\1/p'; }
ndev() { run "$1" | sed -n 's/.*dev-set: .* (\([0-9]*\) wywołań).*/\1/p'; }
ck() { if [ "$2" = "$3" ]; then echo "  ok   $1"; else echo "  FAIL $1 — oczekiwano $2, jest $3"; FAIL=1; fi; }

D="$(date -v-3d +%Y-%m-%d 2>/dev/null || date -d '3 days ago' +%Y-%m-%d)"
mk "${D}T09:14"; mk "${D}T11:00"; mk "${D}T13:04"   # PRZED zmiana o 13:31
mk "${D}T14:14"; mk "${D}T15:04"                     # PO zmianie

echo "Granica godzinowa (zmiana ${D} 13:31):"
ck "held-out liczy tylko to, co PO zmianie" 2 "$(nho "${D}T13:31")"
ck "reszta dnia laduje w dev-secie"         3 "$(ndev "${D}T13:31")"

echo "Sama data — zachowawczo, caly dzien do dev-setu:"
ck "held-out pusty"        0 "$(nho "$D")"
ck "dev-set ma wszystkie"  5 "$(ndev "$D")"
has() { case "$2" in *"$1"*) return 0;; *) return 1;; esac; }
OUT="$(run "$D")"
if has "KONIEC $D" "$OUT"; then echo "  ok   mowi wprost, ze liczy od konca dnia"
else echo "  FAIL brak informacji o zachowawczej granicy"; FAIL=1; fi

echo "Regresja pierwotnej wpadki (granica dzienna zawyzala held-out):"
ck "granica przed fala → held-out 5" 5 "$(nho "${D}T00:01")"
OUT2="$(run "${D}T13:31")"
if has "HELD-OUT ZA MAŁY: 2 < 3" "$OUT2"; then echo "  ok   2 < 3 to nadal 'za malo danych'"
else echo "  FAIL werdykt progu"; FAIL=1; fi

echo "Kod wyjscia:"
run "${D}T13:31" >/dev/null; HELDOUT_ROOT="$TMP/projects" bash "$SPLIT" "$SKILL" "${D}T13:31" >/dev/null 2>&1
ck "ponizej progu → exit 1" 1 "$?"
HELDOUT_ROOT="$TMP/projects" bash "$SPLIT" "$SKILL" "${D}T00:01" >/dev/null 2>&1
ck "prog spelniony → exit 0" 0 "$?"

echo
[ "$FAIL" = 0 ] && echo "SELFTEST: zielony" || echo "SELFTEST: CZERWONY"
exit "$FAIL"
