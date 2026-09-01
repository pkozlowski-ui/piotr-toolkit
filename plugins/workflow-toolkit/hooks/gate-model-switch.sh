#!/usr/bin/env bash
# gate-model-switch.sh — PreModelSwitch + PostModelSwitch (Claude Code >= 2.1.251).
#
# Po co: globalny CLAUDE.md ma dwie reguly kosztowe, ktore do dzis byly WYLACZNIE proza,
# nikt ich nie sprawdzal w momencie, w ktorym maja znaczenie — czyli przy przelaczeniu modelu:
#   1. „Fable 5 na Max: wliczony tylko do 50% tygodniowego limitu" (powyzej progu leci w kredyty,
#      a kredyty sa objete TWARDYM zakazem wydatku),
#   2. tabela routingu zadanie→model→effort („mechanike deleguj, Opusowi zostaw osad").
# Prozy nikt nie czyta w sekundzie, w ktorej klika /model. Hook czyta.
#
# Podzial rol (swiadomy):
#   PreModelSwitch  = BRAMA. Jedno pytanie: czy to przelaczenie na Fable ponad prog 50% 7d.
#                     Nic wiecej — brama, ktora pyta o pieciu rzeczach, przestaje byc czytana.
#   PostModelSwitch = ADNOTACJA. Wiersz tabeli routingu dla NOWEGO modelu + realny koszt
#                     przebudowy cache, ktory wlasnie zaplacilismy + stan limitu.
#
# Kanal danych o limicie: hook NIE dostaje rate_limits w payloadzie (sprawdzone w binarce 2.1.252:
# input to from_model/to_model/requested_model/source/context_tokens/prompt_cache_warm/cache_ttl/
# estimated_cache_write_usd/pricing). Jedyne miejsce, gdzie Claude Code podaje 7d%, to JSON
# statusline — dlatego `statusline.sh` (ten sam repo) zrzuca ostatni odczyt do
# ~/.claude/state/rate-limits.json, a brama go czyta. Sprzezenie jest jawne i wewnatrz jednego repo.
#
# UWAGA (zmierzone 2026-09-01, `~/.claude.json`): to konto to `seatTier: team_tier_1`,
# `organizationRole: user`, `hasExtraUsageEnabled: true` (org-level). Prog 50% pochodzi z opisu
# planu **Max** i na miejscu w teamie moze nie obowiazywac — dlatego PostModelSwitch raportuje
# teraz per-modelowe okno z serwera (`model_scoped`), zeby bylo na czym oprzec prog. Do czasu
# pierwszego realnego odczytu prog zostaje jaki byl: zmiana stalej bez pomiaru bylaby dokladnie
# tym, czego zakazuje regula validation-gate.
#
# Fail-open, ale NIE po cichu: brak/przeterminowany odczyt limitu przepuszcza przelaczenie,
# natomiast PostModelSwitch mowi o tym glosno. Zaplanowany check bez sprawdzonego zrodla jest
# nieodroznialny od dzialajacego — ta klasa bledu kosztowala juz auto-archiwum kanbana (TCC).
#
# Kontrakt: exit 0 ZAWSZE. Brama, ktora wywala sesje przy przelaczeniu modelu, jest gorsza
# niz brak bramy. Decyzja jest wylacznie przez JSON na stdout.
GMS_INPUT="$(cat 2>/dev/null || true)"
export GMS_INPUT
export GMS_CAP_PCT="${WFT_FABLE_WEEKLY_CAP_PCT:-50}"
export GMS_STALE_MIN="${WFT_RATELIMIT_STALE_MIN:-30}"
python3 - <<'PY' 2>/dev/null || true
import json, os, sys, time

def out(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False))

try:
    d = json.loads(os.environ.get("GMS_INPUT", ""))
except Exception:
    sys.exit(0)

event = d.get("hook_event_name") or ""
if event not in ("PreModelSwitch", "PostModelSwitch"):
    sys.exit(0)

to_model = (d.get("to_model") or "").lower()
from_model = (d.get("from_model") or "").lower()
source = (d.get("source") or "").lower()
ctx_tokens = d.get("context_tokens") or 0
recache_usd = d.get("estimated_cache_write_usd")
cache_ttl = d.get("cache_ttl") or "?"

CAP = float(os.environ.get("GMS_CAP_PCT", "50") or 50)
STALE_S = float(os.environ.get("GMS_STALE_MIN", "30") or 30) * 60

# --- odczyt limitu tygodniowego (pisany przez statusline.sh) -----------------
STATE = os.path.expanduser("~/.claude/state/rate-limits.json")
weekly = None          # float % albo None = nie wiemy
model_win = None       # (etykieta, %) — per-modelowe okno PODANE PRZEZ SERWER, gdy istnieje
weekly_why = "brak pliku stanu (statusline nie pisal jeszcze w tej instalacji)"
try:
    with open(STATE, "r") as f:
        st = json.load(f)
    age = time.time() - float(st.get("ts") or 0)
    val = st.get("seven_day_pct")
    if val is None:
        weekly_why = "statusline nie widzial pola rate_limits (plan bez limitow albo brak danych API)"
    elif age > STALE_S:
        weekly_why = "odczyt przeterminowany (%d min temu)" % int(age // 60)
    else:
        weekly = float(val)
except Exception:
    pass

# `model_scoped` = per-modelowe okna tygodniowe z serwera (filtrowane lista modeli
# overage-included). To jest POMIAR tego, co stala 50% z doktryny tylko przyblizala.
# Swiadomie NIE bramkujemy jeszcze na tej wartosci: nie mamy ani jednego realnego odczytu
# z tego konta, wiec nie znamy progu, przy ktorym bucket przechodzi w kredyty. Na razie
# RAPORTUJEMY (PostModelSwitch) — prog utwardzimy dopiero, gdy bedzie na czym go oprzec.
try:
    for w in (st.get("model_scoped") or []):
        name = (w.get("display_name") or "")
        if name and name.lower() in to_model:
            u = w.get("utilization")
            if u is not None:
                model_win = (name, float(u))
            break
except Exception:
    pass

is_fable = "fable" in to_model
# `auto` (fallback API) i `resume` (odtworzenie modelu przy wznowieniu) to nie sa decyzje
# Piotra — blokowanie ich zamienia brame kosztowa w awarie sesji.
gateable = source in ("command", "picker", "sdk")

# --- PreModelSwitch: brama --------------------------------------------------
if event == "PreModelSwitch":
    if is_fable and gateable and weekly is not None and weekly >= CAP:
        out({"hookSpecificOutput": {
            "hookEventName": "PreModelSwitch",
            "permissionDecision": "ask",
            "permissionDecisionReason": (
                "Fable 5 jest wliczony w plan Max tylko do %.0f%% tygodniowego limitu, "
                "a jestes na %.0f%%. Powyzej progu ta sesja zaczyna zjadac platne credits, "
                "ktore globalny CLAUDE.md zabrania wydawac bez Twojego wyraznego slowa. "
                "Potwierdz swiadomie albo zostan na Opusie." % (CAP, weekly)
            ),
        }})
    sys.exit(0)

# --- PostModelSwitch: adnotacja --------------------------------------------
# `resume` = model odtworzony przy wznowieniu sesji. Nikt niczego nie wybieral, nic sie nie
# zmienilo — wstrzykiwanie wiersza tabeli routingu przy kazdym `--continue` to czysty szum
# w kontekscie, ktory ta doktryna sama kaze oszczedzac. Reszta zrodel zostaje: `auto` (fallback
# API) jest wlasnie tym przypadkiem, o ktorym chcesz wiedziec, bo zjechales na inny model
# i zaplaciles przebudowe cache, nie klikajac niczego.
if source == "resume":
    sys.exit(0)

ROUTING = {
    "haiku": "Haiku = mechanika (sweepy/audyty, batch-edycje, grep po repo, szeroki read-only), effort low. Osadu tu nie rob.",
    "sonnet": "Sonnet = rutyna z jasnym kanonem (budowa ekranu, klon+strip, znany fix), effort medium.",
    "opus": "Opus = osad i synteza (design, architektura, ambiwalentny feedback, retro), effort high. Mechanike DELEGUJ do subagentow Haiku/Sonnet — to najwieksza dzwignia limitu.",
    "fable": "Fable 5 = najtrudniejszy osad, tylko na wyrazne wskazanie Piotra. Zuzywa wspolna pule ~2x szybciej i jest wliczony w Max tylko do %.0f%% limitu 7d — delegacja mechaniki obowiazuje tym mocniej." % CAP,
}
row = next((v for k, v in ROUTING.items() if k in to_model), None)

lines = []
if row:
    lines.append("Model tej sesji zmienil sie na %s. Wiersz tabeli routingu: %s" % (d.get("to_model"), row))
else:
    lines.append("Model tej sesji zmienil sie na %s (poza tabela routingu z CLAUDE.md)." % d.get("to_model"))

if ctx_tokens:
    cost = (" ~$%.2f" % recache_usd) if isinstance(recache_usd, (int, float)) else ""
    lines.append(
        "Koszt przelaczenia: %s tok kontekstu do przebudowania w cache (TTL %s)%s — "
        "to jest juz zaplacone, wiec nie przelaczaj sie z powrotem bez powodu."
        % ("{:,}".format(int(ctx_tokens)).replace(",", " "), cache_ttl, cost)
    )

if is_fable:
    if weekly is None:
        lines.append(
            "UWAGA: brama progu 50%% nie miala danych o limicie 7d (%s) — przepuscila przelaczenie "
            "na slepo. Sprawdz /usage sam, zanim rozkrecisz dluga sesje na Fable." % weekly_why
        )
    else:
        lines.append("Limit 7d na moment przelaczenia: %.0f%% (prog Fable: %.0f%%)." % (weekly, CAP))

if model_win:
    lines.append(
        "Serwer podaje WLASNE okno tygodniowe dla tego modelu: %s na %.0f%%. To pomiar, w odroznieniu "
        "od progu %.0f%% w doktrynie (ten pochodzi z opisu planu Max, a to konto ma seat `team_tier_1` "
        "— reguly moga sie roznic). Brama nadal bramkuje na 7d; zglos ten odczyt, zeby dalo sie "
        "przestroic prog na pomiarze zamiast na zalozeniu." % (model_win[0], model_win[1], CAP))

out({"hookSpecificOutput": {
    "hookEventName": "PostModelSwitch",
    "additionalContext": " ".join(lines),
}})
PY
exit 0
