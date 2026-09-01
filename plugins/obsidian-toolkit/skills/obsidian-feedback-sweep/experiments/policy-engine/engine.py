#!/usr/bin/env python3
"""Deterministyczny silnik werdyktu dla feedback-sweep.

Wejscie: (reguly, pola, kontekst) -> werdykt. ZERO wywolan modelu.
Model jest uzyty raz wczesniej, do ekstrakcji POL (obiektywnych atrybutow tekstu);
tutaj juz tylko liczymy.

Logika trojwartosciowa: TRUE / FALSE / UNKNOWN.
UNKNOWN nie jest zamiatane pod FALSE — regula, ktorej przeslanka jest nieznana,
zwraca UNKNOWN i silnik moze skonczyc werdyktem `undetermined`. To jest cel,
nie awaria: jawne "nie wiem" wraca do czlowieka zamiast cichego zgadniecia.
"""
from __future__ import annotations
import json, sys
from pathlib import Path

TRUE, FALSE, UNKNOWN = True, False, None


# ---------- logika trojwartosciowa (Kleene) ----------

def k_and(*vals):
    if any(v is FALSE for v in vals):
        return FALSE
    if any(v is UNKNOWN for v in vals):
        return UNKNOWN
    return TRUE


def k_or(*vals):
    if any(v is TRUE for v in vals):
        return TRUE
    if any(v is UNKNOWN for v in vals):
        return UNKNOWN
    return FALSE


def k_not(v):
    return UNKNOWN if v is UNKNOWN else (not v)


# ---------- predykaty wyprowadzone z KONTEKSTU (bez modelu) ----------

def derive(name: str, fields: dict, context: dict):
    """Predykaty liczone z (pola + kontekst projektu). Deterministyczne — zero modelu.

    Rozdzielenie jest celowe: `fields` to co model wyczytal z TEKSTU, `context` to
    dane projektu (macierz wlascicieli, kim jestesmy). Ta sama polityka na innym
    projekcie = ten sam plik regul, inny plik kontekstu.
    """
    if name == "author_owns_layer":
        # regula "proposer = decision-maker": autor komentarza sam jest wlascicielem
        # warstwy, ktorej dotyka -> jego zdanie JEST decyzja, nie prosba o decyzje
        layer = fields.get("change_layer")
        author = (fields.get("_author") or "").strip()
        if not author or layer in (None, "unclear", "none"):
            return UNKNOWN
        owners = context.get("domain_owners", {})
        for person, layers in owners.items():
            if person.lower() in author.lower() and layer in layers:
                return TRUE
        # autor nieznany macierzy -> nie wiemy, czy ma wladze; nie udawaj FALSE
        if not any(person.lower() in author.lower() for person in owners):
            return UNKNOWN
        return FALSE
    if name == "layer_owned_by_us":
        layer = fields.get("change_layer")
        if layer in (None, "unclear"):
            return UNKNOWN
        entry = context.get("owner_matrix", {}).get(layer)
        if not entry:
            return UNKNOWN
        return TRUE if entry["owner"] in context.get("us", []) else FALSE
    raise ValueError(f"nieznany predykat wyprowadzony: {name}")


def owner_for(fields: dict, context: dict):
    """Trzecia os — Owner. Wyprowadzana z macierzy projektu, nie z osadu modelu."""
    layer = fields.get("change_layer")
    if layer in (None, "unclear", "none"):
        return None, "warstwa zmiany nierozstrzygnieta"
    entry = context.get("owner_matrix", {}).get(layer)
    if not entry:
        return None, f"macierz projektu nie ma wpisu dla warstwy '{layer}'"
    return entry["owner"], entry.get("why")


# ---------- ewaluacja przeslanki ----------

def eval_atom(atom: dict, fields: dict, context: dict):
    """Atom: {"field": nazwa, "in": [...]} / {"field": ..., "not_in": [...]}
    albo {"derived": nazwa, "in": ["yes"|"no"]}.

    Pole nieobecne albo o wartosci "unclear" -> UNKNOWN.
    """
    if "derived" in atom:
        v = derive(atom["derived"], fields, context)
        if v is UNKNOWN:
            return UNKNOWN
        want = atom.get("in", ["yes"])
        return TRUE if (("yes" if v else "no") in want) else FALSE
    name = atom["field"]
    val = fields.get(name)
    if val is None or val == "unclear":
        return UNKNOWN
    if "in" in atom:
        return TRUE if val in atom["in"] else FALSE
    if "not_in" in atom:
        return TRUE if val not in atom["not_in"] else FALSE
    raise ValueError(f"regula bez 'in'/'not_in': {atom}")


def eval_clause(clause, fields, context):
    """Klauzula = lista atomow (AND) albo {"any": [...]} (OR)."""
    if isinstance(clause, dict) and "any" in clause:
        return k_or(*[eval_clause(c, fields, context) for c in clause["any"]])
    if isinstance(clause, dict) and "all" in clause:
        return k_and(*[eval_clause(c, fields, context) for c in clause["all"]])
    if isinstance(clause, dict) and "not" in clause:
        return k_not(eval_clause(clause["not"], fields, context))
    if isinstance(clause, dict):
        return eval_atom(clause, fields, context)
    if isinstance(clause, list):
        return k_and(*[eval_clause(c, fields, context) for c in clause])
    raise ValueError(f"nieznany ksztalt klauzuli: {clause}")


# ---------- silnik ----------

def decide(axis_rules: list, fields: dict, context: dict):
    """Zwraca (werdykt, slad).

    Reguly sa UPORZADKOWANE — pierwsza, ktora zwroci TRUE, wygrywa (priorytet
    zapisany jawnie w kolejnosci, nie ukryty w scoringu).

    Kluczowa wlasnosc: jesli jakas WCZESNIEJSZA regula zwrocila UNKNOWN, nie wolno
    przyjac werdyktu regule pozniejszej — bo gdyby ta wczesniejsza byla prawdziwa,
    to ONA by wygrala. Silnik zwraca wtedy `undetermined` i wskazuje, ktore pole
    rozstrzygnieciem blokuje.
    """
    trace, pending = [], []
    for rule in axis_rules:
        v = eval_clause(rule["when"], fields, context)
        trace.append({"rule": rule["id"], "result": {TRUE: "true", FALSE: "false"}.get(v, "unknown")})
        if v is TRUE:
            if pending:
                return None, {"reason": "blocked-by-unknown", "would_be": rule["then"],
                              "blocking_rules": pending, "trace": trace}
            return rule["then"], {"reason": "matched", "rule": rule["id"],
                                  "why": rule.get("why"), "trace": trace}
        if v is UNKNOWN:
            # `on_unknown: "false"` = jawnie zadeklarowany prior: to regula-straznik na
            # rzadki wyjatek, wiec "nie wiem" traktujemy jak "nie zaszlo" i idziemy dalej.
            # Domyslne "block" zostaje tam, gdzie stawka jest realna (rozwidlenie
            # do-now / needs-decision) — tam niewiedza MA zatrzymac silnik.
            if rule.get("on_unknown") == "false":
                continue
            pending.append({"rule": rule["id"], "missing": missing_fields(rule["when"], fields)})
    if pending:
        return None, {"reason": "no-rule-matched-with-unknowns", "blocking_rules": pending, "trace": trace}
    return None, {"reason": "no-rule-matched", "trace": trace}


def missing_fields(clause, fields):
    out = []
    def walk(c):
        if isinstance(c, list):
            for x in c: walk(x)
        elif isinstance(c, dict):
            if "any" in c or "all" in c:
                for x in c.get("any", c.get("all")): walk(x)
            elif "not" in c:
                walk(c["not"])
            elif "derived" in c:
                out.append("~" + c["derived"])
            elif "field" in c:
                v = fields.get(c["field"])
                if v is None or v == "unclear":
                    out.append(c["field"])
    walk(clause)
    return sorted(set(out))


def classify(rules: dict, fields: dict, context: dict | None = None):
    context = context or {}
    verdict = {}
    for axis in ("type", "disposition"):
        val, why = decide(rules["axes"][axis], fields, context)
        verdict[axis] = val
        verdict[axis + "_trace"] = why
    own, why = owner_for(fields, context)
    verdict["owner"], verdict["owner_trace"] = own, why
    return verdict


# ---------- walidacja regul (petla naprawcza z przepisu) ----------

DERIVED = {"author_owns_layer", "layer_owned_by_us"}


def validate_rules(rules: dict, field_schema: dict) -> list:
    """Sprawdza, czy skompilowane reguly odwoluja sie WYLACZNIE do istniejacych pol
    i dozwolonych wartosci. Model potrafi wymyslic pole albo wartosc, ktorej nie ma
    w schemacie — bez tego checku silnik cicho zwracalby UNKNOWN na zawsze."""
    known = {f["name"]: set(f["values"]) for f in field_schema["fields"]}
    problems = []

    def walk(clause, rid):
        if isinstance(clause, list):
            for c in clause: walk(c, rid)
        elif isinstance(clause, dict):
            if "any" in clause or "all" in clause:
                for c in clause.get("any", clause.get("all")): walk(c, rid)
            elif "not" in clause:
                walk(clause["not"], rid)
            elif "derived" in clause:
                if clause["derived"] not in DERIVED:
                    problems.append(f"{rid}: nieistniejacy predykat wyprowadzony '{clause['derived']}'")
            elif "field" in clause:
                f = clause["field"]
                if f not in known:
                    problems.append(f"{rid}: nieistniejace pole '{f}'")
                    return
                vals = clause.get("in", clause.get("not_in", []))
                for v in vals:
                    if v not in known[f]:
                        problems.append(f"{rid}: pole '{f}' nie ma wartosci '{v}' "
                                        f"(dozwolone: {sorted(known[f])})")

    allowed = {"type": {"question", "bug", "design", "product", "note", "inspiration"},
               "disposition": {"do-now", "answer-close", "needs-decision", "defer",
                               "delight", "no-action"}}
    for axis, axis_rules in rules["axes"].items():
        seen = set()
        for r in axis_rules:
            if r["id"] in seen:
                problems.append(f"{r['id']}: zduplikowane id reguly")
            seen.add(r["id"])
            if r["then"] not in allowed[axis]:
                problems.append(f"{r['id']}: werdykt '{r['then']}' spoza osi {axis}")
            walk(r["when"], r["id"])
    return problems


if __name__ == "__main__":
    rules = json.loads(Path(sys.argv[1]).read_text())
    schema = json.loads(Path(sys.argv[2]).read_text())
    ctx_path = Path(sys.argv[5]) if len(sys.argv) > 5 else None
    context = json.loads(ctx_path.read_text()) if ctx_path else {}
    problems = validate_rules(rules, schema)
    if problems:
        print("REGULY NIEPOPRAWNE:")
        for p in problems:
            print("  -", p)
        sys.exit(1)
    print(f"reguly OK: typ {len(rules['axes']['type'])}, dyspozycja {len(rules['axes']['disposition'])}")
    if len(sys.argv) > 3:
        items = json.loads(Path(sys.argv[3]).read_text())
        out = []
        for i in items:
            f = dict(i["fields"]); f["_author"] = i.get("author")
            v = classify(rules, f, context)
            out.append(dict(id=i["id"], **{k: x for k, x in v.items() if not k.endswith("_trace")}))
        Path(sys.argv[4]).write_text(json.dumps(out, ensure_ascii=False, indent=2))
        print(f"sklasyfikowano {len(out)} -> {sys.argv[4]}")
