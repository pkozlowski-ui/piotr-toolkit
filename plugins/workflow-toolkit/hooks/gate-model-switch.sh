#!/usr/bin/env bash
# gate-model-switch.sh — PreModelSwitch + PostModelSwitch (Claude Code >= 2.1.251).
#
# Po co: globalny CLAUDE.md ma dwie reguly kosztowe, ktore do dzis byly WYLACZNIE proza,
# nikt ich nie sprawdzal w momencie, w ktorym maja znaczenie — czyli przy przelaczeniu modelu:
#   1. „Fable 5 zuzywa pule ~2x szybciej; powyzej progu leci w kredyty, a kredyty sa objete
#      TWARDYM zakazem wydatku",
#   2. tabela routingu zadanie→model→effort („mechanike deleguj, Opusowi zostaw osad").
# Prozy nikt nie czyta w sekundzie, w ktorej klika /model. Hook czyta.
#
# Podzial rol (swiadomy):
#   PreModelSwitch  = BRAMA. Jedno pytanie: czy przelaczasz sie na Fable w drogim momencie.
#                     Nic wiecej — brama, ktora pyta o pieciu rzeczach, przestaje byc czytana.
#   PostModelSwitch = ADNOTACJA. Wiersz tabeli routingu dla NOWEGO modelu + realny koszt
#                     przebudowy cache, ktory wlasnie zaplacilismy + stan zuzycia.
#
# ZRODLO DANYCH — PRZEBUDOWANE 2026-09-01:
#   Hook NIE dostaje `rate_limits` w payloadzie (sprawdzone w binarce 2.1.252: input to
#   from_model/to_model/requested_model/source/context_tokens/prompt_cache_warm/cache_ttl/
#   estimated_cache_write_usd/pricing). Do 1.38.4 brama czytala wiec zrzut, ktory pisze
#   `statusline.sh` — a ten skrypt, zmierzone 2026-09-01, NIE JEST w tym interfejsie uruchamiany
#   w ogole (heartbeat czystym shellem: skasowany 12:57:44, nieobecny 12:59:49). Zrzut nigdy nie
#   powstawal, wiec `weekly` bylo zawsze None i brama NIGDY sie nie odpalila. To zamyka H20:
#   0 odpalen nie bylo bledem logiki, tylko brakiem zrodla.
#
#   Od tej wersji:
#     A) TRANSKRYPTY (`lib/usage-ledger.py`, `~/.claude/projects/*/*.jsonl`) — ZRODLO GLOWNE.
#        Dziala zawsze, bo pisze je sam Claude Code. Daje dzienna wage zuzycia i rozbicie
#        7d na rodziny modeli (ile Fable'a juz poszlo).
#     B) ZRZUT STATUSLINE — kanal OPCJONALNY. Gdy istnieje (terminalowy CLI), ma REALNE %
#        okien z serwera i `model_scoped` — twardszy sygnal niz proxy z tokenow, wiec ma
#        pierwszenstwo w bramkowaniu. Zostaje swiadomie (decyzja Piotra 2026-09-01).
#
# CZYM JEST PROG, A CZYM NIE JEST:
#   Stala 50% tygodniowego limitu pochodzi z opisu planu **Max**, a to konto to seat
#   `team_tier_1` (`organizationRole: user`, extra usage wlaczone org-wide) — NIEZWERYFIKOWANA.
#   `/usage` pokazal ponadto, ze Fable ma WLASNE okno tygodniowe (25%) obok puli all-models
#   (81%), czyli „wspolna pula" z doktryny jest prawdziwa tylko w polowie. Dlatego:
#     - gdy zrzut istnieje, bramkujemy na REALNYM 7d% z serwera wobec CAP (jak dotad),
#     - gdy zrzutu nie ma, bramkujemy na DZIENNEJ wadze z transkryptow wobec WFT_DAY_WARN
#       (ten sam prog p75, na ktorym ostrzega gate-spend-ceiling) — bo tego progu NIE zgadujemy,
#       tylko bierzemy z rozkladu wlasnych 18 dni roboczych.
#   Swiadomie NIE wymyslamy „progu Fable w tokenach": nie znamy limitu, wiec kazda taka stala
#   bylaby dokladnie tym, czego zakazuje regula validation-gate. Rozbicie per-model jest
#   RAPORTOWANE (PostModelSwitch), zeby bylo z czego prog kiedys zmierzyc.
#
# Fail-open, ale NIE po cichu: brak obu odczytow przepuszcza przelaczenie, a PostModelSwitch
# mowi o tym glosno. Zaplanowany check bez sprawdzonego zrodla jest nieodroznialny od
# dzialajacego — ta klasa bledu kosztowala juz auto-archiwum kanbana (TCC) i te brame.
#
# Kontrakt: exit 0 ZAWSZE. Brama, ktora wywala sesje przy przelaczeniu modelu, jest gorsza
# niz brak bramy. Decyzja jest wylacznie przez JSON na stdout.
GMS_INPUT="$(cat 2>/dev/null || true)"
export GMS_INPUT
export GMS_CAP_PCT="${WFT_FABLE_WEEKLY_CAP_PCT:-50}"
export GMS_STALE_MIN="${WFT_RATELIMIT_STALE_MIN:-30}"
export GMS_DAY_WARN="${WFT_DAY_WARN:-268}"
export GMS_DEADLINE="${WFT_USAGE_DEADLINE_S:-1.0}"   # krocej niz w bramie promptu: przelaczenie modelu ma byc natychmiastowe, a zaleglosci i tak dobierze nastepna tura
export GMS_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
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
source = (d.get("source") or "").lower()
ctx_tokens = d.get("context_tokens") or 0
recache_usd = d.get("estimated_cache_write_usd")
cache_ttl = d.get("cache_ttl") or "?"


def _f(name, dflt):
    try:
        return float(os.environ.get(name) or dflt)
    except Exception:
        return float(dflt)


CAP = _f("GMS_CAP_PCT", 50)
STALE_S = _f("GMS_STALE_MIN", 30) * 60
DAY_WARN = _f("GMS_DAY_WARN", 268)
DEADLINE = _f("GMS_DEADLINE", 2.5)

HOME = os.path.expanduser("~")
STATE_DIR = os.path.join(HOME, ".claude", "state")
PROJECTS = os.path.join(HOME, ".claude", "projects")
DUMP = os.path.join(STATE_DIR, "rate-limits.json")

# --- A) zrodlo glowne: transkrypty ------------------------------------------
usage = None
try:
    import importlib.util
    _lp = os.path.join(os.environ.get("GMS_LIB", ""), "usage-ledger.py")
    _spec = importlib.util.spec_from_file_location("usage_ledger", _lp)
    if _spec and _spec.loader:
        _m = importlib.util.module_from_spec(_spec)
        _spec.loader.exec_module(_m)
        r = _m.collect(PROJECTS, STATE_DIR, DEADLINE, write=True)
        if r.get("ok"):
            usage = r
except Exception:
    usage = None

day_w = usage["today"]["w"] if usage else None
fable7 = ((usage or {}).get("win7_models") or {}).get("fable")
total7 = usage["win7"]["w"] if usage else None

# --- B) zrodlo opcjonalne: zrzut statusline ---------------------------------
weekly = None          # float % albo None = nie wiemy
model_win = None       # (etykieta, %) — per-modelowe okno PODANE PRZEZ SERWER
weekly_why = "zrzut statusline nie istnieje (statusline chodzi tylko w terminalowym CLI)"
st = {}
try:
    with open(DUMP, "r") as f:
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

# `model_scoped` = per-modelowe okna tygodniowe z serwera. To POMIAR tego, co stala 50%
# z doktryny tylko przyblizala — raportujemy, nie bramkujemy (brak realnego odczytu z tego konta).
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
    reason = None
    if is_fable and gateable:
        if weekly is not None and weekly >= CAP:
            # Twardszy sygnal: realny procent okna z serwera.
            reason = (
                "Limit tygodniowy jest na %.0f%%, a prog dla Fable 5 to %.0f%%. Powyzej progu ta "
                "sesja zaczyna zjadac platne credits, ktore globalny CLAUDE.md zabrania wydawac "
                "bez Twojego wyraznego slowa. (Prog %.0f%% pochodzi z opisu planu Max i na seacie "
                "team_tier_1 jest NIEZWERYFIKOWANY — traktuj jako ostrzezenie, nie wyrocznie.) "
                "Potwierdz swiadomie albo zostan na Opusie." % (weekly, CAP, CAP)
            )
        elif weekly is None and day_w is not None and day_w >= DAY_WARN:
            # Proxy z transkryptow: dzien juz drogi, a Fable pali ~2x szybciej.
            extra = ""
            if fable7:
                extra = " W ostatnich 7 dniach Fable zebral juz %.0f z %.0f calosci." % (
                    fable7["w"], total7 or 0)
            reason = (
                "Dzisiejsze zuzycie liczone z transkryptow to juz %.0f (prog ostrzegawczy %.0f = p75 "
                "z 18 dni roboczych), a Fable 5 pali pule ~2x szybciej niz Opus.%s Realnego %% "
                "limitu nie znam — statusline nie chodzi w tym interfejsie, wiec to proxy z wolumenu "
                "tokenow, nie odczyt z serwera. Potwierdz swiadomie albo zostan na Opusie." % (
                    day_w, DAY_WARN, extra)
            )
    if reason:
        out({"hookSpecificOutput": {
            "hookEventName": "PreModelSwitch",
            "permissionDecision": "ask",
            "permissionDecisionReason": reason,
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
    "fable": "Fable 5 = najtrudniejszy osad, tylko na wyrazne wskazanie Piotra. Zuzywa pule ~2x szybciej — delegacja mechaniki obowiazuje tym mocniej.",
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

if day_w is not None:
    part = "" if (usage or {}).get("complete") else \
        " [skan transkryptow niepelny, %d plikow czeka — realna liczba jest wyzsza]" % (usage or {}).get("pending", 0)
    lines.append("Zuzycie z transkryptow: dzis %.0f, 7 dni %.0f (proxy z wolumenu tokenow, "
                 "nie %% limitu serwera)%s." % (day_w, total7 or 0, part))
    if fable7:
        lines.append("Z tego Fable w 7 dniach: %.0f (%d req)." % (fable7["w"], fable7["n"]))

if is_fable:
    if weekly is None:
        lines.append(
            "UWAGA: realnego %% limitu 7d brama NIE ma (%s) — brama Fable jedzie na proxy "
            "z transkryptow. Sprawdz /usage sam, zanim rozkrecisz dluga sesje na Fable." % weekly_why)
    else:
        lines.append("Limit 7d na moment przelaczenia: %.0f%% (prog Fable: %.0f%%)." % (weekly, CAP))

if model_win:
    lines.append(
        "Serwer podaje WLASNE okno tygodniowe dla tego modelu: %s na %.0f%%. To pomiar, w odroznieniu "
        "od progu %.0f%% w doktrynie (ten pochodzi z opisu planu Max, a to konto ma seat `team_tier_1`). "
        "Zglos ten odczyt, zeby dalo sie przestroic prog na pomiarze zamiast na zalozeniu."
        % (model_win[0], model_win[1], CAP))

if day_w is None and weekly is None:
    lines.append(
        "UWAGA: brama modelu jest SLEPA — ani licznik transkryptow, ani zrzut statusline nie dal "
        "odczytu. Zadne przelaczenie na Fable nie zostanie zatrzymane. Nie traktuj jej jako ochrony.")

out({"hookSpecificOutput": {
    "hookEventName": "PostModelSwitch",
    "additionalContext": " ".join(lines),
}})
PY
exit 0
