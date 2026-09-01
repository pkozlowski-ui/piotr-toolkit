#!/usr/bin/env python3
"""Pomiar egzekucji KONTRAKTU ODPOWIEDZI na wlasnych transkryptach.

Po co: zeby ocene "styl znowu pekl" oprzec na liczbie, nie na wrazeniu z ostatniej sesji —
i zeby dalo sie sprawdzic, czy zmiana w kanale (CLAUDE.md vs hook reinject-rules.sh vs
guard na wyjsciu) cokolwiek poprawila.

Mianownik jest zawezony do odpowiedzi ZAMYKAJACYCH TURE, w ktorej byla REALNA PRACA
(mutacja stanu: Edit/Write/MultiEdit albo Bash z git commit/push) — bo tylko tam kontrakt
obowiazuje. Bez tego zawezenia licznik rozcienczaja krotkie odpowiedzi robocze i wynik
wyglada gorzej niz jest.

Mierzone soczewki:
  ma sekcje     — "Decyzje dla Ciebie" albo jawne "nic ode mnie nie potrzebujesz"
  ma REKO       — nazwana rekomendacja (albo jawny brak potrzeby decyzji)
  warunek|REKO  — jaki UDZIAL odpowiedzi z rekomendacja niesie warunek uniewaznienia

Baseline 2026-08 (1250 odpowiedzi): 86% / 82% / 23%.

Uzycie: style_probe.py [YYYY-MM-DD]   (domyslnie od 2026-08-01)
"""
import json, os, glob, re
from datetime import datetime, timezone
from collections import defaultdict

import sys
SINCE = (datetime.fromisoformat(sys.argv[1] + "T00:00:00+00:00")
         if len(sys.argv) > 1 else datetime(2026, 8, 1, tzinfo=timezone.utc))
ts = lambda s: datetime.fromisoformat(s.replace("Z", "+00:00"))
MUT = {"Edit", "Write", "MultiEdit", "NotebookEdit"}

def text_of(m):
    c = m.get("content")
    if isinstance(c, str): return c
    if isinstance(c, list):
        return "\n".join(b.get("text","") for b in c if isinstance(b,dict) and b.get("type")=="text")
    return ""

def tools_of(m):
    c = m.get("content"); out = []
    if isinstance(c, list):
        for b in c:
            if isinstance(b, dict) and b.get("type") == "tool_use":
                out.append((b.get("name",""), json.dumps(b.get("input",""))[:400]))
    return out

sessions = defaultdict(list)
for fp in glob.glob(os.path.expanduser("~/.claude/projects/**/*.jsonl"), recursive=True):
    try: fh = open(fp, errors="replace")
    except OSError: continue
    with fh:
        for line in fh:
            try: d = json.loads(line)
            except Exception: continue
            if d.get("isSidechain") or d.get("isMeta"): continue
            t, typ = d.get("timestamp"), d.get("type")
            if not t or typ not in ("assistant","user"): continue
            try: tt = ts(t)
            except Exception: continue
            if tt < SINCE: continue
            m = d.get("message") or {}
            if typ == "user":
                c = m.get("content")
                if isinstance(c, list) and any(isinstance(b,dict) and b.get("type")=="tool_result" for b in c):
                    continue
                sessions[d.get("sessionId")].append({"k":"user","t":tt})
            else:
                sessions[d.get("sessionId")].append(
                    {"k":"asst","t":tt,"txt":text_of(m),"tools":tools_of(m)})

RE_DEC  = re.compile(r"Decyzje dla Ciebie", re.I)
RE_NIC  = re.compile(r"nic (od Ciebie|ode mnie) nie (potrzebuj|potrzeba)", re.I)
RE_REKO = re.compile(r"\bREKO\b|\brekomend", re.I)
RE_INV  = re.compile(r"przestaje by[ćc] trafn|warunek uniewa[żz]nienia|przestaje obowi[ąa]zywa", re.I)

by = defaultdict(lambda: {"n":0,"dec":0,"reko":0,"inv":0,"inv_of_reko":0,"reko_n":0,"chars":[]})
for sid, evs in sessions.items():
    evs.sort(key=lambda e: e["t"])
    worked = False
    for i, e in enumerate(evs):
        if e["k"] == "user":
            worked = False; continue
        for name, inp in e["tools"]:
            if name in MUT or (name == "Bash" and re.search(r"git (commit|push|merge)", inp)):
                worked = True
        nxt = evs[i+1]["k"] if i+1 < len(evs) else "end"
        if nxt != "user" or not e["txt"].strip() or not worked:
            continue
        k = e["t"].strftime("%Y-%m"); b = by[k]
        b["n"] += 1; b["chars"].append(len(e["txt"]))
        has_dec = bool(RE_DEC.search(e["txt"]) or RE_NIC.search(e["txt"]))
        if has_dec: b["dec"] += 1
        if RE_REKO.search(e["txt"]) or RE_NIC.search(e["txt"]): b["reko"] += 1
        if RE_REKO.search(e["txt"]):
            b["reko_n"] += 1
            if RE_INV.search(e["txt"]): b["inv_of_reko"] += 1
        if RE_INV.search(e["txt"]): b["inv"] += 1

print("MIANOWNIK: odpowiedzi zamykajace ture Z REALNA PRACA (edycja pliku / git commit)\n")
print(f"{'miesiac':>9} {'odp.':>6} {'ma sekcje':>10} {'ma REKO':>9} {'warunek|REKO':>13} {'mediana zn.':>12}")
for k in sorted(by):
    b = by[k]; ch = sorted(b["chars"]); med = ch[len(ch)//2] if ch else 0
    wr = 100*b["inv_of_reko"]/b["reko_n"] if b["reko_n"] else 0
    print(f"{k:>9} {b['n']:>6} {100*b['dec']/b['n']:>9.0f}% {100*b['reko']/b['n']:>8.0f}% "
          f"{wr:>12.0f}% {med:>12,}")
