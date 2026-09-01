#!/usr/bin/env python3
"""Scorer dla silnika trojwartosciowego.

Dla silnika, ktory umie powiedziec "nie wiem", jedna liczba klamie. Mierzymy pare:
  - POKRYCIE  = na ilu pozycjach silnik w ogole wydal werdykt
  - PRECYZJA  = trafnosc TAM, GDZIE wydal (to jest liczba, ktorej sie ufa)
  - TRAFNOSC CALKOWITA = precyzja x pokrycie (porownywalna z baseline'em modelu)
Baseline modelu ma pokrycie 100% z definicji — zawsze cos zgadnie.
"""
import json, sys, collections
from pathlib import Path

gold = {f"{x['source'][:10]}#{x['id']}": x for x in json.load(open(sys.argv[1]))}
pred = {x["id"]: x for x in json.load(open(sys.argv[2]))}
ids = sorted(set(gold) & set(pred))
n = len(ids)
print(f"pozycji: {n}\n")

for axis in ("type", "disposition"):
    dec = [i for i in ids if pred[i].get(axis)]
    hit = [i for i in dec if pred[i][axis] == gold[i][axis]]
    cov = len(dec) / n
    prec = len(hit) / len(dec) if dec else 0.0
    print(f"== {axis.upper()} ==")
    print(f"  pokrycie:   {len(dec)}/{n} ({cov:.0%})")
    print(f"  precyzja:   {len(hit)}/{len(dec)} ({prec:.0%})  <- trafnosc tam, gdzie silnik sie wypowiedzial")
    print(f"  calkowita:  {len(hit)}/{n} ({len(hit)/n:.0%})")
    bad = collections.Counter((gold[i][axis], pred[i][axis]) for i in dec if pred[i][axis] != gold[i][axis])
    if bad:
        print("  pomylki:", "; ".join(f"{g}->{p} x{c}" for (g, p), c in bad.most_common(6)))
    und = [i for i in ids if not pred[i].get(axis)]
    if und:
        print(f"  undetermined ({len(und)}): " + ", ".join(und[:8]) + (" …" if len(und) > 8 else ""))
    print()

if any("owner" in pred[i] for i in ids):
    def norm_owner(s):
        s = (s or "").lower()
        for k in ("piotr", "tom", "will", "matt", "dominique", "kara"):
            if k in s:
                return k
        return s.strip(" —-()") or "?"
    dec = [i for i in ids if pred[i].get("owner") and gold[i].get("owner")]
    hit = [i for i in dec if norm_owner(pred[i]["owner"]) == norm_owner(gold[i]["owner"])
           or norm_owner(pred[i]["owner"]) in norm_owner(gold[i]["owner"])]
    if dec:
        print(f"== OWNER (zgrubnie, po pierwszym nazwisku) ==\n  {len(hit)}/{len(dec)} ({len(hit)/len(dec):.0%}) na {len(dec)} porownywalnych\n")
