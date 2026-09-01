#!/usr/bin/env python3
"""Ekstraktor gold setu z domknietych rejestrow feedback-sweep.

Kazdy rejestr ma (w roznych wariantach jezykowych/kolumnowych) tabele triage
`# | Lokalizacja | Typ | Owner | Dyspozycja | ...` oraz bloki detalu `### F1 · ...`
z linia `- **Komentarz:**` / `- **Comment:**`. Skladamy z tego rekordy
(verbatim komentarza) -> (typ, dyspozycja, owner).
"""
import json, re, sys, unicodedata
from pathlib import Path

SRC = Path(sys.argv[1])
OUT = Path(sys.argv[2])

TYPE_EMOJI = {"❓": "question", "🐞": "bug", "🎨": "design", "📦": "product",
              "💬": "note", "✨": "inspiration"}

DISPO_PATTERNS = [
    ("do-now",        r"do\s*now"),
    ("answer-close",  r"answer\s*(&|and)\s*close|answered|odpowiedz|odpowiedziane"),
    ("needs-decision",r"needs?\s*decision|do\s*decyzji|wymaga\s*decyzji|routed|decided|flagged"),
    ("defer",         r"defer|phase[-\s]?2|odlo[zż]|zaparkow"),
    ("delight",       r"delight"),
    ("no-action",     r"no\s*action|bez\s*akcji"),
]

def norm(s):
    s = unicodedata.normalize("NFC", s or "").strip()
    return re.sub(r"\s+", " ", s)

def strip_md(s):
    s = re.sub(r"\[\[([^\]|]+)\|?[^\]]*\]\]", r"\1", s)
    s = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", s)
    s = re.sub(r"[*`_]", "", s)
    return norm(s)

def parse_type(cell):
    hits = [(cell.index(ch), name) for ch, name in TYPE_EMOJI.items() if ch in cell]
    if hits:
        return min(hits)[1]
    low = cell.lower()
    for name, pat in [("question", r"pytanie|question"), ("bug", r"bug|niesp[oó]jno"),
                      ("design", r"design|pomys[lł] design"), ("product", r"produkt|product|scope"),
                      ("inspiration", r"inspiracj|inspiration|referenc"),
                      ("note", r"notka|note|pochwa")]:
        if re.search(pat, low):
            return name
    return None

def parse_dispo(cell):
    low = strip_md(cell).lower()
    for name, pat in DISPO_PATTERNS:
        if re.search(pat, low):
            return name
    # fallback: rejestry ktore w kolumnie trzymaja sam status wykonania
    if re.search(r"^\s*(✅|done|zrobione|built|wdro[zż])", low):
        return "do-now"
    return None

def split_row(line):
    line = line.strip()
    if not line.startswith("|"):
        return None
    cells = line.strip("|").split("|")
    return [c.strip() for c in cells]

def find_tables(lines):
    """Zwraca liste (header_cells, [row_cells...]) dla tabel wygladajacych na triage."""
    tables, i = [], 0
    while i < len(lines):
        row = split_row(lines[i])
        if row and i + 1 < len(lines):
            sep = split_row(lines[i + 1])
            if sep and all(re.fullmatch(r":?-{2,}:?", c) for c in sep if c):
                body, j = [], i + 2
                while j < len(lines):
                    r = split_row(lines[j])
                    if not r:
                        break
                    body.append(r)
                    j += 1
                tables.append((row, body))
                i = j
                continue
        i += 1
    return tables

def col_index(header, *patterns):
    for idx, h in enumerate(header):
        low = h.lower()
        for p in patterns:
            if re.search(p, low):
                return idx
    return None

def parse_comments(text):
    """Mapa id-bloku (F1/B2/...) -> verbatim komentarza z bloku detalu."""
    out = {}
    for m in re.finditer(r"^#{2,4}\s+([A-Z]{1,3}[-·]?\d*[a-z]?\d*)\s*[·:.\-][^\n]*\n(.*?)(?=^#{2,4}\s|\Z)",
                         text, re.M | re.S):
        key, body = m.group(1), m.group(2)
        cm = re.search(r"^-\s*\*\*(?:Komentarz|Comment)\b[^:]*:\*\*\s*(.+?)(?=\n-\s*\*\*|\n\n|\Z)",
                       body, re.M | re.S)
        if cm:
            out[key] = strip_md(cm.group(1))
        loc = re.search(r"^-\s*\*\*(?:Lokalizacja|Location)\b[^:]*:\*\*\s*(.+)$", body, re.M)
        # autor bywa na wlasnej linii ALBO doklejony inline do linii Location
        aut = re.search(r"\*\*(?:Autor|Author)\b[^:]*:\*\*\s*([^·\n|]+)", body)
        if key in out:
            out[key] = {"comment": out[key],
                        "location": strip_md(loc.group(1)) if loc else None,
                        "author": strip_md(aut.group(1)) if aut else None}
    return out

# rejestr dedykowany jednej osobie ma ja w nazwie pliku — ostatnia deska ratunku,
# gdy blok detalu nie podaje autora wprost
FILE_AUTHOR = [
    (r"·\s*Tom\b(?!.*\+)", "Tom Riant"),
    (r"·\s*Dominique\b(?!.*\+)", "Dominique Amis"),
    (r"Dom's Feedback", "Dominique Amis"),
    (r"Dom's Figjam", "Dominique Amis"),
]

records, skipped = [], []
for path in sorted(SRC.glob("*.md")):
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    details = parse_comments(text)
    got = 0
    for header, body in find_tables(lines):
        i_id = col_index(header, r"^#$", r"^nr$", r"^no$")
        i_typ = col_index(header, r"^typ$", r"^type$")
        i_dis = col_index(header, r"dyspozycj", r"disposition")
        if i_id is None or i_typ is None or i_dis is None:
            continue
        i_own = col_index(header, r"^owner", r"decydent")
        i_loc = col_index(header, r"lokalizacj", r"location", r"ekran", r"screen")
        i_vrb = col_index(header, r"verbatim", r"one-liner", r"komentarz", r"start")
        for row in body:
            if max(x for x in [i_id, i_typ, i_dis] if x is not None) >= len(row):
                continue
            rid = strip_md(row[i_id])
            if not re.fullmatch(r"[A-Z]{1,3}[-·]?\d*[a-z]?\d*", rid) or not re.search(r"[0-9a-z]", rid):
                continue
            typ, dis = parse_type(row[i_typ]), parse_dispo(row[i_dis])
            if not typ or not dis:
                skipped.append({"file": path.name, "id": rid,
                                "typ_raw": row[i_typ], "dis_raw": row[i_dis]})
                continue
            det = details.get(rid) or {}
            author = det.get("author")
            if not author:
                for pat, who in FILE_AUTHOR:
                    if re.search(pat, path.name):
                        author = who
                        break
            rec = {
                "source": path.name,
                "id": rid,
                "comment": det.get("comment") or (strip_md(row[i_vrb]) if i_vrb is not None and i_vrb < len(row) else None),
                "location": det.get("location") or (strip_md(row[i_loc]) if i_loc is not None and i_loc < len(row) else None),
                "author": author,
                "type": typ,
                "disposition": dis,
                "owner": strip_md(row[i_own]) if i_own is not None and i_own < len(row) else None,
            }
            records.append(rec)
            got += 1
    if got == 0:
        skipped.append({"file": path.name, "id": "*", "typ_raw": "", "dis_raw": "BRAK TABELI TRIAGE"})

OUT.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
with_comment = [r for r in records if r["comment"]]
print(f"rekordow: {len(records)} (z verbatim: {len(with_comment)}) z {len(set(r['source'] for r in records))} rejestrow")
print(f"pominietych wierszy/plikow: {len(skipped)}")
for s in skipped[:25]:
    print("  -", s["file"], s["id"], "|", s["typ_raw"][:30], "|", s["dis_raw"][:40])
