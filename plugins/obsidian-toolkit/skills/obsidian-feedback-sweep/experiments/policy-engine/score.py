#!/usr/bin/env python3
"""Scorer: trafnosc wobec gold setu + spojnosc miedzy przebiegami."""
import json, sys, itertools, collections
from pathlib import Path

gold_path, runs = sys.argv[1], sys.argv[2:]
gold = {f"{x['source'][:10]}#{x['id']}": x for x in json.load(open(gold_path))}

loaded = {}
for r in runs:
    name = Path(r).stem
    data = json.load(open(r))
    loaded[name] = {x["id"]: x for x in data}

ids = sorted(set(gold) & set.intersection(*[set(v) for v in loaded.values()]))
print(f"pozycji porownywalnych: {len(ids)} (gold {len(gold)}, przebiegi {[len(v) for v in loaded.values()]})\n")

print("== TRAFNOSC wobec gold setu ==")
for name, run in loaded.items():
    t = sum(run[i]["type"] == gold[i]["type"] for i in ids)
    d = sum(run[i]["disposition"] == gold[i]["disposition"] for i in ids)
    b = sum(run[i]["type"] == gold[i]["type"] and run[i]["disposition"] == gold[i]["disposition"] for i in ids)
    print(f"  {name}: typ {t}/{len(ids)} ({t/len(ids):.0%}) · dyspozycja {d}/{len(ids)} ({d/len(ids):.0%}) · oba {b}/{len(ids)} ({b/len(ids):.0%})")

# baseline "zawsze klasa wiekszosciowa"
mt = collections.Counter(gold[i]["type"] for i in ids).most_common(1)[0]
md = collections.Counter(gold[i]["disposition"] for i in ids).most_common(1)[0]
print(f"  [null] zawsze '{mt[0]}': typ {mt[1]/len(ids):.0%} · zawsze '{md[0]}': dyspozycja {md[1]/len(ids):.0%}")

if len(loaded) > 1:
    print("\n== SPOJNOSC miedzy przebiegami (ta sama uwaga, inny przebieg) ==")
    for a, b in itertools.combinations(loaded, 2):
        t = sum(loaded[a][i]["type"] == loaded[b][i]["type"] for i in ids)
        d = sum(loaded[a][i]["disposition"] == loaded[b][i]["disposition"] for i in ids)
        print(f"  {a} vs {b}: typ {t/len(ids):.0%} · dyspozycja {d/len(ids):.0%}")
    unan_t = sum(len({loaded[n][i]["type"] for n in loaded}) == 1 for i in ids)
    unan_d = sum(len({loaded[n][i]["disposition"] for n in loaded}) == 1 for i in ids)
    print(f"  jednomyslnosc wszystkich {len(loaded)}: typ {unan_t}/{len(ids)} ({unan_t/len(ids):.0%}) · dyspozycja {unan_d}/{len(ids)} ({unan_d/len(ids):.0%})")

    print("\n== POZYCJE ROZJEZDZAJACE SIE (dyspozycja) ==")
    for i in ids:
        vals = {n: loaded[n][i]["disposition"] for n in loaded}
        if len(set(vals.values())) > 1:
            print(f"  {i:22} gold={gold[i]['disposition']:15} " + " ".join(f"{n}={v}" for n, v in vals.items()))

print("\n== MACIERZ POMYLEK (dyspozycja, przebieg 1) ==")
n0 = list(loaded)[0]
cm = collections.Counter((gold[i]["disposition"], loaded[n0][i]["disposition"]) for i in ids)
for (g, p), c in sorted(cm.items(), key=lambda x: -x[1]):
    mark = "  " if g == p else "->"
    print(f"  {mark} gold={g:15} pred={p:15} {c}")
