#!/usr/bin/env bash
# context-watch.sh — UserPromptSubmit. Deterministyczny strażnik kosztu sesji:
# 1) kontekst > próg → każe Claude'owi zaproponować domknięcie + wygenerować chip nowej
#    sesji (mcp__ccd_session__spawn_task) z samowystarczalnym promptem kontynuacji,
# 2) nowy model Claude w sesji → każe zaproponować onboarding research (karta kanban).
# Geneza: audyt tokenów 2026-08-04 — 60% zużycia limitu = cache-read maratońskich sesji
# (450–800 req przy 350–517k kontekstu). Progi = HIPOTEZA (200k / eskalacja co 75k),
# walidacja: audyt tokenów za ~2 tyg. (baseline: śr. 246k ctx/request, Haiku 0,14%).
# Kontrakt: exit 0 zawsze, cicho przy błędach — hook nie może blokować sesji.
# Uwaga: stdin (JSON hooka) łapiemy do env ZANIM heredoc zje fd 0.
CW_INPUT="$(cat 2>/dev/null || true)"
export CW_INPUT
python3 - <<'PY' 2>/dev/null || true
import json, sys, os

try:
    data = json.loads(os.environ.get("CW_INPUT", ""))
except Exception:
    sys.exit(0)
tp = data.get("transcript_path") or ""
sid = (data.get("session_id") or "unknown")[:36]
if not tp or not os.path.exists(tp):
    sys.exit(0)

# ostatnie usage z ogona transkryptu (nigdy nie czytamy całego pliku)
try:
    size = os.path.getsize(tp)
    with open(tp, "rb") as f:
        f.seek(max(0, size - 300_000))
        tail = f.read().decode("utf-8", "replace")
except Exception:
    sys.exit(0)

ctx = 0
model = ""
for line in reversed(tail.splitlines()):
    if '"usage"' not in line:
        continue
    try:
        d = json.loads(line)
        msg = d.get("message") or {}
        u = msg.get("usage") or {}
        if not u:
            continue
        ctx = (u.get("input_tokens") or 0) + (u.get("cache_read_input_tokens") or 0) \
            + (u.get("cache_creation_input_tokens") or 0)
        model = msg.get("model") or ""
        break
    except Exception:
        continue

state = os.path.expanduser("~/.claude/state")
os.makedirs(state, exist_ok=True)
msgs = []

# --- 1) próg kontekstu (hipoteza: 200k, eskalacja co 75k; hysteresis per sesja) ---
TH, STEP = 200_000, 75_000
if ctx >= TH:
    lvl = (ctx - TH) // STEP
    sf = os.path.join(state, f"ctxwatch-{sid}")
    prev = -1
    try:
        prev = int(open(sf).read().strip())
    except Exception:
        pass
    if lvl > prev:
        try:
            open(sf, "w").write(str(lvl))
        except Exception:
            pass
        msgs.append(
            f"[context-watch] Kontekst sesji ~{ctx // 1000}k tokenów (próg 200k). "
            "Po domknięciu bieżącego kroku: (1) zaproponuj Piotrowi domknięcie i /clear, "
            "(2) jeśli dostępne narzędzie mcp__ccd_session__spawn_task — utwórz chip "
            "'Kontynuacja: <task>' z SAMOWYSTARCZALNYM promptem (repo/branch, stan, dokładny "
            "następny krok); jeśli niedostępne — podaj gotowy prompt kontynuacji w czacie. "
            "Każdy request w tym kontekście zużywa wielokrotnie więcej limitu niż w świeżej sesji."
        )

# --- 2) nowy model Claude → onboarding research ---
if model.startswith("claude-"):
    seen = os.path.join(state, "seen-models.txt")
    known = set()
    try:
        known = set(open(seen).read().split())
    except Exception:
        pass
    if model not in known:
        try:
            with open(seen, "a") as f:
                f.write(model + "\n")
        except Exception:
            pass
        msgs.append(
            f"[model-watch] Pierwszy raz widzę model: {model}. Zaproponuj Piotrowi onboarding "
            "research (skill web-research: prompting guide, migracja, pricing/limity, nowe "
            f"możliwości) i utwórz kartę kanban 'Model onboarding — {model}' (status: To-do). "
            "Sam research dopiero po jego potwierdzeniu."
        )

if msgs:
    print("\n".join(msgs))
PY
# sprzątanie starych plików hysteresis (>7 dni), cicho
find "$HOME/.claude/state" -name 'ctxwatch-*' -mtime +7 -delete 2>/dev/null || true
exit 0
