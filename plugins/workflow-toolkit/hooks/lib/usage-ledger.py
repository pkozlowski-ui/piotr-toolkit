#!/usr/bin/env python3
# usage-ledger.py — inkrementalny licznik zuzycia liczony z TRANSKRYPTOW sesji.
#
# Po co: obie bramy kosztowe (gate-spend-ceiling.sh, gate-model-switch.sh) czytaly dotad zrzut
# `~/.claude/state/rate-limits.json`, ktory pisze `statusline.sh`. Zmierzone 2026-09-01: ten
# skrypt NIE JEST uruchamiany w tym interfejsie w ogole (heartbeat pisany czystym shellem na
# poczatku skryptu skasowany o 12:57:44, nieobecny o 12:59:49), wiec zrzut nigdy nie powstaje
# i obie bramy sa slepe. Transkrypty (`~/.claude/projects/*/*.jsonl`) sa jedynym zrodlem
# zmierzonym jako realnie dzialajace: kazdy request zapisuje tam `message.usage`.
#
# CO TO MIERZY, A CZEGO NIE (czytaj, zanim oprzesz na tym decyzje):
#   - Mierzy WOLUMEN TOKENOW, ktory ta maszyna wyprodukowala. To PROXY zuzycia limitu planu,
#     nie sam limit. Serwer liczy swoje okna 5h/7d po swojemu i my tego przelicznika NIE ZNAMY.
#   - Waga `(input + cache_creation) + 0,1 x cache_read + 5 x output` odwzorowuje PUBLICZNE
#     stawki CENOWE Anthropic wzgledem input (cache read 0,1x, output 5x). To zalozenie
#     przeniesione z cennika na limit — nie zmierzony przelicznik planu. Trzymamy dokladnie ta
#     formule (nie 1,25x na cache_creation, jak w cenniku), zeby liczby zostaly porownywalne
#     z baza pomiarowa z karty: mediana ~235, p75 268, p90 347, max 401 (18 dni, 801 plikow).
#     Zmiana wspolczynnikow uniewaznia te progi — wtedy przemierz baze od nowa.
#   - `raw` w wyjsciu podaje surowe skladniki. To kanal kalibracji: gdy kiedykolwiek uda sie
#     zestawic te liczby z realnym odczytem `/usage`, prog da sie oprzec na pomiarze zamiast
#     na zalozeniu. Do tego czasu prog jest z rozkladu wlasnych dni, nie z cennika.
#   - BEZ deduplikacji miedzy plikami. Fork sesji kopiuje historie do nowego pliku, wiec
#     zforkowane requesty licza sie dwa razy. Swiadome: baza pomiarowa z karty byla liczona
#     tak samo, a dedup po `message.id` uczynilby progi nieporownywalnymi.
#
# JAK JEST TANI (to jest warunek dzialania w UserPromptSubmit, nie optymalizacja):
#   Ledger `~/.claude/state/usage-ledger.json` trzyma per plik: offset bajtowy + wlasny wklad
#   do kazdego dnia. Kazdy przebieg czyta TYLKO bajty dopisane od ostatniego razu. Wklad jest
#   per-plik, wiec obciecie/rotacja pliku (rozmiar < offset) resetuje jego wklad zamiast
#   dublowac dzien. Skan ma DEADLINE (--deadline, domyslnie 2,5 s): pliki bierzemy od
#   najswiezszego mtime, a to, czego nie zdazymy, ma swoj offset nietkniety i dojdzie w kolejnej
#   turze. Zimny start (2 GB, 1480 plikow) rozklada sie wiec na kilka tur zamiast zawiesic prompt
#   — i przez ten czas wyjscie ma `complete: false`, zeby brama mogla powiedziec, ze jeszcze nie widzi calosci.
#
# Uzycie:  python3 usage-ledger.py [--json] [--deadline SEC] [--projects DIR] [--state DIR] [--no-write]
# Kontrakt: zawsze exit 0 i zawsze poprawny JSON na stdout. Modul liczacy dla bramy nie moze
# wywalic sesji — gdy cokolwiek pojdzie nie tak, zwraca ok:false i brama mowi, ze jest slepa.

import argparse
import datetime
import glob
import json
import os
import sys
import time

W_CACHE_READ = 0.1
W_OUTPUT = 5.0
KEEP_DAYS = 14          # ile dni historii trzymamy w ledgerze (okno 7d + zapas na strefy czasowe)
WIN_DAYS = 7            # dlugosc okna kroczacego
FAMILIES = ("fable", "opus", "sonnet", "haiku")


def family(model):
    """`claude-opus-5` -> `opus`. Rodzina, nie pelne id — brama pyta o KLASE modelu,
    a pelne id zmienia sie co release i rozsypaloby kubelki historyczne."""
    m = (model or "").lower()
    for f in FAMILIES:
        if f in m:
            return f
    return "inne"


def _empty(reason):
    return {
        "ok": False, "reason": reason, "source": "transcripts",
        "today": {"w": 0.0, "n": 0}, "win7": {"w": 0.0, "n": 0},
        "days": {}, "raw": {}, "complete": False, "scanned": 0, "bytes": 0,
    }


def load_ledger(path):
    try:
        with open(path) as f:
            d = json.load(f)
        if isinstance(d, dict) and isinstance(d.get("files"), dict):
            return d
    except Exception:
        pass
    return {"v": 1, "files": {}}


def save_ledger(path, ledger):
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        tmp = path + ".tmp"
        with open(tmp, "w") as f:
            json.dump(ledger, f, separators=(",", ":"))
        os.replace(tmp, path)
    except Exception:
        pass


def local_date(ts_iso):
    """ISO 8601 (zwykle UTC z 'Z') -> lokalna data YYYY-MM-DD. None gdy nie da sie sparsowac."""
    if not ts_iso:
        return None
    t = str(ts_iso).strip().replace("Z", "+00:00")
    try:
        dt = datetime.datetime.fromisoformat(t)
    except Exception:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=datetime.timezone.utc)
    return dt.astimezone().date().isoformat()


def scan_file(path, start_off):
    """Czyta plik od `start_off` do EOF.

    Zwraca (nowy_offset, {dzien: [waga, n, in, out, cr, cc]}, {dzien: {rodzina: [waga, n]}}).

    Czytamy w trybie binarnym i tniemy na ostatnim pelnym '\n' — plik moze byc dopisywany
    w trakcie czytania i ostatnia linia bywa ucieta. Ucieta linia zostaje POZA offsetem,
    wiec dojdzie w calosci przy nastepnym przebiegu.
    """
    acc = {}
    macc = {}
    try:
        size = os.path.getsize(path)
    except OSError:
        return start_off, acc, macc
    if size <= start_off:
        return start_off, acc, macc
    try:
        with open(path, "rb") as f:
            f.seek(start_off)
            chunk = f.read(size - start_off)
    except OSError:
        return start_off, acc, macc

    cut = chunk.rfind(b"\n")
    if cut < 0:
        return start_off, acc, macc    # ani jednej pelnej linii — nic nie konsumujemy
    consumed = cut + 1
    text = chunk[:consumed].decode("utf-8", "replace")

    for line in text.splitlines():
        if '"usage"' not in line:      # tani filtr przed json.loads — wiekszosc linii odpada tu
            continue
        try:
            rec = json.loads(line)
        except Exception:
            continue
        msg = rec.get("message")
        if not isinstance(msg, dict):
            continue
        u = msg.get("usage")
        if not isinstance(u, dict):
            continue
        inp = u.get("input_tokens") or 0
        outp = u.get("output_tokens") or 0
        cr = u.get("cache_read_input_tokens") or 0
        cc = u.get("cache_creation_input_tokens") or 0
        if not (inp or outp or cr or cc):
            continue
        day = local_date(rec.get("timestamp"))
        if not day:
            continue
        w = (inp + cc) + W_CACHE_READ * cr + W_OUTPUT * outp
        b = acc.setdefault(day, [0.0, 0, 0, 0, 0, 0])
        b[0] += w
        b[1] += 1
        b[2] += inp
        b[3] += outp
        b[4] += cr
        b[5] += cc
        mb = macc.setdefault(day, {}).setdefault(family(msg.get("model")), [0.0, 0])
        mb[0] += w
        mb[1] += 1
    return start_off + consumed, acc, macc


def collect(projects_dir, state_dir, deadline_s, write=True):
    ledger_path = os.path.join(state_dir, "usage-ledger.json")
    ledger = load_ledger(ledger_path)
    files = ledger["files"]

    try:
        paths = glob.glob(os.path.join(projects_dir, "*", "*.jsonl"))
    except Exception as e:
        return _empty("nie moge wylistowac %s (%s)" % (projects_dir, e))
    if not paths:
        return _empty("brak transkryptow w %s" % projects_dir)

    # Kandydaci = pliki, ktore urosly od ostatniego skanu. Najswiezszy mtime pierwszy:
    # gdy deadline utnie skan, to co zostanie nietkniete jest najstarsze, czyli najmniej
    # istotne dla okna dnia i 7d.
    cand = []
    for p in paths:
        try:
            st = os.stat(p)
        except OSError:
            continue
        ent = files.get(p)
        off = int(ent.get("o", 0)) if isinstance(ent, dict) else 0
        if isinstance(ent, dict):
            # Plik obciety LUB podmieniony pod ta sama sciezka. Sam rozmiar nie wystarczy:
            # podmiana na plik tej samej dlugosci jest po rozmiarze nieodrozninalna od braku
            # zmian, wiec trzymamy tez i-node. Reset = licz wklad tego pliku od zera, zamiast
            # dopisac go do starego (co zdublowaloby dzien).
            if st.st_size < off or (ent.get("i") is not None and ent["i"] != st.st_ino):
                off = 0
                ent["d"] = {}
                ent["m"] = {}
        if st.st_size > off:
            cand.append((st.st_mtime, p, off))
    cand.sort(reverse=True)

    t0 = time.monotonic()
    scanned = 0
    read_bytes = 0
    for _, p, off in cand:
        if time.monotonic() - t0 > deadline_s:
            break
        new_off, acc, macc = scan_file(p, off)
        if new_off == off and not acc:
            continue
        ent = files.setdefault(p, {"o": 0, "d": {}})
        if off == 0:
            ent["d"] = {}              # reset wkladu po obcieciu pliku
            ent["m"] = {}
        read_bytes += new_off - off
        ent["o"] = new_off
        try:
            ent["i"] = os.stat(p).st_ino
        except OSError:
            pass
        dd = ent.setdefault("d", {})
        for day, b in acc.items():
            cur = dd.get(day)
            dd[day] = [cur[i] + b[i] for i in range(6)] if cur else b
        mm = ent.setdefault("m", {})
        for day, fams in macc.items():
            tgt = mm.setdefault(day, {})
            for fam, b in fams.items():
                cur = tgt.get(fam)
                tgt[fam] = [cur[0] + b[0], cur[1] + b[1]] if cur else b
        scanned += 1
    complete = scanned >= len(cand)

    today = datetime.date.today()
    cutoff = (today - datetime.timedelta(days=KEEP_DAYS)).isoformat()

    # Prune + agregacja w jednym przebiegu. Plik bez zadnego dnia w oknie wypada z ledgera,
    # zeby nie puchl w nieskonczonosc (1480 plikow / 2 GB w projects).
    days = {}
    mdays = {}
    dead = []
    for p, ent in files.items():
        dd = ent.get("d") or {}
        fresh = {k: v for k, v in dd.items() if k >= cutoff}
        if len(fresh) != len(dd):
            ent["d"] = fresh
        mfresh = {k: v for k, v in (ent.get("m") or {}).items() if k >= cutoff}
        if len(mfresh) != len(ent.get("m") or {}):
            ent["m"] = mfresh
        if not fresh and not os.path.exists(p):
            dead.append(p)
            continue
        for day, b in fresh.items():
            cur = days.setdefault(day, [0.0, 0, 0, 0, 0, 0])
            for i in range(6):
                cur[i] += b[i]
        for day, fams in mfresh.items():
            tgt = mdays.setdefault(day, {})
            for fam, b in fams.items():
                cur = tgt.get(fam)
                tgt[fam] = [cur[0] + b[0], cur[1] + b[1]] if cur else list(b)
    for p in dead:
        files.pop(p, None)

    if write:
        ledger["updated"] = int(time.time())
        save_ledger(ledger_path, ledger)

    def pack(b):
        return {"w": round(b[0] / 1e6, 2), "n": b[1]}

    tkey = today.isoformat()
    tb = days.get(tkey, [0.0, 0, 0, 0, 0, 0])
    wstart = (today - datetime.timedelta(days=WIN_DAYS - 1)).isoformat()
    wb = [0.0, 0, 0, 0, 0, 0]
    for day, b in days.items():
        if day >= wstart:
            for i in range(6):
                wb[i] += b[i]

    # Rozbicie okna 7d i dnia na rodziny modeli — brama modelu pyta „ile Fable'a poszlo",
    # a to jest jedyne miejsce, gdzie transkrypty odpowiadaja na to wprost.
    def by_family(since):
        out = {}
        for day, fams in mdays.items():
            if day < since:
                continue
            for fam, b in fams.items():
                cur = out.setdefault(fam, [0.0, 0])
                cur[0] += b[0]
                cur[1] += b[1]
        return {f: {"w": round(b[0] / 1e6, 2), "n": b[1]} for f, b in sorted(out.items())}

    return {
        "ok": True,
        "source": "transcripts",
        "today": pack(tb),
        "win7": pack(wb),
        "today_models": by_family(tkey),
        "win7_models": by_family(wstart),
        "days": {d: pack(b) for d, b in sorted(days.items())},
        # surowe skladniki okna 7d — kanal kalibracji wagi wobec realnego /usage
        "raw": {"input": wb[2], "output": wb[3], "cache_read": wb[4], "cache_creation": wb[5]},
        "complete": complete,
        "scanned": scanned,
        "pending": max(0, len(cand) - scanned),
        "bytes": read_bytes,
        "files": len(files),
        "updated": int(time.time()),
    }


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--deadline", type=float,
                    default=float(os.environ.get("WFT_USAGE_DEADLINE_S", "2.5")))
    ap.add_argument("--projects", default=os.path.expanduser("~/.claude/projects"))
    ap.add_argument("--state", default=os.path.expanduser("~/.claude/state"))
    ap.add_argument("--no-write", action="store_true")
    a = ap.parse_args()
    try:
        res = collect(a.projects, a.state, a.deadline, write=not a.no_write)
    except Exception as e:
        res = _empty("blad licznika: %s" % e)
    if a.json:
        print(json.dumps(res, ensure_ascii=False))
    else:
        if not res["ok"]:
            print("SLEPY: %s" % res.get("reason"))
        else:
            print("dzis %.1f (%d req) · 7d %.1f (%d req) · complete=%s pending=%d"
                  % (res["today"]["w"], res["today"]["n"], res["win7"]["w"],
                     res["win7"]["n"], res["complete"], res["pending"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
