#!/usr/bin/env bash
# Selftest bramy przelaczania modelu. Odpala hook na syntetycznych payloadach
# z podstawionym HOME, zeby nie dotykac realnego ~/.claude/state.
# Uruchomienie: bash gate-model-switch.selftest.sh   (exit 0 = wszystko zielone)
set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/gate-model-switch.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/.claude/state"
FAIL=0

set_limit() { # $1 = 7d pct lub "none", $2 = wiek w sekundach
  if [[ "$1" == "none" ]]; then rm -f "$TMP/.claude/state/rate-limits.json"; return; fi
  printf '{"ts":%s,"seven_day_pct":%s,"five_hour_pct":10}' "$(( $(date +%s) - $2 ))" "$1" \
    > "$TMP/.claude/state/rate-limits.json"
}

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

echo "Odpornosc:"
check "smiec na stdin → cisza"               ''                             "$(HOME="$TMP" bash "$HOOK" <<<'nie-json')"
check "pusty stdin → cisza"                  ''                             "$(HOME="$TMP" bash "$HOOK" </dev/null)"
check "obcy event → cisza"                   ''                             "$(HOME="$TMP" bash "$HOOK" <<<'{"hook_event_name":"PreToolUse"}')"
HOME="$TMP" bash "$HOOK" <<<'nie-json' >/dev/null 2>&1; [[ $? -eq 0 ]] && echo "  ok   exit 0 przy smieciu" || { echo "  FAIL exit != 0"; FAIL=1; }

[[ $FAIL -eq 0 ]] && echo "WSZYSTKO ZIELONE" || echo "SA BLEDY"
exit $FAIL
