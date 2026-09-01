#!/usr/bin/env python3
"""Rozszerzenie skill_trigger_context.py: dla każdego wywołania Skill(<target>)
wypisuje PEŁNĄ ścieżkę .jsonl + draft (tekst asystenta między wywołaniem skilla
a następną wiadomością usera) — do ręcznej klasyfikacji per wymaganie (soczewka C),
której samo `skill_trigger_context.py` (tylko snippet promptu usera) nie umożliwia.

Użycie: skill_trigger_draft.py <plugin:skill> [SINCE=YYYY-MM-DD] [UNTIL=YYYY-MM-DD] [roots...]
Te same reguły okna co skill_trigger_context.py (UNTIL wyłączne, dev-set/held-out split).
"""
import json, sys, glob, os, datetime, re

target = sys.argv[1]
args = sys.argv[2:]
DATE = r"\d{4}-\d{2}-\d{2}"
if args and re.fullmatch(DATE, args[0]):
    since_date = args[0]
    cutoff = datetime.datetime.strptime(args[0], "%Y-%m-%d").timestamp()
    args = args[1:]
else:
    since = datetime.datetime.now() - datetime.timedelta(days=30)
    since_date = since.strftime("%Y-%m-%d")
    cutoff = since.timestamp()
until_date = args[0] if args and re.fullmatch(DATE, args[0]) else None
if until_date:
    args = args[1:]
roots = args or [os.path.expanduser("~/.claude/projects")]

def text_blocks(msg):
    c = msg.get("message", {}).get("content")
    if isinstance(c, str):
        return [c] if c.strip() else []
    if isinstance(c, list):
        return [b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text" and b.get("text", "").strip()]
    return []

def is_real_user_turn(e):
    if e.get("type") != "user" or e.get("isMeta"):
        return False
    c = e.get("message", {}).get("content")
    if isinstance(c, list):
        # tool_result-only user turns are not a real user prompt
        if all(isinstance(b, dict) and b.get("type") == "tool_result" for b in c):
            return False
    return True

results = []
for root in roots:
    for f in glob.glob(os.path.join(root, "**", "*.jsonl"), recursive=True):
        try:
            if os.path.getmtime(f) < cutoff:
                continue
        except OSError:
            continue
        try:
            with open(f, errors="replace") as fh:
                lines = fh.readlines()
        except OSError:
            continue
        events = []
        for line in lines:
            if not line.strip():
                continue
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                events.append(None)
        last_user = ""
        for i, e in enumerate(events):
            if e is None:
                continue
            if e.get("type") == "user" and not e.get("isMeta"):
                t = text_blocks(e)
                if t and not t[0].startswith("[{"):
                    last_user = " ".join(t).strip()
            elif e.get("type") == "assistant":
                for b in e.get("message", {}).get("content", []) or []:
                    if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") == "Skill":
                        if b.get("input", {}).get("skill") != target:
                            continue
                        ts = e.get("timestamp", "?")
                        day = ts[:10]
                        if re.fullmatch(DATE, day):
                            if day < since_date:
                                continue
                            if until_date and day >= until_date:
                                continue
                        draft_parts = []
                        for j in range(i + 1, len(events)):
                            ej = events[j]
                            if ej is None:
                                continue
                            if is_real_user_turn(ej):
                                break
                            if ej.get("type") == "assistant":
                                draft_parts.extend(text_blocks(ej))
                        draft = "\n".join(draft_parts).strip()
                        results.append({
                            "path": f,
                            "timestamp": ts,
                            "project": os.path.basename(os.path.dirname(f)),
                            "prompt": last_user[:300].replace("\n", " "),
                            "draft": draft,
                        })

results.sort(key=lambda r: r["timestamp"])
for r in results:
    print("=" * 100)
    print(f"TS: {r['timestamp']}")
    print(f"PROJECT: {r['project']}")
    print(f"PATH: {r['path']}")
    print(f"PROMPT: {r['prompt']}")
    print("--- DRAFT (tekst asystenta po wywołaniu skilla, do następnego promptu usera) ---")
    print(r["draft"][:6000])
    print()

window = f"{since_date}..{until_date or 'dziś'}"
print(f"TOTAL: {len(results)} (okno {window})", file=sys.stderr)
