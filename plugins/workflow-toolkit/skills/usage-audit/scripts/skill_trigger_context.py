#!/usr/bin/env python3
"""Dla każdego wywołania Skill(<target>) w transkryptach: znajdź ostatnią
wiadomość usera przed wywołaniem i wypisz snippet. Ocena trigger fidelity.
Użycie: skill_trigger_context.py <plugin:skill> [SINCE=YYYY-MM-DD] [roots...]
Bez SINCE: ostatnie 30 dni."""
import json, sys, glob, os, datetime, re

target = sys.argv[1]  # np. workflow-toolkit:session-retro
args = sys.argv[2:]
if args and re.fullmatch(r"\d{4}-\d{2}-\d{2}", args[0]):
    cutoff = datetime.datetime.strptime(args[0], "%Y-%m-%d").timestamp()
    args = args[1:]
else:
    cutoff = (datetime.datetime.now() - datetime.timedelta(days=30)).timestamp()
roots = args or [os.path.expanduser("~/.claude/projects")]

def user_text(msg):
    c = msg.get("message", {}).get("content")
    if isinstance(c, str):
        return c
    if isinstance(c, list):
        parts = [b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text"]
        return " ".join(parts)
    return ""

rows = []
for root in roots:
    for f in glob.glob(os.path.join(root, "**", "*.jsonl"), recursive=True):
        try:
            if os.path.getmtime(f) < cutoff:
                continue
        except OSError:
            continue
        last_user = ""
        try:
            with open(f, errors="replace") as fh:
                for line in fh:
                    if '"skill"' not in line and '"type":"user"' not in line and '"role":"user"' not in line:
                        continue
                    try:
                        e = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    if e.get("type") == "user" and not e.get("isMeta"):
                        t = user_text(e).strip()
                        if t and not t.startswith("[{"):
                            last_user = t
                    elif e.get("type") == "assistant":
                        for b in e.get("message", {}).get("content", []) or []:
                            if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") == "Skill":
                                if b.get("input", {}).get("skill") == target:
                                    rows.append((os.path.basename(os.path.dirname(f)), e.get("timestamp", "?"),
                                                 last_user[:180].replace("\n", " ")))
        except OSError:
            continue

for proj, ts, snip in rows:
    print(f"{ts} | {proj[-30:]} | {snip}")
print(f"\nTOTAL: {len(rows)}", file=sys.stderr)
