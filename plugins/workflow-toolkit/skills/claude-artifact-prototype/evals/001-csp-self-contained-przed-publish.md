---
id: claude-artifact-prototype-001
skill: claude-artifact-prototype
źródło: sesja Persona 2 CMO (2026-07-23) — artefakt claude.ai ma strict CSP; Google Fonts i zewnętrzne assety cicho znikają, wrapper html/head/body łamie publikację. Powtarzalny koszt każdego artefaktu.
status: aktywny
---

# Plik publikowany jako Artifact jest self-contained pod strict CSP (bez wrappera, bez external, bez Google Fonts)

**Scenariusz (input):** Prototyp gotowy jako dev `index.html` (pełny dokument: wrapper
`<!DOCTYPE>/<html>/<head>/<body>`, `<link>` Google Fonts, ewentualnie zewnętrzny obraz/skrypt).
Zadanie zmierza do publikacji jako claude.ai Artifact.

**Pass:** Przed wywołaniem narzędzia Artifact powstaje `artifact.html`, który:
- NIE ma wrappera `<!DOCTYPE>/<html>/<head>/<body>` (Artifact owija własnym skeletonem),
- NIE ma zewnętrznych referencji http(s) (Google Fonts, CDN, zdalne obrazy) — font jako inline
  `@font-face` base64, assety jako `data:` URI,
- przechodzi `preflight_artifact.py artifact.html` (exit 0).
Duże assety (>~15KB base64) wstawione **skryptem** (`embed_base64.py`, placeholder / `@plik`),
nie ręcznym pastem ani full-file Write.

**Fail wygląda tak:** Publikacja `index.html` z wrapperem i/lub `<link>` Google Fonts →
w artefakcie font nie ładuje się (CSP blokuje), obrazy z URL puste, a wrappery html/head/body
psują render. Albo: awatar wklejony ręcznie / przez Write → base64 ucięty, obraz zepsuty.

**Jak sprawdzić:** Na dev `index.html` przejdź workflow skilla i odpal
`preflight_artifact.py artifact.html` — musi dać exit 0 i zero pozycji FAIL. Porównaj: publikacja
surowego `index.html` failuje preflight (wrapper + Google Fonts).
