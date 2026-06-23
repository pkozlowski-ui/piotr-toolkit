---
name: figma-done-gate
description: Twardy gate przed zgłoszeniem "done" dla pracy w Figmie — wymusza uruchomienie gateScreen(id) (token + instance-ratio + padding + fixed100 + copy) i wklejenie pass:true PRZED jakąkolwiek deklaracją gotowości. Uruchamia się ZANIM powiesz "done"/"gotowe"/"naprawione"/"skończone"/"działa" o ekranie lub komponencie Figma, oraz po każdej serii edycji w figma_execute. Egzekwuje globalną regułę "brak done bez dowodu".
---

# Skill: figma-done-gate

## Cel
Zamienić weryfikację z „reguły do zapamiętania" w **krok, którego nie da się cicho pominąć**. Dominujący
tryb awarii przy Figmie = deklaracja-bez-dowodu (retro 2026-06-23). Ten gate temu zapobiega: „done" ma
dowód (`pass:true`) wklejony w tej samej odpowiedzi, albo nie ma „done".

## Auto-trigger
- ZANIM napiszesz „done" / „gotowe" / „naprawione" / „skończone" / „działa" / „zrobione" o ekranie lub
  komponencie Figma.
- Po każdej serii edycji w `figma_execute` na ekranie/komponencie, przed raportem do usera.

## Kontrakt (TWARDY — nadrzędny)
1. **Brak „done" bez `pass:true`.** Uruchom `gateScreen(<NODE_ID>)` (z `figma-build-kit.md`) i **wklej zwrócony
   JSON do odpowiedzi**. `pass:false` = NIE skończone — napraw wg pól i uruchom ponownie.
2. Gate to **osobny, wąsko scope'owany call** na bridge (`figma_execute`) — audyty czytają żywy graf
   (`boundVariables`, `layoutSizing*`, `textStyleId`), więc MUSZĄ zostać w pluginie. Nie da się ich przenieść
   na official MCP/REST.
3. Dowód = JSON, nie słowa. „Wygląda OK na screenshocie" ≠ pass.

## Jak (3 kroki)
1. Na górze `figma_execute` wklej Build Kit + sekcję AUDYTY z `docs/design-system/figma-build-kit.md`
   (zawiera `tokenAudit`/`instanceRatioAudit`/`paddingAudit`/`fixed100Audit`/`copyAudit` + `gateScreen`).
2. `return await gateScreen('NODE_ID')` (ID budowanego/edytowanego ekranu lub komponentu).
3. Wklej wynik. Jeśli `pass:true` → możesz zgłosić done + pokazać screenshot (`figma_capture_screenshot`).
   Jeśli `pass:false` → napraw: `token.issues` (hardcoded/brak-stylu), `fixed100.issues`
   (`layoutSizingVertical='HUG'`), `padding.issues` (`dedupePad`), `copy.issues` (capitalization/placeholder/rok),
   `ratio.violations` (raw frame → instancja). Powtórz gate.

## Inspect-before-mutate (towarzysząca reguła)
Przed hide/swap/delete/setText na istniejącej instancji: `kids(node)` (helper z build-kit) i celuj po
`find(c=>c.name===…)`/typie — **nigdy po indeksie**. Założona kolejność dzieci = realny bug (schowany Switch
zamiast Input). Tani guard, kasuje całą klasę „złego węzła".

## verifyInstances — osobno
Po fixie strukturalnym (zmiana `primaryAxisAlignItems`/`itemSpacing`/sizing na masterze lub instancjach)
uruchom `verifyInstances(masterId, expectedLayout, expectedSpacing)` — wymaga argumentów, więc NIE wchodzi
do `gateScreen`. `hasOverride:true` = zostały stare overrides do wyczyszczenia.

## Czego gate NIE łapie
Rejestru/tonu copy (to człowiek wg `ux-writing.md`), poprawności merytorycznej designu, decyzji
produktowych. Gate = mechaniczna poprawność (tokeny, struktura, layout, copy-mechanika). Zielony gate ≠
„zaakceptowane" — akceptację daje user.

## Ograniczenie (szczere)
W tym stacku nie ma fizycznie blokującego gate'a dla artefaktów Figmy (weryfikator siedzi za tym samym
samoraportującym bridge'em). Maksimum = jeden call + ten skill + dowód-w-transkrypcie. To czyni pominięcie
**widocznym**, nie niemożliwym — dyscyplina nadal po stronie agenta, ale bez wymówki „za dużo roboty".
