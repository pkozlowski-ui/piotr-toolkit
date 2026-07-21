#!/usr/bin/env bash
# kanban-archive.sh — auto-archiwum kart Done po N dniach (nieniszczące, idempotentne).
#
# Cel: kolumna Done nie puchnie. Karta domknięta jako Done starzeje się N dni (domyślnie 30),
# potem ląduje w podfolderze archiwum boardu — wypada z tablicy (board filtruje po DOKŁADNYM
# folderze `file.folder == "<board>"`), ale notatka żyje. Zasada: archiwizuj, nie kasuj.
#
# Działanie (dla każdego *.md w <kanban_dir>, tylko top-level — Archive/ i .claims/ pominięte):
#   status: Done + brak `done_at`      → stempluje `done_at: <dziś>` (rusza zegar; NIE archiwizuje)
#   status: Done + `done_at` > N dni   → `mv` do <kanban_dir>/<ARCHIVE_DIR>/
#   status: Done + `done_at` ≤ N dni   → zostawia (jeszcze świeża)
#   inny status / brak frontmattera    → pomija
#
# Nieniszczące: jedyne mutacje to `mv` pliku i wstawienie linii `done_at`. Idempotentne —
# bezpieczne do codziennego runu z cron/launchd.
#
# Użycie:
#   kanban-archive.sh <kanban_dir> [dni]
#   KANBAN_ARCHIVE_DRYRUN=1 kanban-archive.sh <kanban_dir> [dni]   # tylko raport, zero zmian
#
# Env:
#   KANBAN_ARCHIVE_DIR   nazwa podfolderu archiwum (domyślnie "Archive")
#   KANBAN_ARCHIVE_DRYRUN=1   dry-run (nic nie zapisuje/przenosi)
#
# Exit: 0 OK · 2 błąd użycia
#
# --- Setup crona na macOS (launchd — przeżywa reboot, nie wymaga otwartego terminala) ---
#   Utwórz ~/Library/LaunchAgents/com.piotr.kanban-archive.plist z ProgramArguments:
#     [ "/bin/bash",
#       "/Users/piotrkozlowski/Documents/piotr-toolkit/plugins/obsidian-toolkit/scripts/kanban-archive.sh",
#       "/Users/piotrkozlowski/Documents/Manta Vault/KANBAN" ]
#   + StartCalendarInterval (Hour 9, Minute 0) → codziennie 9:00.
#   Załaduj: launchctl load ~/Library/LaunchAgents/com.piotr.kanban-archive.plist
#   (Alternatywa: wpis w `crontab -e`:  0 9 * * *  /bin/bash <ścieżka skryptu> "<kanban_dir>")
#   Weryfikacja przed podpięciem: KANBAN_ARCHIVE_DRYRUN=1 kanban-archive.sh "<kanban_dir>"
set -uo pipefail

kdir="${1:-}"
days="${2:-30}"
archive_name="${KANBAN_ARCHIVE_DIR:-Archive}"
dry="${KANBAN_ARCHIVE_DRYRUN:-0}"

[ -z "$kdir" ] && { echo "usage: kanban-archive.sh <kanban_dir> [dni]" >&2; exit 2; }
[ -d "$kdir" ] || { echo "kanban_dir nie istnieje: $kdir" >&2; exit 2; }
case "$days" in ''|*[!0-9]*) echo "dni musi być liczbą: $days" >&2; exit 2;; esac

archive_dir="$kdir/$archive_name"
today="$(date +%Y-%m-%d)"
now_epoch="$(date +%s)"
max_age=$(( days * 86400 ))

# Parsuj YYYY-MM-DD → epoch. macOS = BSD date (-j -f); Linux fallback = GNU date (-d).
to_epoch() {
  local d="$1" e
  e="$(date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null)" || e="$(date -d "$d" +%s 2>/dev/null)" || return 1
  printf '%s' "$e"
}

# Odczytaj wartość klucza z bloku frontmattera (pierwszy blok --- … ---). Pusto = brak.
fm_get() {
  awk -v key="$1" '
    NR==1 && $0!="---" { exit }
    NR==1 { infm=1; next }
    infm && $0=="---" { exit }
    infm {
      # dopasuj "key:" na początku linii
      if (index($0, key ":") == 1) {
        v=$0; sub(/^[^:]+:[ \t]*/, "", v)
        gsub(/^["'"'"' \t]+|["'"'"' \t]+$/, "", v)  # obetnij cudzysłowy/spacje
        print v; exit
      }
    }
  ' "$2"
}

stamped=0 archived=0 skipped_fresh=0 scanned=0

shopt -s nullglob
for f in "$kdir"/*.md; do
  scanned=$((scanned+1))
  status="$(fm_get status "$f")"
  [ "$status" = "Done" ] || continue

  done_at="$(fm_get done_at "$f")"

  # Brak done_at → stempluj dzisiejszą datą (rusza zegar), NIE archiwizuj.
  if [ -z "$done_at" ]; then
    if [ "$dry" = "1" ]; then
      echo "STAMP  (dry) $today  $(basename "$f")"
    else
      # wstaw `done_at: <dziś>` tuż po linii `status:` w bloku frontmattera
      tmp="$(mktemp)"
      awk -v d="$today" '
        NR==1 && $0=="---" { print; infm=1; next }
        infm && index($0,"status:")==1 { print; print "done_at: " d; done=1; next }
        infm && $0=="---" && !placed { if(!done){print "done_at: " d}; placed=1; infm=0; print; next }
        { print }
      ' "$f" > "$tmp" && mv "$tmp" "$f"
      echo "STAMP  $today  $(basename "$f")"
    fi
    stamped=$((stamped+1))
    continue
  fi

  # Mamy done_at → policz wiek.
  d_epoch="$(to_epoch "$done_at")" || { echo "WARN   niepoprawny done_at='$done_at' → pomijam  $(basename "$f")" >&2; continue; }
  age=$(( now_epoch - d_epoch ))

  if [ "$age" -gt "$max_age" ]; then
    if [ "$dry" = "1" ]; then
      echo "ARCHIVE (dry) done_at=$done_at  $(basename "$f")"
    else
      mkdir -p "$archive_dir"
      dest="$archive_dir/$(basename "$f")"
      if [ -e "$dest" ]; then
        echo "WARN   cel istnieje, pomijam by nie nadpisać: $dest" >&2
        continue
      fi
      mv "$f" "$dest"
      echo "ARCHIVE done_at=$done_at  $(basename "$f")"
    fi
    archived=$((archived+1))
  else
    skipped_fresh=$((skipped_fresh+1))
  fi
done

echo "---"
dry_note=""; [ "$dry" = "1" ] && dry_note=" · TRYB: dry-run"
echo "skan: $scanned .md · zestemplowane(done_at): $stamped · zarchiwizowane: $archived · świeże(≤${days}d): $skipped_fresh${dry_note}"
[ "$dry" = "1" ] && echo "(dry-run — nic nie zapisano ani nie przeniesiono)"
exit 0
