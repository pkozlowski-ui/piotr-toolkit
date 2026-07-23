#!/usr/bin/env python3
"""
CSP transform: index.html (dev, pełny dokument HTML) -> artifact.html (treść pod claude.ai Artifact).

Narzędzie Artifact owija plik w <!doctype html><head></head><body> przy publikacji,
więc artifact.html ma zawierać WYŁĄCZNIE treść strony: bloki <style> + wnętrze <body>
(markup + inline <script>). Bez wrappera <!DOCTYPE>/<html>/<head>/<body>.

claude.ai Artifacts ma strict CSP: zero external hostów (Google Fonts, CDN skrypty,
zdalne obrazy/fonty). Ten skrypt:
  - wyciąga każdy <style>...</style> z dokumentu,
  - wyciąga wnętrze <body> (markup + inline <script>),
  - usuwa Google-Fonts <link>/@import (blokowane przez CSP),
  - opcjonalnie wstrzykuje inline blok @font-face (base64 woff2) z --fonts FILE,
  - ostrzega o pozostałych zewnętrznych referencjach http(s) (i tak zostaną zablokowane).

Użycie:
  csp_transform.py IN.html -o OUT.html [--fonts fontface_block.html]

--fonts to plik zawierający gotowy <style>@font-face{...base64...}</style> (skopiowany
z istniejącego artifact.html DS-a). Font jest częścią configu DS, nie engine'u — patrz
references/ds-config.md.
"""
import argparse
import re
import sys

GF_HOSTS = ("fonts.googleapis.com", "fonts.gstatic.com")


def extract_styles(src: str) -> str:
    blocks = re.findall(r"<style[^>]*>.*?</style>", src, re.S | re.I)
    out = []
    for b in blocks:
        # usuń @import Google Fonts wewnątrz <style>
        b = re.sub(r"@import\s+url\([^)]*fonts\.(?:googleapis|gstatic)\.com[^)]*\)\s*;?", "", b, flags=re.I)
        out.append(b)
    return "\n".join(out)


def extract_body_inner(src: str) -> str:
    m = re.search(r"<body[^>]*>(.*)</body>", src, re.S | re.I)
    if not m:
        # brak <body> — potraktuj cały plik jako treść (już może być fragmentem)
        return src.strip()
    inner = m.group(1)
    # usuń ewentualne <link ... google fonts> zabłąkane w body
    inner = re.sub(r"<link[^>]*fonts\.(?:googleapis|gstatic)\.com[^>]*>", "", inner, flags=re.I)
    return inner.strip()


def warn_external(text: str) -> None:
    # zewnętrzne referencje (poza data:) — CSP je zablokuje
    refs = re.findall(r"""(?:src|href)\s*=\s*['"](https?://[^'"]+)['"]""", text, re.I)
    refs += re.findall(r"""url\(\s*['"]?(https?://[^'")]+)['"]?\s*\)""", text, re.I)
    ext = [r for r in refs if not r.startswith("data:")]
    if ext:
        print(f"⚠️  {len(ext)} zewnętrznych referencji http(s) — CSP artefaktu je ZABLOKUJE:", file=sys.stderr)
        for r in sorted(set(ext))[:20]:
            flag = "  ← Google Fonts" if any(h in r for h in GF_HOSTS) else ""
            print(f"    {r}{flag}", file=sys.stderr)
        print("    → zinline'uj (data-URI / @font-face base64) albo usuń.", file=sys.stderr)


def main() -> int:
    ap = argparse.ArgumentParser(description="index.html -> artifact.html (CSP self-contained)")
    ap.add_argument("input")
    ap.add_argument("-o", "--output", required=True)
    ap.add_argument("--fonts", help="plik z inline blokiem <style>@font-face base64</style>")
    args = ap.parse_args()

    with open(args.input, encoding="utf-8") as f:
        src = f.read()

    parts = []
    if args.fonts:
        with open(args.fonts, encoding="utf-8") as f:
            fonts = f.read().strip()
        parts.append(fonts)
        if any(h in fonts for h in GF_HOSTS):
            print("⚠️  --fonts zawiera odwołanie do Google Fonts — powinien być inline base64.", file=sys.stderr)

    styles = extract_styles(src)
    if styles:
        parts.append(styles)

    body = extract_body_inner(src)
    parts.append(body)

    out = "\n\n".join(p for p in parts if p) + "\n"

    # ostrzeżenia CSP na finalnej treści
    if any(h in out for h in GF_HOSTS):
        print("⚠️  W wyjściu wciąż jest Google Fonts — dodaj --fonts z inline @font-face base64.", file=sys.stderr)
    warn_external(out)

    # wrapper-guard: artifact.html NIE może mieć wrappera (Artifact dokłada własny)
    if re.search(r"<!doctype|<html[ >]|<head[ >]|<body[ >]", out, re.I):
        print("⚠️  W wyjściu jest tag wrappera (<!doctype/html/head/body) — usuń, Artifact owija sam.", file=sys.stderr)

    with open(args.output, "w", encoding="utf-8") as f:
        f.write(out)

    print(f"✅ {args.input} -> {args.output}  ({len(out):,} B, {len(re.findall(r'<style', out, re.I))} <style>, "
          f"{len(re.findall(r'<script', out, re.I))} <script>)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
