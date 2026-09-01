#!/usr/bin/env bash
# gate-spend-ceiling.sh — UserPromptSubmit. Twardy sufit wydatku, egzekwowany mechanicznie.
#
# Po co: globalny CLAUDE.md ma TWARDA regule „NIE zuzywaj platnych usage credits ponad limit
# planu; gdy limit sie wyczerpie — STOP i czekamy na odnowienie". Do dzis egzekwowalo ja
# WYLACZNIE to, ze model przeczytal CLAUDE.md w zajetej sesji. To nie jest egzekucja, to nadzieja
# — ta sama klasa co v1/v2 `context-watch.sh` (dwie walidacje z rzedu NIE POTWIERDZONE: sam
# wstrzykniety tekst nie zmienil zachowania). Dlatego ta brama ma kanal, ktory NIE zalezy od
# tego, czy model cokolwiek przeczyta: blokade promptu (exit 2) + natywne powiadomienie macOS.
#
# CO JEST FAKTEM, A CO BYLO ZLA HIPOTEZA (zmierzone w binarce 2.1.252, 2026-09-01):
#   - `CLAUDE_CODE_RETRY_WATCHDOG` NIE jest hamulcem wydatku. To „persistent retry mode":
#     zamiast bledu, klient CZEKA na reset limitu. Zmiana z 2.1.239 („fails immediately on
#     organization spend-limit and out-of-credits") dotyczy kont org/API-billed, nie
#     indywidualnego Maxa. Karta kanban zakladala odwrotnie — poprawione.
#   - Prawdziwy sygnal wydatku to `rate_limits.extra_usage` z payloadu statusline:
#     `{is_enabled, monthly_limit, used_credits, utilization, currency}`.
#     `is_enabled=true` = konto MOZE przelac w platne kredyty; `used_credits>0` = juz przelalo.
#   - Jedyny sufit TWARDY w sensie „niemozliwe, nie tylko odradzane" jest po stronie konta:
#     extra usage / usage credits wylaczone w billingu claude.ai. Tego hook nie zrobi — to
#     akcja Piotra. Hook pilnuje wszystkiego ponizej tej linii.
#
# Kanal danych: hook nie dostaje `rate_limits` w payloadzie — czyta zrzut, ktory pisze
# `statusline.sh` (to samo repo) do ~/.claude/state/rate-limits.json. Sprzezenie jawne,
# dokladnie jak w `gate-model-switch.sh`.
#
# ZACHOWANIE:
#   1. NOWY wydatek kredytow (used_credits > zaakceptowany baseline) → BLOKADA promptu (exit 2).
#      Baseline, nie „used_credits>0": jeden historyczny przelew nie moze zamurowac narzedzia
#      na caly miesiac. Blokujemy PRZYROST — czyli dokladnie to, czego regula zabrania.
#      Odblokowanie: `WFT_ALLOW_OVERAGE=1` (swiadoma zgoda na te sesje) albo `ack` (patrz nizej).
#   2. Pierwszy run bez baseline'u → NIE blokuje, zapisuje baseline i mowi glosno raz.
#      Brama, ktora przy instalacji blokuje sesje z powodu zastanego stanu, zostanie wylaczona.
#   3. `is_enabled=true` bez nowego wydatku → raz na dobe: sufit po stronie konta NIE jest uzbrojony.
#   4. 5h/7d w [90%, 99%) → ostrzezenie co ture: domykaj, NIE wlaczaj kredytow.
#   5. 5h/7d >= 99% przy wlaczonym extra usage → BLOKADA. To krawedz planu: kolejna tura jest
#      juz platna. Blokada PRZED wydatkiem jest jedyna, ktora cokolwiek oszczedza — pkt 1 lapie
#      dopiero po fakcie. Progi: WFT_PLAN_WARN_PCT / WFT_PLAN_STOP_PCT.
#   6. Brak odczytu → fail-open, ale raz na dobe glosno. Odczyt PRZETERMINOWANY, ktorego ostatnia
#      wartosc byla >= 99% a `resets_at` jeszcze nie minal → BLOKADA: procent zuzycia okna nie
#      spada przed resetem, wiec wiemy, ze okno nadal jest gorace. Zaplanowany check bez
#      sprawdzonego zrodla jest nieodroznialny od dzialajacego (kosztowalo juz auto-archiwum kanbana).
#
# Ack po swiadomym wydatku (re-baseline, zeby brama przestala blokowac):
#   bash gate-spend-ceiling.sh ack
#
# Kontrakt: exit 0 albo exit 2 (blokada). Nigdy inny — brama, ktora wywala sesje bledem, jest
# gorsza niz brak bramy.
set -uo pipefail

GSC_INPUT=""
if [[ "${1:-}" != "ack" ]]; then GSC_INPUT="$(cat 2>/dev/null || true)"; fi
export GSC_INPUT
export GSC_MODE="${1:-hook}"
export GSC_STALE_MIN="${WFT_RATELIMIT_STALE_MIN:-30}"
export GSC_WARN_PCT="${WFT_PLAN_WARN_PCT:-90}"
export GSC_STOP_PCT="${WFT_PLAN_STOP_PCT:-99}"
export GSC_ALLOW="${WFT_ALLOW_OVERAGE:-}"
export GSC_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

python3 - <<'PY'
import json, os, sys, time, datetime, subprocess

STATE = os.path.expanduser("~/.claude/state")
DUMP = os.path.join(STATE, "rate-limits.json")
BASE = os.path.join(STATE, "spend-ceiling-baseline.json")
MODE = os.environ.get("GSC_MODE", "hook")
STALE_S = float(os.environ.get("GSC_STALE_MIN", "30") or 30) * 60
WARN = float(os.environ.get("GSC_WARN_PCT", "90") or 90)
STOP = float(os.environ.get("GSC_STOP_PCT", "99") or 99)
ALLOW = os.environ.get("GSC_ALLOW", "").strip() not in ("", "0", "false", "no")
SELF = os.environ.get("GSC_SELF") or "gate-spend-ceiling.sh"

def read_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return None

def write_json(path, obj):
    try:
        os.makedirs(STATE, exist_ok=True)
        tmp = path + ".tmp"
        with open(tmp, "w") as f:
            json.dump(obj, f)
        os.replace(tmp, path)
    except Exception:
        pass

def month_now():
    return datetime.date.today().strftime("%Y-%m")

def notify(text):
    """Kanal POZA petla modelu — nie zalezy od tego, czy Claude przeczyta wstrzyniety tekst.
    No-op (cicho) poza macOS z GUI."""
    try:
        subprocess.run(
            ["osascript", "-e",
             'display notification "%s" with title "Claude Code — sufit wydatku" sound name "Basso"'
             % text.replace('"', "'")],
            timeout=3, capture_output=True)
    except Exception:
        pass

def once_per_day(tag):
    """True gdy dla tego tagu nie bylo jeszcze komunikatu dzisiaj."""
    p = os.path.join(STATE, "spend-ceiling-%s" % tag)
    today = month_now() + "-" + datetime.date.today().strftime("%d")
    try:
        if open(p).read().strip() == today:
            return False
    except Exception:
        pass
    try:
        os.makedirs(STATE, exist_ok=True)
        open(p, "w").write(today)
    except Exception:
        pass
    return True

def parse_ts(v):
    """ISO 8601 → epoch. Tolerancyjnie: z 'Z', z offsetem, z ulamkiem sekundy albo juz jako liczba."""
    if v is None:
        return None
    if isinstance(v, (int, float)):
        return float(v)
    t = str(v).strip().replace("Z", "+00:00")
    try:
        return datetime.datetime.fromisoformat(t).timestamp()
    except Exception:
        pass
    for fmt in ("%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M:%S.%f"):
        try:
            return datetime.datetime.strptime(str(v).strip().rstrip("Z"), fmt)\
                .replace(tzinfo=datetime.timezone.utc).timestamp()
        except Exception:
            continue
    return None


def windows(dump):
    """[(etykieta, procent, epoch_resetu|None)] dla okien, ktore serwer podal."""
    out = []
    for label, kp, kr in (("5h", "five_hour_pct", "five_hour_resets_at"),
                          ("7d", "seven_day_pct", "seven_day_resets_at")):
        try:
            v = float(dump.get(kp))
        except Exception:
            continue
        out.append((label, v, parse_ts(dump.get(kr))))
    return out


def credits_of(dump):
    xu = (dump or {}).get("extra_usage")
    if not isinstance(xu, dict):
        return None, None
    used = xu.get("used_credits")
    try:
        used = float(used) if used is not None else None
    except Exception:
        used = None
    return used, bool(xu.get("is_enabled"))

# --- tryb `ack`: re-baseline po swiadomym wydatku ---------------------------
if MODE == "ack":
    dump = read_json(DUMP)
    used, _ = credits_of(dump)
    if used is None:
        print("Brak odczytu extra_usage w %s — nie ma czego zaakceptowac "
              "(statusline musi sie odswiezyc w interaktywnej sesji)." % DUMP)
        sys.exit(0)
    write_json(BASE, {"acked_credits": used, "month": month_now(), "acked_at": int(time.time())})
    print("Zaakceptowano stan kredytow: %.2f (miesiac %s). Brama zablokuje dopiero KOLEJNY przyrost."
          % (used, month_now()))
    sys.exit(0)

try:
    json.loads(os.environ.get("GSC_INPUT", ""))
except Exception:
    sys.exit(0)

msgs = []
dump = read_json(DUMP)
fresh = False
if dump:
    try:
        fresh = (time.time() - float(dump.get("ts") or 0)) <= STALE_S
    except Exception:
        fresh = False

def block(text):
    """Jedyna sciezka blokady. WFT_ALLOW_OVERAGE degraduje ja do glosnego ostrzezenia."""
    notify(text[:180])
    if ALLOW:
        msgs.append(text + " WFT_ALLOW_OVERAGE=1 — przepuszczone swiadomie.")
        return False
    sys.stderr.write(text + "\n")
    return True


if not fresh:
    # Przeterminowany odczyt NIE jest automatycznie fail-open. Procent zuzycia okna nie spada
    # sam — spada dopiero przy resecie. Jesli ostatni znany odczyt byl na progu STOP, a `resets_at`
    # tego okna jeszcze nie minal, to WIEMY, ze okno nadal jest gorace: przepuszczenie promptu
    # byloby wydaniem platnych kredytow z pelna wiedza, ze tak sie stanie. Blokujemy.
    if dump:
        hot = [(n, v, r) for n, v, r in windows(dump)
               if v >= STOP and r is not None and time.time() < r]
        if hot:
            n, v, r = hot[0]
            left = int((r - time.time()) // 60)
            if block("[sufit-wydatku] STOP. Ostatni znany odczyt: okno %s na %.0f%% (prog %.0f%%), "
                     "a jego reset dopiero za ~%d min. Odczyt jest przeterminowany, ale procent "
                     "zuzycia nie spada przed resetem — wiec okno NADAL jest gorace i kolejna tura "
                     "poleci w platne kredyty. Zaczekaj na reset albo `WFT_ALLOW_OVERAGE=1`."
                     % (n, v, STOP, left)):
                sys.exit(2)
    # Fail-open, ale nie po cichu — inaczej martwy check wyglada jak dzialajacy.
    if once_per_day("stale"):
        why = "brak pliku %s" % DUMP if not dump else "odczyt przeterminowany"
        msgs.append(
            "[sufit-wydatku] Brama nie ma swiezych danych o limicie (%s) — przepuszcza na slepo. "
            "Zrzut pisze statusline.sh, wiec w sesjach headless/scheduled ta brama nie chroni. "
            "Sprawdz /usage sam, zanim rozkrecisz dluga sesje." % why)
    if msgs:
        print("\n".join(msgs))
    sys.exit(0)

used, enabled = credits_of(dump)
base = read_json(BASE)

# --- 1) nowy wydatek platnych kredytow → BLOKADA ----------------------------
if used is not None:
    if not isinstance(base, dict) or "acked_credits" not in base:
        # Pierwszy run: zapisz baseline, nie blokuj zastanego stanu.
        write_json(BASE, {"acked_credits": used, "month": month_now(), "acked_at": int(time.time())})
        if used > 0:
            msgs.append(
                "[sufit-wydatku] Brama uzbrojona. Zastany stan platnych kredytow w tym miesiacu: "
                "%.2f — przyjety jako baseline, NIE blokuje. Kazdy KOLEJNY przyrost zablokuje prompt."
                % used)
    else:
        acked = float(base.get("acked_credits") or 0)
        if base.get("month") != month_now() or used < acked - 1e-9:
            # Nowy miesiac albo licznik zresetowany po stronie serwera → re-baseline po cichu.
            write_json(BASE, {"acked_credits": used, "month": month_now(),
                              "acked_at": int(time.time())})
        elif used > acked + 1e-9:
            delta = used - acked
            head = ("[sufit-wydatku] STOP. Ta sesja przelala sie w PLATNE usage credits: "
                    "%.2f nowego wydatku ponad zaakceptowane %.2f (razem %.2f w tym miesiacu). "
                    "Globalny CLAUDE.md: „gdy limit planu sie wyczerpie — STOP i czekamy na "
                    "odnowienie, NIGDY nie przelewaj w paid overage.”" % (delta, acked, used))
            tail = ("Dalej: (1) zaczekaj na reset limitu planu, albo (2) jesli ten wydatek jest "
                    "swiadomy — `bash %s ack` " % SELF +
                    "(re-baseline), albo (3) jednorazowo `WFT_ALLOW_OVERAGE=1` dla tej sesji. "
                    "Twardy sufit po stronie konta uzbroisz wylaczajac extra usage w billingu claude.ai.")
            if block(head + " " + tail):
                sys.exit(2)

    # --- 3) sufit po stronie konta nieuzbrojony ------------------------------
    if enabled and once_per_day("enabled"):
        msgs.append(
            "[sufit-wydatku] Konto ma WLACZONE extra usage (usage credits) — to znaczy, ze po "
            "wyczerpaniu limitu planu sesja przeleje sie w platne kredyty sama, bez pytania. "
            "Jedyny sufit twardy w sensie „niemozliwe” to wylaczenie extra usage w billingu "
            "claude.ai; hook potrafi tylko zablokowac PO fakcie pierwszego przyrostu. "
            "Powiedz to Piotrowi wprost, jesli jeszcze nie wie.")

# --- 4) prog limitu planu ----------------------------------------------------
wins = windows(dump)

# Prog STOP = krawedz planu. Blokujemy TYLKO gdy konto w ogole moze przelac w kredyty —
# przy `is_enabled=false` wyczerpanie limitu i tak konczy sie odmowa serwera, wiec
# wyprzedzajaca blokada bylaby czystym halasem.
if enabled is not False:
    over = [(n, v, r) for n, v, r in wins if v >= STOP]
    if over:
        n, v, r = over[0]
        when = ""
        if r is not None:
            when = " Reset za ~%d min." % int(max(0, r - time.time()) // 60)
        if block("[sufit-wydatku] STOP. Okno %s na %.0f%% (prog %.0f%%) — to krawedz planu, "
                 "a konto ma wlaczone extra usage, wiec kolejna tura poleci juz w PLATNE kredyty. "
                 "Regula: STOP i czekamy na odnowienie.%s Swiadomy wyjatek: `WFT_ALLOW_OVERAGE=1`."
                 % (n, v, STOP, when)):
            sys.exit(2)

hot = [(n, v) for n, v, _ in wins if v >= WARN and v < STOP]
if hot:
    where = ", ".join("%s %.0f%%" % (n, v) for n, v in hot)
    msgs.append(
        "[sufit-wydatku] Blisko sufitu planu (%s, prog %.0f%%). Domykaj biezacy krok i "
        "checkpointuj; NIE startuj subagentow ani dlugich runow. Gdy Claude Code zaproponuje "
        "wlaczenie usage credits (/usage-credits albo dialog przy limicie) — NIE akceptuj i nie "
        "proponuj tego Piotrowi: regula mowi STOP i czekamy na reset. "
        "Ten komunikat powtorzy sie kazda ture powyzej progu — to swiadome." % (where, WARN))

if msgs:
    print("\n".join(msgs))
sys.exit(0)
PY
rc=$?
[[ "$rc" == "2" ]] && exit 2
exit 0
