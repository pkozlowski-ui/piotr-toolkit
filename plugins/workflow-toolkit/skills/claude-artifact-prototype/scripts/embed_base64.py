#!/usr/bin/env python3
"""
Base64-safe embed. Podmienia placeholdery w pliku HTML na data-URI zbudowane z assetów
na dysku — BEZ wklejania dużego base64 przez model.

Dlaczego skrypt, a nie ręczny paste / full-file Write: Write ucina base64 >~15-20KB
(awatar/mp3), a ręczny paste tym bardziej. Ten skrypt czyta bajty assetu, koduje base64
i wstawia data-URI bezpośrednio — string nigdy nie przechodzi przez kontekst modelu.

Workflow: w HTML zostaw placeholder (rekomendacja: __NAZWA__), np.
  <img src="__AVATAR__">   albo   var SND={greet:"__SND_GREET__"};
potem odpal ten skrypt, by podmienić każdy placeholder na data:...;base64,...

Użycie:
  embed_base64.py FILE.html __AVATAR__=avatar.png [__LOGO__=logo.svg:image/svg+xml] ...
  embed_base64.py FILE.html __AVATAR__=@avatar.datauri            # gotowy data-URI z pliku

Dwa tryby wartości:
  ścieżka do assetu   -> skrypt koduje base64 i buduje data:<mime>;base64,...
  @ścieżka            -> wstawia ZAWARTOŚĆ pliku verbatim (np. .datauri z figma_asset_extract.sh);
                         nic nie koduje ponownie, string nie przechodzi przez argv/kontekst modelu.

MIME wykrywany z rozszerzenia; nadpisz przez ':mime' po ścieżce (tryb kodowania).
Podmiana jest in-place (nadpisuje FILE.html). Placeholder musi istnieć w pliku.
"""
import base64
import sys

MIME = {
    ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
    ".webp": "image/webp", ".gif": "image/gif", ".svg": "image/svg+xml",
    ".mp3": "audio/mpeg", ".wav": "audio/wav", ".m4a": "audio/mp4",
    ".woff2": "font/woff2", ".woff": "font/woff",
}


def datauri(path: str, mime: str | None) -> str:
    if mime is None:
        ext = "." + path.rsplit(".", 1)[-1].lower() if "." in path else ""
        mime = MIME.get(ext)
        if mime is None:
            print(f"❌ nieznany MIME dla {path} — podaj jawnie ':mime'", file=sys.stderr)
            sys.exit(2)
    with open(path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode("ascii")
    return f"data:{mime};base64,{b64}"


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    html_path = sys.argv[1]
    pairs = sys.argv[2:]

    with open(html_path, encoding="utf-8") as f:
        html = f.read()

    for pair in pairs:
        if "=" not in pair:
            print(f"❌ zły argument (brak '='): {pair}", file=sys.stderr)
            return 2
        placeholder, rhs = pair.split("=", 1)
        if placeholder not in html:
            print(f"❌ placeholder nieobecny w {html_path}: {placeholder}", file=sys.stderr)
            return 1
        if rhs.startswith("@"):
            # gotowy string (np. .datauri) — wstaw verbatim, nie koduj ponownie
            src_label = rhs
            with open(rhs[1:], encoding="utf-8") as f:
                uri = f.read().strip()
        else:
            # rozdziel ścieżkę od opcjonalnego :mime (ostrożnie: ścieżka może mieć ':')
            mime = None
            asset = rhs
            if ":" in rhs and rhs.rsplit(":", 1)[1].count("/") == 1 and not rhs.rsplit(":", 1)[1].startswith("/"):
                asset, mime = rhs.rsplit(":", 1)
            src_label = asset
            uri = datauri(asset, mime)
        n = html.count(placeholder)
        html = html.replace(placeholder, uri)
        print(f"✅ {placeholder} × {n}  ←  {src_label}  ({len(uri):,} B data-URI)")

    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"✅ zapisano {html_path} ({len(html):,} B)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
