#!/usr/bin/env bash
# Selftest bramy sufitu wydatku. Odpala hook na syntetycznych zrzutach limitu
# z podstawionym HOME, zeby nie dotykac realnego ~/.claude/state.
# Uruchomienie: bash gate-spend-ceiling.selftest.sh   (exit 0 = wszystko zielone)
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/gate-spend-ceiling.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/.claude/state"
FAIL=0

# $1 = 7d pct, $2 = 5h pct, $3 = wiek zrzutu w s, $4 = used_credits ("null" = brak extra_usage),
# $5 = is_enabled
# $6 (opcjonalny) = za ile sekund od teraz resetuja sie okna; brak = bez resets_at
set_state() {
  if [[ "$4" == "null" ]]; then XU=null
  else XU="{\"is_enabled\":$5,\"monthly_limit\":100,\"used_credits\":$4,\"utilization\":0.1,\"currency\":\"USD\"}"
  fi
  if [[ -n "${6:-}" ]]; then
    R="\"$(python3 -c "import datetime,sys;print((datetime.datetime.now(datetime.timezone.utc)+datetime.timedelta(seconds=int(sys.argv[1]))).strftime('%Y-%m-%dT%H:%M:%SZ'))" "$6")\""
  else R=null; fi
  printf '{"ts":%s,"seven_day_pct":%s,"five_hour_pct":%s,"seven_day_resets_at":%s,"five_hour_resets_at":%s,"extra_usage":%s}' \
    "$(( $(date +%s) - $3 ))" "$1" "$2" "$R" "$R" "$XU" > "$TMP/.claude/state/rate-limits.json"
}
no_state() { rm -f "$TMP/.claude/state/rate-limits.json"; }
set_base() { printf '{"acked_credits":%s,"month":"%s","acked_at":0}' "$1" "$(date +%Y-%m)" \
  > "$TMP/.claude/state/spend-ceiling-baseline.json"; }
# UWAGA: kasujemy TYLKO znaczniki „raz na dobe" — baseline (…-baseline.json) musi przetrwac,
# inaczej test blokady mierzy sciezke „pierwszy run" zamiast przyrostu.
clear_marks() { find "$TMP/.claude/state" -maxdepth 1 -name "spend-ceiling-*" ! -name "*.json" -delete 2>/dev/null; }

# --- syntetyczne transkrypty (zrodlo GLOWNE bramy) --------------------------
# $1 = docelowa waga dnia w mln, $2 = model (dom. claude-opus-5), $3 = ile dni wstecz (dom. 0),
# $4 = tryb zapisu: "w" nadpisuje plik, "a" dopisuje (test inkrementalnosci), $5 = nazwa sesji.
# Wage skladamy z samego `output_tokens` (waga 5x), zeby liczba w tescie byla oczywista:
# out = waga_mln * 200 000. Timestampy stawiamy w POLUDNIE lokalne i konwertujemy do UTC —
# inaczej test przy zmianie strefy wpadalby raz w dzien wczorajszy, raz w dzisiejszy.
mk_transcript() {
  python3 - "$TMP" "$1" "${2:-claude-opus-5}" "${3:-0}" "${4:-w}" "${5:-sess}" <<'PYX'
import datetime, json, os, sys
tmp, w, model, back, mode, name = sys.argv[1:7]
d = datetime.date.today() - datetime.timedelta(days=int(back))
local_noon = datetime.datetime(d.year, d.month, d.day, 12, 0, 0).astimezone()
ts = local_noon.astimezone(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
out_tok = int(round(float(w) * 200_000))
rec = {"type": "assistant", "timestamp": ts,
       "message": {"model": model,
                   "usage": {"input_tokens": 0, "output_tokens": out_tok,
                             "cache_read_input_tokens": 0, "cache_creation_input_tokens": 0}}}
p = os.path.join(tmp, ".claude", "projects", "proj")
os.makedirs(p, exist_ok=True)
with open(os.path.join(p, name + ".jsonl"), mode) as f:
    f.write(json.dumps(rec) + "\n")
PYX
}
# Kasuje ledger — inaczej offsety bajtowe z poprzedniego przypadku zafalszuja nastepny.
reset_ledger() { rm -f "$TMP/.claude/state/usage-ledger.json"; }
no_transcripts() { rm -rf "$TMP/.claude/projects"; reset_ledger; }

PAYLOAD='{"hook_event_name":"UserPromptSubmit","session_id":"selftest","prompt":"x"}'
# Powiadomienia macOS w tescie sa niepozadane — podmieniamy osascript na no-op.
mkdir -p "$TMP/bin"; printf '#!/bin/sh\nexit 0\n' > "$TMP/bin/osascript"; chmod +x "$TMP/bin/osascript"

run() { HOME="$TMP" PATH="$TMP/bin:$PATH" WFT_ALLOW_OVERAGE="${ALLOW:-}" \
        bash "$HOOK" <<<"$PAYLOAD" 2>"$TMP/err"; echo "rc=$?"; cat "$TMP/err"; }

check() { # $1 nazwa, $2 wzorzec ("" = pusty), $3 faktyczny
  if [[ -z "$2" ]]; then
    if [[ -z "${3//rc=0/}" ]]; then echo "  ok   $1"; else echo "  FAIL $1 — oczekiwano ciszy, jest: $3"; FAIL=1; fi
  elif grep -q -- "$2" <<<"$3"; then echo "  ok   $1"
  else echo "  FAIL $1 — brak '$2' w: $3"; FAIL=1; fi
}

echo "Swiezosc danych:"
clear_marks; no_state
check "brak zrzutu → fail-open, ale glosno raz" 'przepuszcza na slepo' "$(run)"
check "brak zrzutu → drugi raz cisza"           ''                     "$(run)"
clear_marks; set_state 20 20 7200 0 false
check "zrzut przeterminowany → fail-open glosno" 'przeterminowany'     "$(run)"

echo "Baseline i blokada:"
clear_marks; rm -f "$TMP/.claude/state/spend-ceiling-baseline.json"; set_state 20 20 60 3.50 true
O="$(run)"
check "pierwszy run z zastanym wydatkiem → NIE blokuje" 'rc=0'            "$O"
check "pierwszy run → przyjety baseline"                'baseline'        "$O"
check "baseline zapisany"                               '3.5'             "$(cat "$TMP/.claude/state/spend-ceiling-baseline.json")"
clear_marks
check "ten sam stan po baseline → brak blokady"         'rc=0'            "$(run)"

clear_marks; set_base 3.50; set_state 20 20 60 4.10 true
O="$(run)"
check "przyrost kredytow → BLOKADA (rc=2)"              'rc=2'            "$O"
check "blokada podaje delte"                            '0.60'           "$O"
check "blokada podaje sciezke ack"                      'gate-spend-ceiling.sh ack' "$O"
clear_marks
ALLOW=1 O="$(ALLOW=1 run)"
check "WFT_ALLOW_OVERAGE=1 → przepuszcza, ale glosno"   'rc=0'            "$O"
check "override nadal mowi STOP"                        'STOP'            "$O"
unset ALLOW

clear_marks; set_base 9.00; set_state 20 20 60 4.10 true
check "licznik spadl (nowy miesiac) → re-baseline, brak blokady" 'rc=0'   "$(run)"
check "re-baseline zapisany"                            '4.1'             "$(cat "$TMP/.claude/state/spend-ceiling-baseline.json")"

echo "Sufit po stronie konta:"
clear_marks; set_base 0; set_state 20 20 60 0 true
check "extra usage ON → ostrzezenie raz na dobe"        'WLACZONE extra usage' "$(run)"
check "extra usage ON → drugi raz cisza"                ''                "$(run)"
clear_marks; set_base 0; set_state 20 20 60 0 false
check "extra usage OFF → cisza"                         ''                "$(run)"

echo "Prog limitu planu:"
clear_marks; set_base 0; set_state 93 20 60 0 false
O="$(run)"
check "7d ponad progiem → ostrzezenie"                  'Blisko sufitu planu' "$O"
check "ostrzezenie nazywa okno"                         '7d 93%'          "$O"
check "ostrzezenie zakazuje wlaczania kredytow"         'NIE akceptuj'    "$O"
clear_marks
check "prog powtarza sie kazda ture (bez hysteresis)"   'Blisko sufitu planu' "$(run)"
clear_marks; set_state 20 95 60 0 false
check "5h ponad progiem → ostrzezenie"                  '5h 95%'          "$(run)"
clear_marks; set_state 20 20 60 0 false
check "ponizej progu → cisza"                           ''                "$(run)"

echo "Prog STOP (krawedz planu):"
clear_marks; set_base 0; set_state 99.4 20 60 0 true 1800
O="$(run)"
check "7d na krawedzi + extra usage ON → BLOKADA"       'rc=2'            "$O"
check "blokada nazywa okno i prog"                      'Okno 7d na 99%' "$O"
check "blokada podaje czas do resetu"                   'Reset za ~29 min' "$O"
clear_marks
check "ta sama sytuacja z WFT_ALLOW_OVERAGE=1 → przejscie" 'rc=0'          "$(ALLOW=1 run)"
clear_marks; set_base 0; set_state 99.4 20 60 0 false 1800
check "krawedz planu, ale extra usage OFF → brak blokady" 'rc=0'          "$(run)"
clear_marks; set_base 0; set_state 95 20 60 0 true 1800
O="$(run)"
check "miedzy WARN a STOP → tylko ostrzezenie"          'rc=0'            "$O"
check "…i to ostrzezenie o progu"                       'Blisko sufitu planu' "$O"

echo "Przeterminowany odczyt, ale okno wciaz gorace:"
clear_marks; set_base 0; set_state 99.5 20 7200 0 true 1800
O="$(run)"
check "stary odczyt >= STOP, reset jeszcze przed nami → BLOKADA" 'rc=2'   "$O"
check "blokada tlumaczy, czemu nie fail-open"           'nie spada przed resetem' "$O"
clear_marks; set_base 0; set_state 99.5 20 7200 0 true -60
check "stary odczyt >= STOP, ale reset juz minal → fail-open"    'rc=0'   "$(run)"
clear_marks; set_base 0; set_state 99.5 20 7200 0 true
check "stary odczyt >= STOP, brak resets_at → fail-open"         'rc=0'   "$(run)"
clear_marks; set_base 0; set_state 40 20 7200 0 true 1800
check "stary odczyt ponizej STOP → fail-open"                    'rc=0'   "$(run)"

echo "Swiezy zrzut, ale puste pola (rate_limits: null):"
clear_marks; rm -f "$TMP/.claude/state/spend-ceiling-baseline.json"
printf '{"ts":%s,"seven_day_pct":null,"five_hour_pct":null,"extra_usage":null}' "$(date +%s)" \
  > "$TMP/.claude/state/rate-limits.json"
O="$(run)"
check "swiezy-ale-pusty → glosno, nie cisza"            'SLEPA'           "$O"
check "…i nie blokuje"                                  'rc=0'            "$O"
check "…i raz na dobe"                                  ''                "$(run)"

echo "Tryb ack:"
clear_marks; set_base 0; set_state 20 20 60 7.25 true
check "ack re-baseline'uje" '7.25' "$(HOME="$TMP" bash "$HOOK" ack)"
check "ack zapisal baseline" '7.25' "$(cat "$TMP/.claude/state/spend-ceiling-baseline.json")"
clear_marks
check "po ack brak blokady" 'rc=0' "$(run)"

echo "Zrodlo glowne — transkrypty:"
clear_marks; no_state; no_transcripts
mk_transcript 100
check "dzien ponizej WARN → cisza"                    ''  "$(run)"
check "…i brama nie mowi, ze jest slepa"              ''  "$(run)"

clear_marks; no_transcripts; mk_transcript 300
O="$(run)"
check "dzien w [WARN, STOP) → ostrzezenie"            'Dzisiejsze zuzycie z transkryptow: 300' "$O"
check "ostrzezenie nazywa oba progi"                  'ostrzezenie od 268'  "$O"
check "…i nie blokuje"                                'rc=0'                "$O"
clear_marks
check "ostrzezenie powtarza sie kazda ture"           'Dzisiejsze zuzycie'  "$(run)"

clear_marks; no_transcripts; mk_transcript 400
O="$(run)"
check "dzien ponad STOP → BLOKADA (rc=2)"             'rc=2'                "$O"
check "blokada podaje liczbe i prog"                  'prog blokady 350'    "$O"
check "blokada podaje sciezke podgladu"               'usage'               "$O"
clear_marks
check "blokada z WFT_ALLOW_OVERAGE=1 → przepuszcza"   'rc=0'                "$(ALLOW=1 run)"
clear_marks
check "…ale nadal mowi STOP"                          'STOP'                "$(ALLOW=1 run)"

clear_marks; reset_ledger
check "prog przestrajalny przez env"                  'rc=2' "$(WFT_DAY_STOP=50 run)"
clear_marks; reset_ledger
check "podniesiony prog → brak blokady"               'rc=0' "$(WFT_DAY_STOP=9000 WFT_DAY_WARN=8000 run)"

echo "Okno dnia i inkrementalnosc:"
clear_marks; no_transcripts; mk_transcript 400 claude-opus-5 3
check "zuzycie sprzed 3 dni NIE wchodzi do dnia"      ''                    "$(run)"
clear_marks; no_transcripts; mk_transcript 200
run >/dev/null
mk_transcript 200 claude-opus-5 0 a
O="$(run)"
check "dopisana linia podbija licznik (offset dziala)" 'transkryptow: 400'  "$O"
clear_marks; no_transcripts; mk_transcript 400
run >/dev/null
mk_transcript 7 claude-opus-5 0 w      # plik podmieniony na krotszy — klasyczne obciecie
O="$(run)"
check "obciecie pliku nie dubluje dnia"               'rc=0'                "$O"
check "…licznik spadl do nowej wartosci"              'dzis 7'  "$(HOME="$TMP" bash "$HOOK" usage)"
# Podmiana na plik TEJ SAMEJ dlugosci: po rozmiarze nie do odroznienia od braku zmian,
# dlatego ledger trzyma i-node. Bez tego dzien policzylby sie dwa razy.
clear_marks; no_transcripts; mk_transcript 400
run >/dev/null
rm -f "$TMP/.claude/projects/proj/sess.jsonl"; mk_transcript 100 claude-opus-5 0 w
check "podmiana pliku tej samej dlugosci → licznik nie dubluje" 'dzis 100' "$(HOME="$TMP" bash "$HOOK" usage)"

echo "Wspolistnienie zrodel:"
clear_manual_marks() { :; }
clear_marks; no_transcripts; mk_transcript 400; set_base 0; set_state 20 20 60 0 false
check "transkrypty blokuja mimo spokojnego zrzutu"    'rc=2'                "$(run)"
clear_marks; no_transcripts; mk_transcript 100; set_base 3.50; set_state 20 20 60 4.10 true
check "zrzut blokuje mimo spokojnych transkryptow"    'rc=2'                "$(run)"
clear_marks; no_transcripts; mk_transcript 100; no_state
check "transkrypty dzialaja → brama NIE mowi ze jest slepa" '' "$(run)"

echo "Kalibracja:"
clear_marks; no_transcripts; mk_transcript 100; set_base 0; set_state 42 20 60 0 false
rm -f "$TMP/.claude/state/usage-calibration.jsonl"
run >/dev/null
check "para (waga, realne %) zapisana"  '"7d": 42' "$(cat "$TMP/.claude/state/usage-calibration.jsonl" 2>/dev/null)"
check "…z waga dnia z transkryptow"     '"day_w": 100' "$(cat "$TMP/.claude/state/usage-calibration.jsonl" 2>/dev/null)"
N1=$(wc -l < "$TMP/.claude/state/usage-calibration.jsonl" | tr -d ' ')
clear_marks; run >/dev/null
check "…i nie puchnie co ture (raz na godzine)" "^$N1\$" "$(wc -l < "$TMP/.claude/state/usage-calibration.jsonl" | tr -d ' ')"

echo "Tryb usage (podglad):"
no_transcripts; mk_transcript 123
O="$(HOME="$TMP" bash "$HOOK" usage)"
check "usage podaje dzien"    'dzis 123' "$O"
check "usage podaje progi"    'warn 268 / stop 350' "$O"
check "usage rozbija na modele" 'opus' "$O"

echo
if [[ "$FAIL" == "0" ]]; then echo "SELFTEST: zielony"; else echo "SELFTEST: CZERWONY"; fi
exit "$FAIL"
