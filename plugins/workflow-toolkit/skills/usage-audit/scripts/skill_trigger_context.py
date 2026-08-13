#!/usr/bin/env python3
"""Dla każdego wywołania Skill(<target>) w transkryptach: znajdź ostatnią
wiadomość usera przed wywołaniem i wypisz snippet. Ocena trigger fidelity.
Użycie: skill_trigger_context.py <plugin:skill> [SINCE=YYYY-MM-DD] [UNTIL=YYYY-MM-DD] [roots...]
Bez SINCE: ostatnie 30 dni. UNTIL jest wyłączne (< UNTIL) i służy podziałowi
czasowemu na dev-set / held-out (patrz held-out-gate.md w skillu session-retro):
okno [stary..data-zmiany) to przykłady, na których zmiana powstała, a [data-zmiany..dziś]
to zbiór, którego nikt nie widział, gdy reguła była pisana."""
import json, sys, glob, os, datetime, re

target = sys.argv[1]  # np. workflow-toolkit:session-retro
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
# UNTIL nie może filtrować po mtime pliku: sesja dotknięta wczoraj zawiera zdarzenia
# z zeszłego miesiąca. Granica górna działa więc na timestampie ZDARZENIA, nie pliku.
until_date = args[0] if args and re.fullmatch(DATE, args[0]) else None
if until_date:
    args = args[1:]
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
                                    ts = e.get("timestamp", "?")
                                    # Filtr po dacie ZDARZENIA, nie tylko mtime pliku — inaczej
                                    # świeżo dotknięta stara sesja przecieka do obu kubełków
                                    # i podział czasowy przestaje być podziałem.
                                    day = ts[:10]
                                    if re.fullmatch(DATE, day):
                                        if day < since_date:
                                            continue
                                        if until_date and day >= until_date:
                                            continue
                                    rows.append((os.path.basename(os.path.dirname(f)), ts,
                                                 last_user[:180].replace("\n", " ")))
        except OSError:
            continue

for proj, ts, snip in sorted(rows, key=lambda r: r[1]):
    print(f"{ts} | {proj[-30:]} | {snip}")
window = f"{since_date}..{until_date or 'dziś'}"
print(f"\nTOTAL: {len(rows)} (okno {window})", file=sys.stderr)
