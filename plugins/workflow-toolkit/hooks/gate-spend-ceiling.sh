#!/usr/bin/env bash
# gate-spend-ceiling.sh — UserPromptSubmit. Twardy sufit wydatku, egzekwowany mechanicznie.
#
# Po co: globalny CLAUDE.md ma TWARDA regule „NIE zuzywaj platnych usage credits ponad limit
# planu; gdy limit sie wyczerpie — STOP i czekamy na odnowienie". Do dzis egzekwowalo ja
# WYLACZNIE to, ze model przeczytal CLAUDE.md w zajetej sesji. To nie jest egzekucja, to nadzieja.
# Dlatego ta brama ma kanaly, ktore NIE zaleza od tego, czy model cokolwiek przeczyta: blokade
# promptu (exit 2) + natywne powiadomienie macOS.
#
# ZRODLO DANYCH — PRZEBUDOWANE 2026-09-01 (to jest sedno tej wersji):
#   Do 1.38.4 brama czytala WYLACZNIE zrzut `~/.claude/state/rate-limits.json`, ktory pisze
#   `statusline.sh`. Zmierzone: ten skrypt NIE JEST uruchamiany w tym interfejsie w ogole —
#   heartbeat pisany czystym shellem na pierwszej linii skryptu (bez jq, bez pipe'ow, bez
#   podprocesow — nic nie moze go zablokowac) skasowany o 12:57:44 byl nieobecny o 12:59:49.
#   Hipoteza „brak jq w PATH" obalona osobno (`jq` jest w /usr/bin i dziala przy PATH=/usr/bin:/bin).
#   Czyli: zrzut nigdy nie powstawal, a brama byla slepa od pierwszego dnia — wygladajac na
#   dzialajaca. Ta sama klasa bledu co auto-archiwum kanbana pod TCC.
#
#   Od tej wersji sa DWA zrodla, o roznej randze:
#     A) TRANSKRYPTY (`~/.claude/projects/*/*.jsonl`) — ZRODLO GLOWNE, zmierzone jako realnie
#        istniejace. Kazdy request zapisuje tam `message.usage`. Liczy je `lib/usage-ledger.py`
#        inkrementalnie (offsety bajtowe; ~30 ms na ture po rozgrzaniu, zimny start 2 GB
#        rozlozony na 2 tury po deadline'ie 2,5 s).
#     B) ZRZUT STATUSLINE — kanal OPCJONALNY, twardszy gdy istnieje. W terminalowym CLI
#        statusline chodzi i daje realne % okien 5h/7d oraz stan `extra_usage` prosto z serwera.
#        To jedyne miejsce z PRAWDZIWYM procentem limitu, wiec go nie usuwamy — degradujemy
#        z „jedynego zrodla" do „mocniejszego sygnalu, gdy jest". Decyzja Piotra 2026-09-01.
#
# CZEGO TA BRAMA NIE WIE (czytaj, zanim uznasz jej liczby za limit):
#   Metryka z transkryptow to WOLUMEN TOKENOW, wazony `(input + cache_creation) + 0,1 x cache_read
#   + 5 x output` (w mln). Wspolczynniki odwzorowuja PUBLICZNE stawki CENOWE wzgledem input —
#   to ZALOZENIE przeniesione z cennika na limit, nie zmierzony przelicznik planu. Progi NIE sa
#   wiec „% limitu": sa wziete z rozkladu wlasnych 18 dni roboczych (mediana ~235, p75 268,
#   p90 347, max 401 · 25.08). Prog blokady = p90 ~350 (decyzja Piotra 2026-09-01: blokuje 2 dni
#   z 18, czyli tylko odstajace), ostrzezenie od p75 268.
#   Gdy oba zrodla sa dostepne naraz, brama dopisuje pare (waga, realne %) do
#   ~/.claude/state/usage-calibration.jsonl — to material na pozniejsze oparcie progu na pomiarze
#   zamiast na zalozeniu. Do tego czasu progi sa jawna heurystyka i tak sa opisane w komunikatach.
#
# ZACHOWANIE:
#   1. [transkrypty] Dzien >= WFT_DAY_STOP (350) → BLOKADA promptu (exit 2).
#   2. [transkrypty] Dzien w [WFT_DAY_WARN (268), STOP) → ostrzezenie CO TURE.
#   3. [zrzut] NOWY wydatek kredytow (used_credits > zaakceptowany baseline) → BLOKADA.
#      Baseline, nie „used_credits>0": jeden historyczny przelew nie moze zamurowac narzedzia
#      na caly miesiac. Blokujemy PRZYROST. Odblokowanie: `WFT_ALLOW_OVERAGE=1` albo `ack`.
#   4. [zrzut] Pierwszy run bez baseline'u → NIE blokuje, zapisuje baseline i mowi glosno raz.
#      Brama, ktora przy instalacji blokuje sesje z powodu zastanego stanu, zostanie wylaczona.
#   5. [zrzut] `is_enabled=true` bez nowego wydatku → raz na dobe: sufit po stronie konta NIE
#      jest uzbrojony.
#   6. [zrzut] 5h/7d w [90%, 99%) → ostrzezenie co ture; >= 99% przy wlaczonym extra usage →
#      BLOKADA (krawedz planu: kolejna tura jest juz platna). WFT_PLAN_WARN_PCT/WFT_PLAN_STOP_PCT.
#   7. [zrzut] Odczyt PRZETERMINOWANY, ktorego ostatnia wartosc byla >= 99% a `resets_at` jeszcze
#      nie minal → BLOKADA: procent zuzycia okna nie spada przed resetem, wiec wiemy, ze okno
#      nadal jest gorace.
#   8. ZADNE zrodlo nie dalo odczytu → fail-open, ale RAZ NA DOBE glosno „brama jest slepa".
#      Zaplanowany check bez sprawdzonego zrodla jest nieodroznialny od dzialajacego.
#
# Ack po swiadomym wydatku (re-baseline kredytow ze zrzutu):
#   bash gate-spend-ceiling.sh ack
# Podglad samego licznika z transkryptow (bez bramy):
#   bash gate-spend-ceiling.sh usage
#
# Progi (env): WFT_DAY_STOP=350 WFT_DAY_WARN=268 WFT_PLAN_STOP_PCT=99 WFT_PLAN_WARN_PCT=90
#              WFT_RATELIMIT_STALE_MIN=30 WFT_USAGE_DEADLINE_S=2.5 WFT_ALLOW_OVERAGE=1
#
# Kontrakt: exit 0 albo exit 2 (blokada). Nigdy inny — brama, ktora wywala sesje bledem, jest
# gorsza niz brak bramy.
set -uo pipefail

GSC_INPUT=""
case "${1:-}" in
  ack|usage) : ;;
  *) GSC_INPUT="$(cat 2>/dev/null || true)" ;;
esac
export GSC_INPUT
export GSC_MODE="${1:-hook}"
export GSC_STALE_MIN="${WFT_RATELIMIT_STALE_MIN:-30}"
export GSC_WARN_PCT="${WFT_PLAN_WARN_PCT:-90}"
export GSC_STOP_PCT="${WFT_PLAN_STOP_PCT:-99}"
export GSC_DAY_WARN="${WFT_DAY_WARN:-268}"
export GSC_DAY_STOP="${WFT_DAY_STOP:-350}"
export GSC_DEADLINE="${WFT_USAGE_DEADLINE_S:-2.5}"
export GSC_ALLOW="${WFT_ALLOW_OVERAGE:-}"
export GSC_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
export GSC_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

python3 - <<'PY'
import json, os, sys, time, datetime, subprocess

HOME = os.path.expanduser("~")
STATE = os.path.join(HOME, ".claude", "state")
PROJECTS = os.path.join(HOME, ".claude", "projects")
DUMP = os.path.join(STATE, "rate-limits.json")
BASE = os.path.join(STATE, "spend-ceiling-baseline.json")
CALIB = os.path.join(STATE, "usage-calibration.jsonl")
MODE = os.environ.get("GSC_MODE", "hook")


def _f(name, dflt):
    try:
        return float(os.environ.get(name) or dflt)
    except Exception:
        return float(dflt)


STALE_S = _f("GSC_STALE_MIN", 30) * 60
WARN = _f("GSC_WARN_PCT", 90)
STOP = _f("GSC_STOP_PCT", 99)
DAY_WARN = _f("GSC_DAY_WARN", 268)
DAY_STOP = _f("GSC_DAY_STOP", 350)
DEADLINE = _f("GSC_DEADLINE", 2.5)
ALLOW = os.environ.get("GSC_ALLOW", "").strip() not in ("", "0", "false", "no")
SELF = os.environ.get("GSC_SELF") or "gate-spend-ceiling.sh"

# Licznik transkryptow ladujemy PO SCIEZCE (nazwa pliku ma myslnik, wiec zwykly import odpada).
# Ladujemy w procesie, nie subprocessem — brama chodzi w kazdej turze i fork Pythona kosztowalby
# wiecej niz caly odczyt inkrementalny (~30 ms).
ledger = None
try:
    import importlib.util
    _lp = os.path.join(os.environ.get("GSC_LIB", ""), "usage-ledger.py")
    _spec = importlib.util.spec_from_file_location("usage_ledger", _lp)
    if _spec and _spec.loader:
        ledger = importlib.util.module_from_spec(_spec)
        _spec.loader.exec_module(ledger)
except Exception:
    ledger = None


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
    """Kanal POZA petla modelu — nie zalezy od tego, czy Claude przeczyta wstrzykniety tekst.
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
    today = datetime.date.today().isoformat()
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


def transcripts():
    """Odczyt z licznika transkryptow. None gdy modul niedostepny albo policzyl nic."""
    if ledger is None:
        return None
    try:
        return ledger.collect(PROJECTS, STATE, DEADLINE, write=True)
    except Exception:
        return None


# --- tryb `usage`: podglad licznika, bez bramy -------------------------------
if MODE == "usage":
    u = transcripts()
    if not u or not u.get("ok"):
        print("Licznik transkryptow nie dziala: %s"
              % ((u or {}).get("reason") or "modul lib/usage-ledger.py niedostepny"))
        sys.exit(0)
    print("dzis %.1f (%d req) · 7d %.1f (%d req) · progi: warn %.0f / stop %.0f%s"
          % (u["today"]["w"], u["today"]["n"], u["win7"]["w"], u["win7"]["n"],
             DAY_WARN, DAY_STOP, "" if u.get("complete") else
             "  [skan niepelny: %d plikow czeka]" % u.get("pending", 0)))
    for k, label in (("today_models", "dzis"), ("win7_models", "7d  ")):
        parts = ", ".join("%s %.1f" % (f, v["w"]) for f, v in (u.get(k) or {}).items())
        if parts:
            print("  %s wg modelu: %s" % (label, parts))
    sys.exit(0)

# --- tryb `ack`: re-baseline po swiadomym wydatku ---------------------------
if MODE == "ack":
    used, _ = credits_of(read_json(DUMP))
    if used is None:
        print("Brak odczytu extra_usage w %s — nie ma czego zaakceptowac "
              "(zrzut pisze statusline, ktory dziala tylko w terminalowym CLI). "
              "Blokada dzienna z transkryptow ma wlasny zawor: WFT_ALLOW_OVERAGE=1." % DUMP)
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
blocked = False


def block(text):
    """Jedyna sciezka blokady. WFT_ALLOW_OVERAGE degraduje ja do glosnego ostrzezenia."""
    global blocked
    notify(text[:180])
    if ALLOW:
        msgs.append(text + " WFT_ALLOW_OVERAGE=1 — przepuszczone swiadomie.")
        return
    sys.stderr.write(text + "\n")
    blocked = True


def finish():
    if msgs:
        print("\n".join(msgs))
    sys.exit(2 if blocked else 0)


# ============================================================================
# A) ZRODLO GLOWNE — transkrypty
# ============================================================================
usage = transcripts()
have_transcripts = bool(usage and usage.get("ok") and usage.get("today"))

if have_transcripts:
    day = usage["today"]["w"]
    req = usage["today"]["n"]
    partial = "" if usage.get("complete") else (
        " (skan jeszcze niepelny — %d plikow czeka na kolejna ture, wiec realna liczba jest "
        "WYZSZA niz ta)" % usage.get("pending", 0))
    if day >= DAY_STOP:
        block("[sufit-wydatku] STOP. Dzisiejsze zuzycie z transkryptow: %.0f (prog blokady %.0f, "
              "p90 z 18 dni roboczych) przy %d requestach%s. Konto ma extra usage wlaczone "
              "org-wide i „unlimited usage credits” — zaden backstop po stronie serwera nie "
              "istnieje, wiec ta brama jest jedynym hamulcem. Regula: STOP i czekamy na "
              "odnowienie. Swiadomy wyjatek na te sesje: `WFT_ALLOW_OVERAGE=1`. Podglad liczb: "
              "`bash %s usage`." % (day, DAY_STOP, req, partial, SELF))
    elif day >= DAY_WARN:
        msgs.append(
            "[sufit-wydatku] Dzisiejsze zuzycie z transkryptow: %.0f (ostrzezenie od %.0f = p75, "
            "blokada od %.0f = p90) przy %d requestach%s. Domykaj biezacy krok i checkpointuj; "
            "NIE startuj dlugich runow. Mechanike deleguj do subagentow Haiku/Sonnet — to "
            "najwieksza dzwignia. Ten komunikat powtorzy sie kazda ture powyzej progu — swiadome."
            % (day, DAY_WARN, DAY_STOP, req, partial))

# ============================================================================
# B) ZRODLO OPCJONALNE — zrzut statusline (twardszy sygnal, gdy istnieje)
# ============================================================================
dump = read_json(DUMP)
fresh = False
if dump:
    try:
        fresh = (time.time() - float(dump.get("ts") or 0)) <= STALE_S
    except Exception:
        fresh = False

if not fresh:
    # Przeterminowany odczyt NIE jest automatycznie fail-open. Procent zuzycia okna nie spada
    # sam — spada dopiero przy resecie. Jesli ostatni znany odczyt byl na progu STOP, a `resets_at`
    # tego okna jeszcze nie minal, to WIEMY, ze okno nadal jest gorace.
    if dump:
        hot = [(n, v, r) for n, v, r in windows(dump)
               if v >= STOP and r is not None and time.time() < r]
        if hot:
            n, v, r = hot[0]
            left = int((r - time.time()) // 60)
            block("[sufit-wydatku] STOP. Ostatni znany odczyt: okno %s na %.0f%% (prog %.0f%%), "
                  "a jego reset dopiero za ~%d min. Odczyt jest przeterminowany, ale procent "
                  "zuzycia nie spada przed resetem — wiec okno NADAL jest gorace i kolejna tura "
                  "poleci w platne kredyty. Zaczekaj na reset albo `WFT_ALLOW_OVERAGE=1`."
                  % (n, v, STOP, left))

    if not have_transcripts and once_per_day("blind"):
        why = (usage or {}).get("reason") or "licznik transkryptow nie zwrocil danych"
        msgs.append(
            "[sufit-wydatku] BRAMA JEST SLEPA i przepuszcza na slepo. Zrodlo glowne "
            "(transkrypty ~/.claude/projects) nie dalo odczytu: %s. Zrodlo zapasowe (zrzut "
            "statusline) tez nie: %s. Nie traktuj tej bramy jako ochrony, dopoki to sie nie "
            "zmieni — sprawdz /usage sam, zanim rozkrecisz dluga sesje."
            % (why, "brak pliku %s" % DUMP if not dump else "odczyt przeterminowany"))
    finish()

# --- zrzut jest swiezy: pelna semantyka kredytow i okien --------------------
used, enabled = credits_of(dump)
base = read_json(BASE)

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
            block("[sufit-wydatku] STOP. Ta sesja przelala sie w PLATNE usage credits: "
                  "%.2f nowego wydatku ponad zaakceptowane %.2f (razem %.2f w tym miesiacu). "
                  "Globalny CLAUDE.md: „gdy limit planu sie wyczerpie — STOP i czekamy na "
                  "odnowienie, NIGDY nie przelewaj w paid overage.” Dalej: (1) zaczekaj na reset, "
                  "albo (2) jesli ten wydatek jest swiadomy — `bash %s ack` (re-baseline), albo "
                  "(3) jednorazowo `WFT_ALLOW_OVERAGE=1` dla tej sesji."
                  % (delta, acked, used, SELF))

    if enabled and once_per_day("enabled"):
        msgs.append(
            "[sufit-wydatku] Konto ma WLACZONE extra usage (usage credits) — to znaczy, ze po "
            "wyczerpaniu limitu planu sesja przeleje sie w platne kredyty sama, bez pytania. "
            "Jedyny sufit twardy w sensie „niemozliwe” to wylaczenie extra usage w billingu "
            "claude.ai; hook potrafi tylko zablokowac PO fakcie pierwszego przyrostu. "
            "Powiedz to Piotrowi wprost, jesli jeszcze nie wie.")

wins = windows(dump)

# Zrzut moze byc SWIEZY i jednoczesnie pusty: Claude Code podaje `rate_limits: null`, gdy konto nie
# ma czytelnych okien limitu (brak profile scope w tokenie OAuth, API key/Bedrock/Vertex, albo
# `no_limits_configured` — org z nielimitowanymi kredytami). Wtedy zrzut nie wnosi nic ponad
# transkrypty — i tylko wtedy warto o tym powiedziec, bo transkrypty juz chronia.
if used is None and not wins and not have_transcripts and once_per_day("nodata"):
    msgs.append(
        "[sufit-wydatku] BRAMA JEST SLEPA. Zrzut limitu jest swiezy, ale wszystkie pola puste "
        "(`rate_limits: null` z API), a licznik transkryptow tez nie dal odczytu. Zaden prog sie "
        "nie odpali — brama nie chroni w tej sesji.")

# Prog STOP = krawedz planu. Blokujemy TYLKO gdy konto w ogole moze przelac w kredyty —
# przy `is_enabled=false` wyczerpanie limitu i tak konczy sie odmowa serwera.
if enabled is not False:
    over = [(n, v, r) for n, v, r in wins if v >= STOP]
    if over:
        n, v, r = over[0]
        when = " Reset za ~%d min." % int(max(0, r - time.time()) // 60) if r is not None else ""
        block("[sufit-wydatku] STOP. Okno %s na %.0f%% (prog %.0f%%) — to krawedz planu, "
              "a konto ma wlaczone extra usage, wiec kolejna tura poleci juz w PLATNE kredyty. "
              "Regula: STOP i czekamy na odnowienie.%s Swiadomy wyjatek: `WFT_ALLOW_OVERAGE=1`."
              % (n, v, STOP, when))

hot = [(n, v) for n, v, _ in wins if WARN <= v < STOP]
if hot:
    where = ", ".join("%s %.0f%%" % (n, v) for n, v in hot)
    msgs.append(
        "[sufit-wydatku] Blisko sufitu planu (%s, prog %.0f%%). Domykaj biezacy krok i "
        "checkpointuj; NIE startuj subagentow ani dlugich runow. Gdy Claude Code zaproponuje "
        "wlaczenie usage credits (/usage-credits albo dialog przy limicie) — NIE akceptuj i nie "
        "proponuj tego Piotrowi: regula mowi STOP i czekamy na reset. "
        "Ten komunikat powtorzy sie kazda ture powyzej progu — to swiadome." % (where, WARN))

# --- KALIBRACJA: para (waga z transkryptow, realny % z serwera) --------------
# Jedyny moment, w ktorym obie strony rownania sa widoczne naraz. Bez tego progi na zawsze
# zostana heurystyka z rozkladu wlasnych dni. Raz na godzine, zeby plik nie puchl.
if have_transcripts and wins:
    try:
        last = 0.0
        try:
            with open(CALIB, "rb") as f:
                f.seek(max(0, os.path.getsize(CALIB) - 4096))
                for ln in f.read().decode("utf-8", "replace").splitlines():
                    if ln.strip():
                        last = float(json.loads(ln).get("ts") or 0)
        except Exception:
            pass
        if time.time() - last > 3600:
            os.makedirs(STATE, exist_ok=True)
            rec = {"ts": int(time.time()),
                   "day_w": usage["today"]["w"], "day_n": usage["today"]["n"],
                   "win7_w": usage["win7"]["w"], "win7_n": usage["win7"]["n"],
                   "raw7d": usage.get("raw"),
                   "server": {n: v for n, v, _ in wins}}
            with open(CALIB, "a") as f:
                f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    except Exception:
        pass

finish()
PY
rc=$?
[[ "$rc" == "2" ]] && exit 2
exit 0
