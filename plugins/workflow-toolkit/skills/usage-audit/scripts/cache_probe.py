#!/usr/bin/env python3
"""Pomiar realnego zachowania prompt cache na transkryptach ~/.claude/projects.

Po co: regula "pracuj seriami" z globalnego CLAUDE.md mowila "dlugie luki = re-czytanie
bez cache" bez zadnego progu. Ten skrypt zamienia domysl w liczbe — mierzy, przy jakiej
luce miedzy requestami cache faktycznie pada i ile to kosztuje tokenow.

Zrodlo prawdy: pole `usage` w rekordach `assistant`, ktore CLI zapisuje w transkryptach.
Dziala niezaleznie od wersji CLI (pole `prompt_cache` w status line wymaga >= 2.1.251).

Definicja rebuildu: cache_read biezacego requestu < 50% tego, co bylo w cache ture wczesniej
(read + creation). Pary z kontekstem < 5k tokenow sa pomijane — nie ma tam czego trzymac.

Uzycie:
    cache_probe.py [YYYY-MM-DD]        # domyslnie ostatnie 30 dni

Wyjscie: krzywa rebuildu wg dlugosci luki + atrybucja kosztu + faktycznie zamawiany TTL,
osobno dla glownej sesji i dla subagentow (sidechain), oraz PRZYCZYNY przebudowy.

Przyczyny (H18): sama krzywa luk tlumaczy tylko przebudowy po przerwie. Przebudowy WEWNATRZ
serii (luka < 5 min) to osobny, wiekszy worek — i zeby go rozbic, trzeba patrzec nie na czas,
tylko na to, CO ZMIENILO SIE W PREFIKSIE miedzy dwoma requestami. Transkrypt zapisuje to
wprost: rekordy `attachment` o typach `*_delta` sa zdarzeniem "zestaw narzedzi/instrukcji
sie zmienil", a pola `version`/`effort`/`permissionMode` zmieniaja poczatek promptu.
"""
import json, os, sys, glob
from datetime import datetime, timedelta, timezone
from collections import defaultdict

if len(sys.argv) > 1:
    since = datetime.fromisoformat(sys.argv[1] + "T00:00:00+00:00")
else:
    since = datetime.now(timezone.utc) - timedelta(days=30)

BUCKETS = [(0, 1), (1, 5), (5, 15), (15, 30), (30, 60), (60, 120), (120, 10**9)]
label = lambda lo, hi: f">{lo}m" if hi >= 10**9 else f"{lo}-{hi}m"
MIN_CTX = 5000          # ponizej tego kontekst jest za maly, zeby rebuild cokolwiek znaczyl
REBUILD_AT = 0.5        # cache_read ponizej tej czesci poprzedniego kontekstu = przebudowa

# Atrybucja przyczyn — KOLEJNOSC JEST POLITYKA, nie szczegolem. Zdarzenie dostaje PIERWSZA
# pasujaca przyczyne, wiec udzialy sumuja sie do 100% i nic nie jest liczone dwa razy.
# Wyzej stoi to, co zmienia prefiks w sposob pewny (podmiana CLI, inny model, inny zestaw
# narzedzi); nizej to, co jest tylko poszlaka.
CAUSES = [
    ("podmiana CLI",        "zmienil sie `version` — inny system prompt i inny zestaw narzedzi"),
    ("zmiana modelu",       "inny `model` niz w poprzednim requescie"),
    ("zestaw narzedzi",     "attachment `deferred_tools_delta` / `mcp_instructions_delta` / "
                            "`agent_listing_delta` / `skill_listing` — lista narzedzi siedzi na "
                            "poczatku prefiksu, wiec kazda jej zmiana uniewaznia cache"),
    ("uprawnienia/tryb",    "zmiana `permissionMode` albo attachment `auto_mode` / `command_permissions`"),
    ("zmiana effortu",      "inny `effort` niz w poprzednim requescie"),
    ("zmiana katalogu",     "inny `cwd` albo `gitBranch`"),
    ("nierozpoznane",       "nic obserwowalnego sie nie zmienilo — kandydat na eviction po stronie dostawcy"),
]
TOOLSET_ATTACH = {"deferred_tools_delta", "mcp_instructions_delta",
                  "agent_listing_delta", "skill_listing"}
PERM_ATTACH = {"auto_mode", "command_permissions"}


def collect(since):
    """Zbiera unikalne requesty per (sesja, sidechain). Dedup po requestId — iteracje
    w obrebie jednego requestu powtarzaja to samo `usage`.

    Zbiera TEZ sygnaly zmiany prefiksu (rekordy `attachment` i `permissionMode` z rekordow
    `user`), przeplecione z requestami po czasie — bez nich da sie powiedziec TYLKO, ze cache
    padl, a nie dlaczego."""
    sessions, seen = defaultdict(list), set()
    signals = defaultdict(list)
    ttl = {False: {"1h": 0, "5m": 0}, True: {"1h": 0, "5m": 0}}
    for fp in glob.glob(os.path.expanduser("~/.claude/projects/**/*.jsonl"), recursive=True):
        try:
            if datetime.fromtimestamp(os.path.getmtime(fp), timezone.utc) < since:
                continue
            fh = open(fp, errors="replace")
        except OSError:
            continue
        with fh:
            for line in fh:
                try:
                    d = json.loads(line)
                except Exception:
                    continue
                typ = d.get("type")
                if typ not in ("assistant", "attachment", "user"):
                    continue
                t = d.get("timestamp")
                if not t:
                    continue
                try:
                    tt = datetime.fromisoformat(t.replace("Z", "+00:00"))
                except Exception:
                    continue
                if tt < since:
                    continue
                key = (d.get("sessionId"), bool(d.get("isSidechain")))

                if typ == "attachment":
                    a = d.get("attachment")
                    kind = a.get("type") if isinstance(a, dict) else None
                    if kind:
                        signals[key].append({"t": tt, "attach": kind})
                    continue
                if typ == "user":
                    pm = d.get("permissionMode")
                    if pm:
                        signals[key].append({"t": tt, "perm": pm})
                    # granica tury: prawdziwy prompt czlowieka, nie wynik narzedzia
                    if d.get("promptSource") or (d.get("origin") and not d.get("sourceToolUseID")):
                        signals[key].append({"t": tt, "boundary": True})
                    continue

                u = (d.get("message") or {}).get("usage")
                rid = d.get("requestId")
                if not (u and rid) or rid in seen:
                    continue
                seen.add(rid)
                side = key[1]
                cc = u.get("cache_creation") or {}
                ttl[side]["1h"] += cc.get("ephemeral_1h_input_tokens", 0) or 0
                ttl[side]["5m"] += cc.get("ephemeral_5m_input_tokens", 0) or 0
                sessions[key].append({
                    "t": tt,
                    "read": u.get("cache_read_input_tokens", 0) or 0,
                    "create": u.get("cache_creation_input_tokens", 0) or 0,
                    "version": d.get("version"),
                    "effort": d.get("effort"),
                    "cwd": d.get("cwd"),
                    "branch": d.get("gitBranch"),
                    "model": (d.get("message") or {}).get("model"),
                })
    return sessions, signals, ttl, len(seen)


def attribute(prev, cur, sigs):
    """Zwraca nazwe PIERWSZEJ pasujacej przyczyny z listy CAUSES.

    `sigs` to sygnaly zapisane miedzy poprzednim a biezacym requestem. Kolejnosc sprawdzania
    jest ta sama co w CAUSES i jest czescia polityki — patrz komentarz przy tabeli."""
    kinds = {x.get("attach") for x in sigs if x.get("attach")}
    perms = {x.get("perm") for x in sigs if x.get("perm")}
    if prev.get("version") and cur.get("version") and prev["version"] != cur["version"]:
        return "podmiana CLI"
    if prev.get("model") and cur.get("model") and prev["model"] != cur["model"]:
        return "zmiana modelu"
    if kinds & TOOLSET_ATTACH:
        return "zestaw narzedzi"
    if len(perms) > 1 or (kinds & PERM_ATTACH):
        return "uprawnienia/tryb"
    if prev.get("effort") and cur.get("effort") and prev["effort"] != cur["effort"]:
        return "zmiana effortu"
    if prev.get("cwd") != cur.get("cwd") or prev.get("branch") != cur.get("branch"):
        return "zmiana katalogu"
    return "nierozpoznane"


def boundary_report(sessions, signals, side, title):
    """Gdzie w ogole wypadaja przebudowy: na granicy tury czy w srodku petli narzedziowej?

    To rozstrzyga najwazniejsze pytanie z H18 — czy reszta worka to eviction po stronie
    dostawcy (uderzalby ROWNOMIERNIE, bo nie wie nic o naszych turach), czy cos naszego,
    co dzieje sie deterministycznie na styku tur."""
    cell = defaultdict(lambda: {"n": 0, "reb": 0, "tok": 0})
    for key, evs in sessions.items():
        if key[1] != side:
            continue
        evs.sort(key=lambda e: e["t"])
        sigs = sorted(signals.get(key, []), key=lambda x: x["t"])
        j = 0
        for i in range(1, len(evs)):
            prev, cur = evs[i - 1], evs[i]
            ctx = prev["read"] + prev["create"]
            if ctx < MIN_CTX:
                continue
            if (cur["t"] - prev["t"]).total_seconds() / 60.0 >= 5:
                continue
            while j < len(sigs) and sigs[j]["t"] < prev["t"]:
                j += 1
            k, win = j, []
            while k < len(sigs) and sigs[k]["t"] <= cur["t"]:
                win.append(sigs[k]); k += 1
            if attribute(prev, cur, win) != "nierozpoznane":
                continue                      # juz wytlumaczone twarda przyczyna
            c = cell[any(x.get("boundary") for x in win)]
            c["n"] += 1
            if cur["read"] < REBUILD_AT * ctx:
                c["reb"] += 1
                c["tok"] += cur["create"]
    print(f"\n=== {title} — GDZIE wypada nierozpoznana przebudowa (luka < 5 min) ===")
    print(f"{'miejsce':>16} {'par':>9} {'rebuild%':>10} {'tokeny':>15}")
    for b, name in ((True, "granica tury"), (False, "wnetrze tury")):
        c = cell[b]
        if not c["n"]:
            continue
        print(f"{name:>16} {c['n']:>9} {100.0*c['reb']/c['n']:>9.2f}% {c['tok']:>15,}")
    a, z = cell[True], cell[False]
    if a["n"] and z["n"] and z["reb"]:
        ratio = (a["reb"]/a["n"]) / (z["reb"]/z["n"])
        print(f"  -> na granicy tury {ratio:.0f}x czesciej niz w srodku tury. Eviction po stronie"
              "\n     dostawcy uderzalby rownomiernie, wiec ta asymetria go WYKLUCZA jako glowna przyczyne.")


def causes_report(sessions, signals, side, title, max_gap_min=None):
    """Rozbicie przebudow na przyczyny. `max_gap_min` zaweza do przebudow WEWNATRZ serii —
    tam, gdzie przerwa w pracy niczego nie tlumaczy i zostaje realna zmiana prefiksu."""
    stat = defaultdict(lambda: {"n": 0, "tokens": 0})
    total_n = total_tok = 0
    for key, evs in sessions.items():
        if key[1] != side:
            continue
        evs.sort(key=lambda e: e["t"])
        sigs = sorted(signals.get(key, []), key=lambda x: x["t"])
        j = 0
        for i in range(1, len(evs)):
            prev, cur = evs[i - 1], evs[i]
            ctx = prev["read"] + prev["create"]
            if ctx < MIN_CTX:
                continue
            gap = (cur["t"] - prev["t"]).total_seconds() / 60.0
            if max_gap_min is not None and gap >= max_gap_min:
                continue
            if cur["read"] >= REBUILD_AT * ctx:
                continue
            while j < len(sigs) and sigs[j]["t"] < prev["t"]:
                j += 1
            window = []
            k = j
            while k < len(sigs) and sigs[k]["t"] <= cur["t"]:
                window.append(sigs[k]); k += 1
            c = attribute(prev, cur, window)
            stat[c]["n"] += 1
            stat[c]["tokens"] += cur["create"]
            total_n += 1
            total_tok += cur["create"]
    scope = "wszystkie przebudowy" if max_gap_min is None else f"przebudowy przy luce < {max_gap_min:g} min"
    print(f"\n=== {title} — PRZYCZYNY ({scope}) ===")
    if not total_n:
        print("  brak zdarzen")
        return
    print(f"{'przyczyna':>18} {'zdarzen':>9} {'tokeny':>15} {'% worka':>9}")
    for name, _why in CAUSES:
        st = stat.get(name)
        if not st or not st["n"]:
            continue
        print(f"{name:>18} {st['n']:>9} {st['tokens']:>15,} {100.0*st['tokens']/total_tok:>8.1f}%")
    print(f"{'RAZEM':>18} {total_n:>9} {total_tok:>15,} {'100.0%':>9}")


def report(sessions, side, title):
    stat = defaultdict(lambda: {"n": 0, "rebuild": 0, "tokens": 0})
    total_create = n_sess = 0
    for (_, s), evs in sessions.items():
        if s != side:
            continue
        n_sess += 1
        evs.sort(key=lambda e: e["t"])
        for i, cur in enumerate(evs):
            total_create += cur["create"]
            if i == 0:
                continue
            prev = evs[i - 1]
            ctx = prev["read"] + prev["create"]
            if ctx < MIN_CTX:
                continue
            gap = (cur["t"] - prev["t"]).total_seconds() / 60.0
            for lo, hi in BUCKETS:
                if lo <= gap < hi:
                    st = stat[label(lo, hi)]
                    st["n"] += 1
                    if cur["read"] < REBUILD_AT * ctx:
                        st["rebuild"] += 1
                        st["tokens"] += cur["create"]
                    break
    if not n_sess:
        print(f"\n=== {title} — brak danych ===")
        return
    print(f"\n=== {title} — sesji: {n_sess}, cache_creation razem: {total_create:,} tok ===")
    print(f"{'luka':>10} {'par':>8} {'rebuild%':>9} {'tokeny':>15} {'% kosztu':>9}")
    ge15 = 0
    for lo, hi in BUCKETS:
        st = stat.get(label(lo, hi))
        if not st or not st["n"]:
            continue
        pct_cost = 100.0 * st["tokens"] / total_create if total_create else 0
        print(f"{label(lo, hi):>10} {st['n']:>8} {100.0*st['rebuild']/st['n']:>8.1f}% "
              f"{st['tokens']:>15,} {pct_cost:>8.1f}%")
        if lo >= 15:
            ge15 += st["tokens"]
    if total_create:
        print(f"{'>=15m':>10} {'':>8} {'':>9} {ge15:>15,} {100.0*ge15/total_create:>8.1f}%"
              "   <- sufit oszczednosci z 'pracuj seriami'")


sessions, signals, ttl, n_req = collect(since)
report(sessions, False, "GLOWNA SESJA")
report(sessions, True, "SUBAGENTY (sidechain)")

# Worek z H18: przebudowy wewnatrz serii. Krzywa luk ich nie tlumaczy, wiec pytamy o prefiks.
causes_report(sessions, signals, False, "GLOWNA SESJA", max_gap_min=5)
causes_report(sessions, signals, False, "GLOWNA SESJA")
causes_report(sessions, signals, True, "SUBAGENTY (sidechain)", max_gap_min=5)
boundary_report(sessions, signals, False, "GLOWNA SESJA")

print("\n=== TTL faktycznie zamawiany (suma cache_creation) ===")
for side, name in ((False, "glowna sesja"), (True, "subagenty")):
    b = ttl[side]
    tot = b["1h"] + b["5m"]
    if not tot:
        print(f"{name:>14}: brak danych")
        continue
    print(f"{name:>14}: 1h {b['1h']:>13,} ({100*b['1h']/tot:5.1f}%)"
          f" | 5m {b['5m']:>13,} ({100*b['5m']/tot:5.1f}%)")
print(f"\nokno: od {since.date()}, unikalnych requestow: {n_req:,}")
print("\nlegenda przyczyn (kolejnosc = priorytet atrybucji, pierwsza pasujaca wygrywa):")
for name, why in CAUSES:
    print(f"  {name:>18} — {why}")
