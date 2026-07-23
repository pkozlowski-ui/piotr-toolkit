#!/usr/bin/env bash
# Ekstrakcja assetu z Figmy, która DZIAŁA — omija timeout 5s pluginu przy figma_execute exportAsync.
#
# KROK 1 (model, MCP — NIE ten skrypt): wywołaj get_design_context(nodeId). Zwraca URL assetu:
#     http://localhost:3845/assets/<uuid>            (Figma Dev Mode, lokalny serwer)
#     https://www.figma.com/api/mcp/asset/<uuid>     (hostowany, TTL ~7 dni)
# KROK 2 (ten skrypt, deterministyczny): curl -> sips (resize rastra) -> base64 -> data-URI.
#
# Użycie:
#   figma_asset_extract.sh <ASSET_URL> <OUT_BASENAME> [MAX_PX]
#     ASSET_URL     — URL z get_design_context
#     OUT_BASENAME  — bazowa nazwa plików wyjściowych (bez rozszerzenia)
#     MAX_PX        — opcjonalny longest-edge downscale rastra (sips -Z); pomiń dla SVG
#
# Wynik: <OUT_BASENAME>.datauri (jedna linia: data:<mime>;base64,<...>) — wstaw przez embed_base64.py.
set -euo pipefail

if [ "$#" -lt 2 ]; then
  grep '^#' "$0" | sed 's/^# \{0,1\}//'
  exit 2
fi

URL="$1"
OUT="$2"
MAX_PX="${3:-}"

TMP="$(mktemp -t figasset).bin"
trap 'rm -f "$TMP"' EXIT

# pobierz + przechwyć content-type
CT="$(curl -fsSL -D - "$URL" -o "$TMP" 2>/dev/null | tr -d '\r' | awk -F': ' 'tolower($1)=="content-type"{print tolower($2); exit}')"
[ -s "$TMP" ] || { echo "❌ pusty pobór z $URL (URL wygasł? Dev Mode serwer nie działa?)" >&2; exit 1; }

# ustal MIME / rozszerzenie
case "$CT" in
  *svg*)  MIME="image/svg+xml"; EXT="svg" ;;
  *png*)  MIME="image/png";     EXT="png" ;;
  *jpeg*|*jpg*) MIME="image/jpeg"; EXT="jpg" ;;
  *webp*) MIME="image/webp";    EXT="webp" ;;
  *)
    # fallback: sniff po nagłówku bajtów
    if head -c 5 "$TMP" | grep -qi "<svg\|<?xml"; then MIME="image/svg+xml"; EXT="svg"
    elif head -c 8 "$TMP" | grep -qa "PNG"; then MIME="image/png"; EXT="png"
    else MIME="image/png"; EXT="png"; fi ;;
esac

# resize tylko dla rastra i tylko gdy podano MAX_PX
if [ -n "$MAX_PX" ] && [ "$EXT" != "svg" ]; then
  sips -Z "$MAX_PX" "$TMP" --out "$TMP" >/dev/null 2>&1 || echo "⚠️  sips resize nie powiódł się — koduję oryginał" >&2
fi

B64="$(base64 -i "$TMP" | tr -d '\n')"
printf 'data:%s;base64,%s' "$MIME" "$B64" > "${OUT}.datauri"

BYTES=$(wc -c < "${OUT}.datauri" | tr -d ' ')
echo "✅ ${URL}"
echo "   -> ${OUT}.datauri  (${MIME}, ${BYTES} B data-URI${MAX_PX:+, ≤${MAX_PX}px})"
echo "   wstaw: embed_base64.py FILE.html __PLACEHOLDER__=@${OUT}.datauri   # @ = z pliku, base64 nie wraca do kontekstu"
