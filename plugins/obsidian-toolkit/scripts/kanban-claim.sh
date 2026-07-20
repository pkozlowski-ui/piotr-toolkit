#!/usr/bin/env bash
# kanban-claim.sh — atomowy mutex na karty KANBAN (współbieżne sesje na tej samej maszynie).
#
# Problem: dwie sesje biorą tę samą kartę → duplikat pracy. Frontmatter `claimed:` jest
# nieatomowy (read-then-write race) i pomijalny. Ten skrypt daje PRAWDZIWY zamek:
# katalog-lock zakładany przez `mkdir` (operacja atomowa na POSIX — druga sesja dostaje błąd,
# nie „obie widzą wolne"). Frontmatter `claimed:` zostaje jako czytelne lustro dla człowieka.
#
# Lock żyje w <kanban>/.claims/<slug>/ (gitignored — stan lokalny maszyny). Meta w środku:
# session=…, epoch=…, note=…, at=…
#
# Użycie:
#   kanban-claim.sh claim   <kanban_dir> <card_slug> <session_id> [note]
#   kanban-claim.sh release <kanban_dir> <card_slug> <session_id>
#   kanban-claim.sh check   <kanban_dir> <card_slug>
#   kanban-claim.sh steal   <kanban_dir> <card_slug> <session_id> [note]   # jawne przejęcie
#
# Exit:
#   0  OK (zamek Twój — świeżo wzięty, odświeżony, zwolniony, lub check=wolny)
#   3  ZAJĘTE przez inną, ŻYWĄ sesję (świeży lock) — NIE bierz karty
#   4  ZAJĘTE przez inną sesję, ale lock STARY (>próg) — pokaż userowi, pytaj o przejęcie
#   2  błąd użycia
#
# Próg wygaśnięcia locka (sekundy) — po nim claim zwraca 4 (stale), nie 3 (blocked):
STALE_SECS="${KANBAN_CLAIM_STALE:-172800}"   # 2 dni
set -uo pipefail

cmd="${1:-}"; kdir="${2:-}"; raw="${3:-}"; sid="${4:-}"; note="${5:-}"
[ -z "$cmd" ] && { echo "usage: kanban-claim.sh {claim|release|check|steal} <kanban_dir> <card_slug> [session] [note]" >&2; exit 2; }
[ -d "$kdir" ] || { echo "kanban_dir nie istnieje: $kdir" >&2; exit 2; }

# slug = nazwa karty bez .md, znaki spoza [A-Za-z0-9._-] → _
slug="$(printf '%s' "$raw" | sed -E 's/\.md$//; s/[^A-Za-z0-9._-]+/_/g')"
[ -z "$slug" ] && { echo "pusty slug" >&2; exit 2; }

claims="$kdir/.claims"
lock="$claims/$slug"
meta="$lock/meta"
now="$(date +%s)"

_read_meta() {  # ustawia M_session M_epoch M_note M_at; 0 jeśli meta jest
  M_session=""; M_epoch=0; M_note=""; M_at=""
  [ -f "$meta" ] || return 1
  while IFS='=' read -r k v; do
    case "$k" in
      session) M_session="$v" ;;
      epoch)   M_epoch="$v" ;;
      note)    M_note="$v" ;;
      at)      M_at="$v" ;;
    esac
  done < "$meta"
  return 0
}

_write_meta() {
  { printf 'session=%s\n' "$sid"
    printf 'epoch=%s\n' "$now"
    printf 'note=%s\n' "$note"
    printf 'at=%s\n' "$(date '+%Y-%m-%d %H:%M')"
  } > "$meta"
}

case "$cmd" in
  claim)
    [ -z "$sid" ] && { echo "brak session_id" >&2; exit 2; }
    mkdir -p "$claims" 2>/dev/null
    if mkdir "$lock" 2>/dev/null; then
      # wygrana — atomowo zajęte
      _write_meta
      echo "CLAIMED $slug (session $sid)"
      exit 0
    fi
    # lock istnieje — czyj?
    if _read_meta; then
      if [ "$M_session" = "$sid" ]; then
        _write_meta   # odśwież epoch (heartbeat)
        echo "OWN $slug (odświeżony)"
        exit 0
      fi
      age=$(( now - M_epoch ))
      if [ "$age" -gt "$STALE_SECS" ]; then
        echo "STALE $slug — trzyma sesja '$M_session' od '$M_at' ($((age/3600))h temu). Pokaż userowi, pytaj o przejęcie (steal)."
        exit 4
      fi
      echo "TAKEN $slug — trzyma sesja '$M_session' od '$M_at' (note: $M_note). NIE bierz tej karty."
      exit 3
    fi
    # lock bez meta (wyścig w trakcie pisania) — traktuj jako zajęte świeżo
    echo "TAKEN $slug — lock bez meta (inna sesja właśnie zakłada). NIE bierz."
    exit 3
    ;;
  release)
    [ -d "$lock" ] || { echo "FREE $slug (nic do zwolnienia)"; exit 0; }
    if _read_meta && [ -n "$sid" ] && [ "$M_session" != "$sid" ]; then
      echo "SKIP release $slug — lock należy do '$M_session', nie do '$sid'. Nie zwalniam cudzego."
      exit 0
    fi
    rm -rf "$lock"
    echo "RELEASED $slug"
    exit 0
    ;;
  steal)
    [ -z "$sid" ] && { echo "brak session_id" >&2; exit 2; }
    mkdir -p "$claims" 2>/dev/null
    rm -rf "$lock"
    mkdir "$lock" 2>/dev/null || { echo "nie mogę założyć locka po steal" >&2; exit 2; }
    _write_meta
    echo "STOLEN $slug (session $sid)"
    exit 0
    ;;
  check)
    if _read_meta; then
      age=$(( now - M_epoch ))
      echo "TAKEN $slug — sesja '$M_session' od '$M_at' ($((age/3600))h; note: $M_note)"
      [ "$age" -gt "$STALE_SECS" ] && echo "(STALE — starszy niż próg)"
      exit 3
    fi
    echo "FREE $slug"
    exit 0
    ;;
  *)
    echo "nieznana komenda: $cmd" >&2; exit 2 ;;
esac
