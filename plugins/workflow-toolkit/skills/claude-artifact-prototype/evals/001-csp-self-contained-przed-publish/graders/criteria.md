---
type: llm
weight: 2
---

PASS wymaga obu:
1. Odpowiedź usuwa wrapper `<!DOCTYPE>`/`<html>`/`<head>`/`<body>` i zewnętrzne referencje
   http(s) (Google Fonts `<link>`) — font zamieniony na inline `@font-face` base64. Nie
   publikuje surowego dev-pliku wprost.
2. Duży base64 (awatar) wstawiany jest **skryptem** (placeholder + embed), NIE ręcznym pastem
   ani pełnym przepisaniem pliku przez Write.

FAIL, jeśli odpowiedź planuje publikację pliku z zachowanym wrapperem/Google Fonts, albo ręczne
wklejenie/edycję dużego base64 przez Write.
