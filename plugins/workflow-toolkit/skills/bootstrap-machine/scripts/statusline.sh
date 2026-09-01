#!/usr/bin/env bash
# Status line pod doktryne kosztowa z globalnego CLAUDE.md.
#
# Pokazuje trzy rzeczy, ktore do tej pory byly w regulach tylko jako proza:
#   1. prompt cache  — realny TTL, warm/cold i hit ratio ("pracuj seriami" przestaje byc domyslem)
#   2. limity planu  — 5h i 7d ("TWARDY sufit wydatku": prog 50% na Fable 5, stop przed overage)
#   3. kontekst      — % zajetego okna (kiedy /clear, kiedy kompaktowac)
#
# Wejscie: JSON na stdin (schemat: https://code.claude.com/docs/en/statusline).
# `prompt_cache` wymaga Claude Code >= 2.1.251 i pojawia sie dopiero po pierwszej odpowiedzi API.
# Kazde pole czytane z fallbackiem — brak pola ma zniknac z linii, nie wywalic skryptu.
set -uo pipefail

IN="$(cat)"

jqr() { printf '%s' "$IN" | jq -r "$1" 2>/dev/null; }

# Pusty/niepoprawny stdin nie ma prawa wygladac na poprawny stan — lepiej jawny znacznik niz cicha pustka.
if ! printf '%s' "$IN" | jq -e . >/dev/null 2>&1; then
  printf '%s\n' "statusline: brak danych sesji na stdin"
  exit 0
fi

MODEL="$(jqr '.model.display_name // "?"')"
EFFORT="$(jqr '.effort.level // empty')"
FAST="$(jqr 'if .fast_mode then "⚡" else "" end')"
DIR="$(basename "$(jqr '.workspace.current_dir // .cwd // "?"')")"
BRANCH="$(jqr '.workspace.git_worktree // empty')"
CTX="$(jqr '.context_window.used_percentage // empty')"
COST="$(jqr '.cost.total_cost_usd // empty')"

# --- prompt cache -----------------------------------------------------------
CACHE=""
if [[ "$(jqr 'has("prompt_cache") and (.prompt_cache != null)')" == "true" ]]; then
  if [[ "$(jqr '.prompt_cache.caching_observed')" == "true" ]]; then
    TTL="$(jqr '.prompt_cache.ttl // "?"')"
    if [[ "$(jqr '.prompt_cache.warm')" == "true" ]]; then STATE="warm"; else STATE="COLD"; fi
    HIT="$(jqr 'if .prompt_cache.hit_ratio == null then "" else (.prompt_cache.hit_ratio * 100 | round | tostring) + "%" end')"
    MISS="$(jqr '.prompt_cache.misses // 0')"
    CACHE="cache ${STATE}/${TTL}"
    [[ -n "$HIT" ]] && CACHE="${CACHE} hit ${HIT}"
    [[ "$MISS" != "0" ]] && CACHE="${CACHE} miss ${MISS}"
  else
    CACHE="cache n/d"
  fi
fi

# --- limity planu -----------------------------------------------------------
LIM=""
H5="$(jqr '.rate_limits.five_hour.used_percentage // empty')"
D7="$(jqr '.rate_limits.seven_day.used_percentage // empty')"
[[ -n "$H5" ]] && LIM="5h $(printf '%.0f' "$H5")%"
if [[ -n "$D7" ]]; then
  D7R="$(printf '%.0f' "$D7")"
  # 50% tygodniowego limitu = prog, po ktorym Fable 5 schodzi z planu Max (globalny CLAUDE.md)
  [[ "$D7R" -ge 50 ]] && MARK="!" || MARK=""
  LIM="${LIM:+$LIM · }7d ${D7R}%${MARK}"
fi

# --- zrzut limitow dla bramy przelaczania modelu -----------------------------
# PreModelSwitch/PostModelSwitch NIE dostaja rate_limits w payloadzie, a statusline to jedyne
# miejsce, gdzie Claude Code je podaje. Zrzucamy ostatni odczyt, zeby `gate-model-switch.sh`
# mial na czym oprzec prog 50% na Fable 5. Zapis atomowy (mv), cicho przy bledzie —
# status line nie ma prawa sie wywalic przez ten dopisek.
{
  RL_DIR="$HOME/.claude/state"
  mkdir -p "$RL_DIR" 2>/dev/null
  RL_TMP="$(mktemp "$RL_DIR/.rate-limits.XXXXXX" 2>/dev/null)"
  if [[ -n "${RL_TMP:-}" ]]; then
    printf '%s' "$IN" | jq -c --argjson ts "$(date +%s)" '{
      ts: $ts,
      seven_day_pct: (.rate_limits.seven_day.used_percentage // null),
      five_hour_pct: (.rate_limits.five_hour.used_percentage // null)
    }' > "$RL_TMP" 2>/dev/null && mv -f "$RL_TMP" "$RL_DIR/rate-limits.json" 2>/dev/null
    rm -f "$RL_TMP" 2>/dev/null
  fi
} 2>/dev/null || true

# --- zlozenie ---------------------------------------------------------------
L1="$MODEL"
[[ -n "$EFFORT" ]] && L1="$L1/$EFFORT"
[[ -n "$FAST"   ]] && L1="$L1$FAST"
L1="$L1 · $DIR"
[[ -n "$BRANCH" ]] && L1="$L1 (${BRANCH})"

L2=""
[[ -n "$CTX"   ]] && L2="ctx ${CTX}%"
[[ -n "$CACHE" ]] && L2="${L2:+$L2 · }$CACHE"
[[ -n "$LIM"   ]] && L2="${L2:+$L2 · }$LIM"
[[ -n "$COST"  ]] && L2="${L2:+$L2 · }\$$(printf '%.2f' "$COST")"

printf '%s\n' "$L1"
[[ -n "$L2" ]] && printf '%s\n' "$L2"
exit 0
