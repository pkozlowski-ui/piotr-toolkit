#!/usr/bin/env python3
"""
Preflight przed publikacją artefaktu claude.ai. Deterministyczny gate PRZED wywołaniem
narzędzia Artifact (samego tool-calla nie da się skryptować — to weryfikuje wsad do niego).

Sprawdza, że plik jest self-contained pod strict CSP. FAIL (exit 1) gdy:
  - jest wrapper (<!doctype>/<html>/<head>/<body>) — Artifact dokłada własny,
  - są zewnętrzne referencje http(s) w src/href/url() (poza data:),
  - jest Google Fonts (fonts.googleapis.com / fonts.gstatic.com).
Info (nie blokuje): rozmiar pliku, liczba i łączny rozmiar data-URI base64, liczba <style>/<script>.

Użycie: preflight_artifact.py artifact.html
"""
import re
import sys

GF = ("fonts.googleapis.com", "fonts.gstatic.com")


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    path = sys.argv[1]
    with open(path, encoding="utf-8") as f:
        html = f.read()

    fails = []

    if re.search(r"<!doctype|<html[ >]|<head[ >]|<body[ >]", html, re.I):
        fails.append("wrapper (<!doctype/html/head/body) obecny — usuń, Artifact owija sam")

    refs = re.findall(r"""(?:src|href)\s*=\s*['"](https?://[^'"]+)['"]""", html, re.I)
    refs += re.findall(r"""url\(\s*['"]?(https?://[^'")]+)['"]?\s*\)""", html, re.I)
    ext = sorted({r for r in refs if not r.startswith("data:")})
    if ext:
        fails.append(f"{len(ext)} zewnętrznych referencji http(s) (CSP zablokuje): " + ", ".join(ext[:8]))

    if any(h in html for h in GF):
        fails.append("Google Fonts w pliku — zamień na inline @font-face base64")

    # info
    datauris = re.findall(r"data:[^;]+;base64,([A-Za-z0-9+/=]+)", html)
    b64_bytes = sum(len(d) for d in datauris)
    print(f"ℹ️  {path}: {len(html):,} B | "
          f"{len(re.findall(r'<style', html, re.I))} <style>, {len(re.findall(r'<script', html, re.I))} <script> | "
          f"{len(datauris)} data-URI base64 ({b64_bytes:,} B)")

    if fails:
        print(f"❌ PREFLIGHT FAIL ({len(fails)}):", file=sys.stderr)
        for x in fails:
            print(f"   - {x}", file=sys.stderr)
        return 1

    print("✅ PREFLIGHT OK — self-contained, gotowe do publikacji (Artifact, ten sam file_path = ten sam URL).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
