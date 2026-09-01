#!/usr/bin/env bash
# guard-send-invitation.sh — Stop. Blokuje odpowiedzi zapraszające do wysyłki
# ("czekam na Twoje «wyślij»", "powiedz «wyślij»", pytanie zamykające "wysłać?")
# zamiast pokazać draft i ZAMILKNĄĆ (CLAUDE.md → "Wysyłka na zewnątrz"; skill
# linear-ticket-draft → reguła 1/1a/1b/1c).
#
# Geneza: DWIE próby tekstowe w SKILL.md zawiodły — held-out `hipotezy-otwarte.md` (H3):
# fix v1 (2026-08-17) → ODRZUCONA (2/4 draftów łamało regułę), fix v2, dopisane 1a/1c
# (2026-08-26) → GORZEJ (5/9, 56%). Ta sama klasa awarii co v1/v2 `context-watch.sh`:
# tekst wstrzyknięty w kontekst nie jest deterministyczny — model go czasem nie przeczyta
# albo nie zastosuje w zajętej sesji. Ten hook egzekwuje deterministycznie, POZA pętlą
# modelu, zamiast pisać trzecią wersję tego samego zdania w SKILL.md.
#
# Reguła jest właściwie GLOBALNA (CLAUDE.md, nie tylko linear-ticket-draft), więc hook
# siedzi tutaj, nie w jednym SKILL.md — łapie każdy skill/kontekst, nie tylko drafty do Lineara.
#
# Kontrakt: fail-open na KAŻDY błąd parsowania/braku pola — blokujemy WYŁĄCZNIE na
# potwierdzone dopasowanie wzorca, nigdy przez awarię hooka.
# Uwaga: stdin (JSON hooka) łapiemy do env ZANIM heredoc zje fd 0 (wzorzec z context-watch.sh).
GSI_INPUT="$(cat 2>/dev/null || true)"
export GSI_INPUT
python3 - <<'PY'
import json, os, re, sys

try:
    data = json.loads(os.environ.get("GSI_INPUT", "") or "{}")
except Exception:
    sys.exit(0)

# Loop-guard: jeśli Stop hook już raz wymusił kontynuację w tej turze, nie blokuj drugi
# raz na tej samej odpowiedzi (pole może nie istnieć w każdej wersji Claude Code — wtedy
# domyślnie False i zachowanie jest identyczne jak bez tego guarda).
if data.get("stop_hook_active"):
    sys.exit(0)

msg = data.get("last_assistant_message") or ""
if not msg:
    sys.exit(0)

# Trzy warianty zmierzone w realnych sesjach (patrz hipotezy-otwarte.md → H3):
# 1. "czekam/czeka/poczekam na Twoje «wyślij»" (w dowolnym miejscu odpowiedzi)
# 2. "powiedz/potwierdź «wyślij»" (wariant sprzed fixu v1, na wszelki wypadek)
# 3. pytanie zamykające "wysłać?" (zakaz z globalnej reguły "Wysyłka na zewnątrz")
patterns = [
    r'(czek\w*|poczek\w*|zaczek\w*)[^\n.]{0,60}wy[śs]lij',
    r'(powiedz|potwierd\w*)[^\n.]{0,30}["„«]?\s*wy[śs]lij',
    r'wysła[ćc]\s*\?',
]
hit = None
for p in patterns:
    m = re.search(p, msg, re.IGNORECASE)
    if m:
        hit = m.group(0)
        break

if hit is None:
    sys.exit(0)

sys.stderr.write(
    "BLOK zaproszenia do wysyłki: odpowiedź zawiera formułę zapraszającą do wysyłki "
    f'(dopasowanie: "{hit}"). Reguła (CLAUDE.md "Wysyłka na zewnątrz" + skill '
    "linear-ticket-draft, reguła 1/1a/1b/1c): pokaż draft/artefakt i ZAMILKNIJ — nie "
    "zapraszaj formułą oczekiwania (\"czekam na wyślij\", \"powiedz wyślij\"), nie pytaj "
    "zamykająco (\"wysłać?\"), nie wystawiaj draftu jako pozycji w sekcji decyzji. User "
    "inicjuje wysyłkę sam, nieproszony. Przepisz odpowiedź usuwając TĘ formułę z całej "
    "treści (proza, sekcja decyzji, podpis) — jeśli nic innego nie wymaga decyzji, skończ "
    "na pokazaniu draftu bez pytania. Pytanie o kanał (komentarz/description) pada "
    "WYŁĄCZNIE PO tym, jak user sam napisze \"wyślij\" w kolejnej wiadomości, nigdy przed."
)
sys.exit(2)
PY
