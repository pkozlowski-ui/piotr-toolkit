#!/usr/bin/env bash
# Selftest bramy przelaczania modelu. Odpala hook na syntetycznych payloadach
# z podstawionym HOME, zeby nie dotykac realnego ~/.claude/state.
# Uruchomienie: bash gate-model-switch.selftest.sh   (exit 0 = wszystko zielone)
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/gate-model-switch.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/.claude/state"
FAIL=0

set_limit() { # $1 = 7d pct lub "none", $2 = wiek w sekundach, $3 (opc.) = model_scoped JSON
  if [[ "$1" == "none" ]]; then rm -f "$TMP/.claude/state/rate-limits.json"; return; fi
  printf '{"ts":%s,"seven_day_pct":%s,"five_hour_pct":10,"model_scoped":%s}' \
    "$(( $(date +%s) - $2 ))" "$1" "${3:-null}" \
    > "$TMP/.claude/state/rate-limits.json"
}

# --- syntetyczne transkrypty (zrodlo GLOWNE bramy od 1.39.0) -----------------
# $1 = waga dnia w mln, $2 = model (dom. claude-opus-5), $3 = tryb zapisu (dom. w), $4 = plik.
# Wage skladamy z samego `output_tokens` (waga 5x): out = waga_mln * 200 000.
mk_transcript() {
  python3 - "$TMP" "$1" "${2:-claude-opus-5}" "${3:-w}" "${4:-sess}" <<'PYX'
import datetime, json, os, sys
tmp, w, model, mode, name = sys.argv[1:6]
d = datetime.date.today()
ts = datetime.datetime(d.year, d.month, d.day, 12, 0, 0).astimezone()\
        .astimezone(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
rec = {"type": "assistant", "timestamp": ts,
       "message": {"model": model,
                   "usage": {"input_tokens": 0, "output_tokens": int(round(float(w) * 200_000)),
                             "cache_read_input_tokens": 0, "cache_creation_input_tokens": 0}}}
p = os.path.join(tmp, ".claude", "projects", "proj")
os.makedirs(p, exist_ok=True)
with open(os.path.join(p, name + ".jsonl"), mode) as f:
    f.write(json.dumps(rec) + "\n")
PYX
}
no_transcripts() { rm -rf "$TMP/.claude/projects" "$TMP/.claude/state/usage-ledger.json"; }

payload() { # $1 event, $2 to_model, $3 source, $4 ctx_tokens
  printf '{"hook_event_name":"%s","from_model":"claude-opus-5","to_model":"%s","requested_model":null,"source":"%s","context_tokens":%s,"prompt_cache_warm":true,"cache_ttl":"1h","estimated_cache_write_usd":0.9375,"pricing":{}}' \
    "$1" "$2" "$3" "$4"
}

check() { # $1 nazwa, $2 oczekiwany wzorzec ("" = pusty stdout), $3 faktyczny
  if [[ -z "$2" ]]; then
    if [[ -z "$3" ]]; then echo "  ok   $1"; else echo "  FAIL $1 — oczekiwano pustki, jest: $3"; FAIL=1; fi
  elif grep -q "$2" <<<"$3"; then echo "  ok   $1"
  else echo "  FAIL $1 — brak '$2' w: $3"; FAIL=1; fi
}

run() { HOME="$TMP" bash "$HOOK" <<<"$1"; }

echo "PreModelSwitch (brama):"
set_limit 62 60
check "Fable ponad progiem → ask"            '"permissionDecision": "ask"' "$(run "$(payload PreModelSwitch claude-fable-5 command 250000)")"
check "Fable ponad progiem → powod z liczba" '62%'                          "$(run "$(payload PreModelSwitch claude-fable-5 picker 250000)")"
check "Fable, ale source=auto (fallback)"    ''                             "$(run "$(payload PreModelSwitch claude-fable-5 auto 250000)")"
check "Fable, ale source=resume"             ''                             "$(run "$(payload PreModelSwitch claude-fable-5 resume 250000)")"
check "Opus przy 62% — nie nasza sprawa"     ''                             "$(run "$(payload PreModelSwitch claude-opus-5 command 250000)")"
set_limit 30 60
check "Fable ponizej progu"                  ''                             "$(run "$(payload PreModelSwitch claude-fable-5 command 250000)")"
set_limit 62 7200
check "Fable, odczyt przeterminowany → fail-open" ''                        "$(run "$(payload PreModelSwitch claude-fable-5 command 250000)")"
set_limit none 0
check "Fable, brak pliku stanu → fail-open"  ''                             "$(run "$(payload PreModelSwitch claude-fable-5 command 250000)")"

echo "PostModelSwitch (adnotacja):"
set_limit 30 60
O="$(run "$(payload PostModelSwitch claude-opus-5 picker 250000)")"
check "wiersz routingu dla Opusa"            'DELEGUJ'                      "$O"
check "koszt przebudowy cache"               '250 000 tok'                  "$O"
check "kwota re-cache"                       '0.94'                         "$O"
H="$(run "$(payload PostModelSwitch claude-haiku-4-5-20251001 sdk 12000)")"
check "wiersz routingu dla Haiku"            'mechanika'                    "$H"
set_limit none 0
F="$(run "$(payload PostModelSwitch claude-fable-5 command 250000)")"
check "Fable bez danych limitu → glosne UWAGA" 'UWAGA'                      "$F"
set_limit 62 60
F2="$(run "$(payload PostModelSwitch claude-fable-5 command 250000)")"
check "Fable z danymi → raport stanu limitu" 'Limit 7d'                     "$F2"
check "resume → cisza (nic sie nie zmienilo)" ''                            "$(run "$(payload PostModelSwitch claude-opus-5 resume 250000)")"
check "auto (fallback API) → nadal adnotuje" 'Wiersz tabeli routingu'       "$(run "$(payload PostModelSwitch claude-sonnet-5 auto 250000)")"

echo "Per-modelowe okno z serwera (model_scoped):"
set_limit 30 60 '[{"display_name":"Fable","utilization":41,"resets_at":null}]'
M="$(run "$(payload PostModelSwitch claude-fable-5 command 250000)")"
check "raportuje pomiar serwera"            'Fable na 41%'                 "$M"
check "nazywa go pomiarem vs doktryna"      'To pomiar'                    "$M"
check "przypomina o seat team_tier_1"       'team_tier_1'                  "$M"
set_limit 30 60 '[{"display_name":"Fable","utilization":41,"resets_at":null}]'
check "inny model → bez cudzego okna"       ''                             "$(run "$(payload PostModelSwitch claude-haiku-4-5-20251001 command 0)" | grep -o 'Fable na' || true)"
set_limit 30 60
check "brak model_scoped → adnotacja bez pomiaru" ''                       "$(run "$(payload PostModelSwitch claude-fable-5 command 0)" | grep -o 'Serwer podaje' || true)"

echo "Zrodlo glowne — transkrypty (gdy zrzutu statusline nie ma):"
set_limit none 0; no_transcripts; mk_transcript 300
A="$(run "$(payload PreModelSwitch claude-fable-5 command 250000)")"
check "Fable na drogim dniu, bez zrzutu → ask"     '"permissionDecision": "ask"' "$A"
check "…powod podaje wage dnia"                    'juz 300'                     "$A"
check "…i mowi wprost, ze to proxy, nie % limitu"  'proxy'                       "$A"
no_transcripts; mk_transcript 100
check "Fable na tanim dniu → przepuszcza"          ''  "$(run "$(payload PreModelSwitch claude-fable-5 command 250000)")"
no_transcripts; mk_transcript 300
check "drogi dzien, ale source=auto → przepuszcza" ''  "$(run "$(payload PreModelSwitch claude-fable-5 auto 250000)")"
check "drogi dzien, ale to Opus → nie nasza sprawa" '' "$(run "$(payload PreModelSwitch claude-opus-5 command 250000)")"
set_limit 30 60
check "swiezy zrzut ponizej CAP wygrywa z proxy"   ''  "$(run "$(payload PreModelSwitch claude-fable-5 command 250000)")"
set_limit 62 60
check "swiezy zrzut ponad CAP → ask (twardszy sygnal)" '"permissionDecision": "ask"' "$(run "$(payload PreModelSwitch claude-fable-5 command 250000)")"

echo "PostModelSwitch — raport z transkryptow:"
set_limit none 0; no_transcripts; mk_transcript 120
R="$(run "$(payload PostModelSwitch claude-opus-5 picker 250000)")"
check "raportuje dzien i okno 7d"                  'dzis 120'  "$R"
check "nazywa to proxy, nie % limitu"              'nie % limitu' "$R"
no_transcripts; mk_transcript 50 claude-fable-5; mk_transcript 60 claude-opus-5 a
RF="$(run "$(payload PostModelSwitch claude-fable-5 command 250000)")"
check "rozbija 7d na Fable"                        'Fable w 7 dniach: 50' "$RF"
no_transcripts; set_limit none 0
check "brak OBU zrodel → glosne SLEPA"             'SLEPA' "$(run "$(payload PostModelSwitch claude-fable-5 command 250000)")"

echo "Odpornosc:"
check "smiec na stdin → cisza"               ''                             "$(HOME="$TMP" bash "$HOOK" <<<'nie-json')"
check "pusty stdin → cisza"                  ''                             "$(HOME="$TMP" bash "$HOOK" </dev/null)"
check "obcy event → cisza"                   ''                             "$(HOME="$TMP" bash "$HOOK" <<<'{"hook_event_name":"PreToolUse"}')"
HOME="$TMP" bash "$HOOK" <<<'nie-json' >/dev/null 2>&1; [[ $? -eq 0 ]] && echo "  ok   exit 0 przy smieciu" || { echo "  FAIL exit != 0"; FAIL=1; }

[[ $FAIL -eq 0 ]] && echo "WSZYSTKO ZIELONE" || echo "SA BLEDY"
exit $FAIL
