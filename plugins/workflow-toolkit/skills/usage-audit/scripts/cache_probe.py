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
osobno dla glownej sesji i dla subagentow (sidechain).
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


def collect(since):
    """Zbiera unikalne requesty per (sesja, sidechain). Dedup po requestId — iteracje
    w obrebie jednego requestu powtarzaja to samo `usage`."""
    sessions, seen = defaultdict(list), set()
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
                if d.get("type") != "assistant":
                    continue
                u = (d.get("message") or {}).get("usage")
                rid, t = d.get("requestId"), d.get("timestamp")
                if not (u and rid and t) or rid in seen:
                    continue
                seen.add(rid)
                try:
                    tt = datetime.fromisoformat(t.replace("Z", "+00:00"))
                except Exception:
                    continue
                if tt < since:
                    continue
                side = bool(d.get("isSidechain"))
                cc = u.get("cache_creation") or {}
                ttl[side]["1h"] += cc.get("ephemeral_1h_input_tokens", 0) or 0
                ttl[side]["5m"] += cc.get("ephemeral_5m_input_tokens", 0) or 0
                sessions[(d.get("sessionId"), side)].append({
                    "t": tt,
                    "read": u.get("cache_read_input_tokens", 0) or 0,
                    "create": u.get("cache_creation_input_tokens", 0) or 0,
                })
    return sessions, ttl, len(seen)


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


sessions, ttl, n_req = collect(since)
report(sessions, False, "GLOWNA SESJA")
report(sessions, True, "SUBAGENTY (sidechain)")

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
