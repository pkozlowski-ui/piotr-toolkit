# DS config — kształt (engine ↔ config)

Engine (SKILL.md + skrypty) jest **generyczny**. Wszystko projekto-/klientowo-specyficzne
żyje w **configu DS**, który podajesz przy budowie — **poza tym repo** (pamięć projektu lub
repo projektu). Do publicznego toolkitu **nie trafiają** tokeny, hex-e, node-id ani nazwy klienta.

Config to nie plik w tym skillu — to zestaw wartości, które musisz mieć pod ręką dla danego DS.
Poniżej co engine potrzebuje i jak to spina się ze skryptami.

## Co config musi dostarczyć

| Element | Do czego (który krok) | Forma |
|---|---|---|
| **Font — inline @font-face base64** | `csp_transform.py --fonts <plik>` | plik `<style>@font-face{...base64 woff2...}</style>`; jeden `latin` woff2 zwykle pokrywa wszystkie wagi. Najprościej skopiować z `artifact.html` istniejącego artefaktu tego DS. |
| **Tokeny** (kolory, radius, spacing, typografia) | krok Adapt (ręcznie w HTML/CSS) | CSS variables / wartości; źródło = `tokens.css` lub docs DS projektu |
| **Komponenty / archetypy** (nav, karty, panele, widgety, agent) | krok Adapt + Klasa B | wzorce w repo projektu / plik Figma DS |
| **Node-id assetów Figmy** (logo, avatary, ikony) | `get_design_context(nodeId)` → `figma_asset_extract.sh` | mapa nazwa→nodeId w configu projektu |
| **Parametry prototypu** | krok Publish | np. viewport, touch-first, tranzycje |

## Gdzie config żyje (nie tutaj)
- **Pamięć projektu** (`.claude/memory/` danego repo) albo prywatna pamięć cross-project.
- **Repo projektu** z design systemem (`docs/design-system/`, `tokens.css`).
- Znajdowanie wartości w repo projektu → [[design-system-lookup]].

## Przykład wiązania (generyczny)
```bash
# 1) asset z Figmy (URL z get_design_context — krok MCP, nie shell)
figma_asset_extract.sh "<ASSET_URL>" avatar 160        # -> avatar.datauri

# 2) transform pod CSP z fontem DS
csp_transform.py index.html -o artifact.html --fonts <config>/fontface.html

# 3) wstaw asset przez placeholder (base64 nie wraca do kontekstu)
embed_base64.py artifact.html __AVATAR__=@avatar.datauri

# 4) gate + publish
preflight_artifact.py artifact.html                    # musi być OK
# -> narzędzie Artifact, file_path=artifact.html (ten sam path = ten sam URL)
```

## Przykładowe configi (poza publicznym repo)
Configi konkretnych DS (np. praca KIPP/Manta) trzymane są w **pamięci projektu**, nie tutaj —
tam są font, tokeny i node-id. Ten plik opisuje wyłącznie *kształt*, żeby engine został reusable
i wolny od danych klienckich.
