---
name: figma-prototype
description: Tworzenie interaktywnych prototypów w Figmie — łączenie ekranów, tranzycje, overlaye, back navigation przez Plugin API. Ładuj gdy user chce budować lub modyfikować prototype mode w Figmie.
---

# figma-prototype

**Prerequisite:** Skill `figma-design-toolkit:figma-console` must be loaded first (gives `figma_execute` access).

---

## When to load

- User mówi: "połącz ekrany", "podłącz flow", "prototype mode", "dodaj interakcje", "kliknij i przejdź do X"
- Budowanie demo/prezentacji z istniejących ekranów
- Dodawanie tranzycji, overlayów, back navigation
- Czytanie istniejących połączeń prototypu

## Core concept

Prototype mode w Figmie = właściwość `reactions` na każdym nodzie. **Tylko Plugin API (figma_execute) może to zapisywać** — REST API i MCP server są read-only dla prototype.

> **⚠️ DOMYŚLNA TRANZYCJA = INSTANT (`transition: null`).** Nigdy nie wstawiaj `SMART_ANIMATE`/`DISSOLVE`/`PUSH` ani innej animacji — ani dla nawigacji, ani dla overlayów/disclosure/drawerów — **chyba że user wyraźnie o animację poprosi**. To globalny default (patrz user-level `CLAUDE.md → Figma — prototypy`). Tabela „Transition animation types" niżej jest referencją na wypadek wyraźnej prośby, nie zachętą.

```js
await node.setReactionsAsync([{
  trigger: { type: 'ON_CLICK' },
  actions: [{                      // ZAWSZE 'actions' (tablica), nigdy 'action'
    type: 'NODE',
    destinationId: 'target-frame-id',
    navigation: 'NAVIGATE',        // 'NAVIGATE' | 'OVERLAY' | 'SWAP' | 'SCROLL_TO'
    transition: null               // INSTANT (default). Animacja tylko na wyraźną prośbę.
  }]
}]);
```

## ⚠️ Gotchas API (dynamic-page) — czytaj zanim napiszesz pierwszy skrypt

Te pułapki wywalają każdy `figma_execute` po kolei. Realne błędy z sesji (Flow 1 2026-06-01; Flow 15/16 2026-06-09):

1. **`node.reactions = [...]` rzuca błąd** `Cannot call with documentAccess: dynamic-page`. Plugin działa w trybie dynamic-page → ZAWSZE `await node.setReactionsAsync([...])`. Odczyt: `await node.reactions` (getter nadal działa).
2. **`action:` (l. poj.) rzuca** `Please update the 'actions' field instead of the 'action' field in order to prevent data loss`. ZAWSZE `actions: [ {...} ]` (tablica) — nawet dla pojedynczej akcji. Pole `action` jest deprecated.
3. **`flowStartingPoints` nie znosi zduplikowanych `nodeId`** → `Found duplicate input nodeIds`. Frame bywa już punktem startowym pod inną nazwą. Filtruj po **`nodeId`**, nie po nazwie, zanim dopiszesz swój.
4. **Buttony w modalu/drawerze/zagnieżdżonej instancji adresuj PEŁNĄ ścieżką instancji** `I<root>;…;<btn>`, NIE gołym ID. Gołe ID (np. `2891:62610`) rozwiązuje się do węzła **wewnątrz komponentu** (chain urywa się, nie sięga PAGE) → `destination rejected … the source may not be a valid prototype source`. Znajdź on-canvas węzeł przez `screen.findAll(n=>n.type==='INSTANCE' && …)` i sprawdź, że parent-chain dochodzi do `PAGE` (`reachesPage`). Realny błąd Flow 15 (modal Merge-confirm) i Flow 16 (przycisk w SideDrawer).
5. **`setReactionsAsync` NIE jest rollbackowane przy throwie skryptu.** Mimo że `figma_execute` bywa „atomic", reactions ustawione PRZED rzutem zostają zapisane. Po nieudanym skrypcie **zweryfikuj stan** (odczytaj `reactions`), nie zakładaj że nic się nie stało — i pisz wiring idempotentnie (overwrite), żeby ponowienie było bezpieczne.
6. **Lista „Flows" w Present mode = `page.flowStartingPoints`, nie sekcje/ekrany.** Samo okablowanie ekranów i przycisków NIE sprawi, że flow pojawi się na liście ani że da się go odpalić z panelu — trzeba dopisać `{nodeId, name}` do `flowStartingPoints` (dedupe po `nodeId`, patrz pkt 3). Typowy „starting point" to cover/intro-frame, którego CTA wchodzi w pierwszy ekran flow.
7. **`scrollBehavior` (fixed-position) jest NIEWIDOCZNY dla Plugin API — w żadnej wersji** (`api:"1.0.0"` jest aktualne; to nie kwestia wersji bridge'a). `'scrollBehavior' in node === false`, odczyt `undefined`, zapis `node.scrollBehavior='FIXED'` rzuca `object is not extensible`. **Odczyt** (audyt): przez **REST** `GET /v1/files/:key/nodes?ids=<id>&depth=1` (bez `geometry`) → pole `scrollBehavior` (`SCROLLS`|`FIXED`|`STICKY_SCROLLS`). **Zapis** per-node: niemożliwy. **JEDYNA programowa dźwignia fixed-position = `frame.numberOfFixedChildren = N`** (zapisywalny, zweryfikowane 2026-06-11) — przypina N **wiodących dzieci-bezpośrednich** (np. ekran `[NavRail, Content]` → `numberOfFixedChildren=1` pinuje NavRail). Chrome zagnieżdżona głębiej (AppTopBar/footer w `Content`) → restrukturyzacja albo ręczny toggle w UI. Realny bug 2026-06-11 (Staff flows: cała chrome `SCROLLS`).

---

## Pre-flight: pobierz Node IDs

Potrzebujesz IDs ekranów źródłowych i docelowych. Wybierz opcję:

```js
// Opcja A — lista wszystkich frame'ów na bieżącej stronie
figma.currentPage.children
  .filter(n => n.type === 'FRAME')
  .map(n => ({ name: n.name, id: n.id }))

// Opcja B — z aktualnego zaznaczenia (zaznacz ekrany w Figmie)
figma.currentPage.selection.map(n => ({ name: n.name, id: n.id }))
```

Opcja C: z `docs/design-system/figma-registry.json` jeśli ekrany są tam udokumentowane.

---

## applyFlow() — deklaratywny pattern (główna metoda)

Definiuj flow jako tablicę tupli, apliku hurtem. To podstawowy pattern pracy z tym skillem.

```js
// Flow: [sourceId, targetId, trigger, transition]
// transition pomiń lub 'INSTANT' — to domyślne i preferowane (patrz Core concept).
const flow = [
  ['111:01', '111:02', 'ON_CLICK'],   // brak = INSTANT
  ['111:02', '111:03', 'ON_CLICK', 'INSTANT'],
  ['111:03', '111:01', 'ON_CLICK', 'INSTANT'],
];

async function applyFlow(flow) {
  for (const [srcId, dstId, trigger, transition] of flow) {
    const src = await figma.getNodeByIdAsync(srcId);
    if (!src) { console.error('Node not found:', srcId); continue; }
    await src.setReactionsAsync([{
      trigger: buildTrigger(trigger),
      actions: [{
        type: 'NODE',
        destinationId: dstId,
        navigation: 'NAVIGATE',
        transition: buildTransition(transition)
      }]
    }]);
  }
  return `Applied ${flow.length} connections`;
}

function buildTrigger(type, opts = {}) {
  if (type === 'AFTER_TIMEOUT') return { type, timeout: opts.timeout ?? 2000 };
  if (type === 'ON_KEY_DOWN') return { type, keyCodes: opts.keyCodes ?? ['Enter'] };
  return { type };
}

function buildTransition(type, duration = 0.3, direction = 'LEFT') {
  if (!type || type === 'INSTANT') return null;
  const easeOut = { type: 'EASE_OUT' };
  if (type === 'SMART_ANIMATE') return { type, duration, easing: easeOut };
  if (type === 'DISSOLVE')      return { type, duration, easing: easeOut };
  if (type === 'MOVE_IN')       return { type, duration, easing: easeOut, direction };
  if (type === 'MOVE_OUT')      return { type, duration, easing: easeOut, direction };
  if (type === 'PUSH')          return { type, duration, easing: easeOut, direction };
  if (type === 'SLIDE_IN')      return { type, duration, easing: { type: 'EASE_IN_AND_OUT' }, direction };
  if (type === 'SLIDE_OUT')     return { type, duration, easing: { type: 'EASE_IN_AND_OUT' }, direction };
  return null;
}

return await applyFlow(flow);
```

---

## Trigger types

| Trigger | String | Dodatkowe pola | Typowe użycie |
|---------|--------|----------------|---------------|
| Klik/tap | `ON_CLICK` | — | Główna nawigacja |
| Hover | `ON_HOVER` | — | Tooltips, preview states |
| Press (wciśnięty) | `ON_PRESS` | — | Button press state |
| Po czasie | `AFTER_TIMEOUT` | `timeout` (ms) | Auto-advance, loading screens |
| Mouse enter | `MOUSE_ENTER` | — | Enter state |
| Mouse leave | `MOUSE_LEAVE` | — | Exit state |
| Klawisz | `ON_KEY_DOWN` | `keyCodes: []` | Keyboard navigation |
| Przeciągnięcie | `ON_DRAG` | — | Swipe gestures |

---

## Navigation types

```js
navigation: 'NAVIGATE'    // push nowy ekran (historia działa — Back wraca)
navigation: 'OVERLAY'     // otwórz nad bieżącym ekranem (modal, drawer)
navigation: 'SWAP'        // zamień ekran bez historii (tabs, replace)
navigation: 'SCROLL_TO'   // przewiń do elementu na tym samym ekranie
```

---

## Transition animation types

| Type | Opis | Direction |
|------|------|-----------|
| `null` / `INSTANT` | Bez animacji | — |
| `SMART_ANIMATE` | Figma morphuje matching warstwy | — |
| `DISSOLVE` | Fade in/out | — |
| `MOVE_IN` | Wjeżdża z kierunku | LEFT / RIGHT / TOP / BOTTOM |
| `MOVE_OUT` | Wyjeżdża w kierunek | LEFT / RIGHT / TOP / BOTTOM |
| `PUSH` | Oba ekrany w ruchu (iOS-style) | LEFT / RIGHT / TOP / BOTTOM |
| `SLIDE_IN` | Wsuwa z opacity | LEFT / RIGHT / TOP / BOTTOM |
| `SLIDE_OUT` | Wysuwa z opacity | LEFT / RIGHT / TOP / BOTTOM |

Easing options: `EASE_IN` `EASE_OUT` `EASE_IN_AND_OUT` `LINEAR` `EASE_IN_BACK` `EASE_OUT_BACK` `CUSTOM_SPRING`

---

## Overlay pattern (modal, drawer, bottom sheet)

```js
const btn = await figma.getNodeByIdAsync('BUTTON_NODE_ID');
await btn.setReactionsAsync([{
  trigger: { type: 'ON_CLICK' },
  actions: [{
    type: 'NODE',
    destinationId: 'MODAL_FRAME_ID',
    navigation: 'OVERLAY',
    overlaySettings: {
      overlayBackgroundInteraction: 'CLOSE_ON_CLICK_OUTSIDE',  // lub 'NONE'
      overlayBackground: {
        type: 'SOLID_COLOR',
        color: { r: 0, g: 0, b: 0, a: 0.5 }  // dimmed backdrop
      },
      overlayRelativePosition: {
        type: 'CENTER'  // 'CENTER' | 'TOP_LEFT' | 'TOP_CENTER' | 'TOP_RIGHT'
                        // 'BOTTOM_LEFT' | 'BOTTOM_CENTER' | 'BOTTOM_RIGHT' | 'MANUAL'
      }
    },
    transition: { type: 'DISSOLVE', duration: 0.2, easing: { type: 'EASE_OUT' } }
  }]
}]);
```

---

## Back navigation

```js
const backBtn = await figma.getNodeByIdAsync('BACK_BTN_ID');
await backBtn.setReactionsAsync([{
  trigger: { type: 'ON_CLICK' },
  actions: [{ type: 'BACK' }]
}]);
```

---

## Wiele akcji na jeden trigger

```js
// 'actions' (plural) jest wymagane ZAWSZE — także dla jednej akcji (patrz Gotchas)
await node.setReactionsAsync([{
  trigger: { type: 'ON_CLICK' },
  actions: [
    {
      type: 'NODE',
      destinationId: 'MODAL_ID',
      navigation: 'OVERLAY',
      transition: null
    },
    {
      type: 'SET_VARIABLE',
      variableId: 'VAR_ID',
      variableValue: { type: 'BOOLEAN', resolvedType: 'BOOLEAN', value: true }
    }
  ]
}]);
```

---

## Inspekcja istniejących połączeń

```js
// Wylistuj wszystkie reactions na bieżącej stronie (getter `reactions` działa synchronicznie)
const frames = figma.currentPage.children.filter(n => n.type === 'FRAME');
return frames.map(f => ({
  id: f.id,
  name: f.name,
  reactions: f.reactions.map(r => ({
    trigger: r.trigger?.type,
    actions: (r.actions || []).map(a => ({ type: a.type, destination: a.destinationId, nav: a.navigation }))
  }))
})).filter(f => f.reactions.length > 0);
```

---

## Flow starting point (punkt startowy prototypu)

```js
// Ustaw frame jako punkt startowy flow w prototype mode
const startFrame = await figma.getNodeByIdAsync('START_FRAME_ID');
const page = figma.currentPage;
// dedupe po nodeId (NIE po nazwie) — frame bywa już startem pod inną nazwą → 'duplicate nodeIds'
page.flowStartingPoints = [
  ...page.flowStartingPoints.filter(p => p.nodeId !== startFrame.id),
  { nodeId: startFrame.id, name: 'Main Flow' }
];
return 'Flow starting point set';
```

---

## Usuń wszystkie reactions (reset)

```js
// UWAGA: usuwa WSZYSTKIE połączenia prototypu na bieżącej stronie
const all = figma.currentPage.findAll(n => n.reactions?.length > 0);
for (const n of all) await n.setReactionsAsync([]);
return `Cleared reactions on ${all.length} nodes`;
```

---

## Verification pass — OBOWIĄZKOWY pierwszy audyt (przed „done")

Po okablowaniu flow (albo gdy user prosi „zweryfikuj prototyp") zrób **automatyczny, dokładny audyt** — nie zgłaszaj „done" na podstawie samego faktu, że `setReactionsAsync` przeszło. Audyt ma 3 osie; pierwsze dwie robisz w pełni programowo, trzecią (fixed-position) czytasz przez REST i raportujesz (UI fix po stronie usera).

### Oś 1 + 2 — Connections, reachability, transitions (jeden skrypt `figma_execute`)

Dla każdej sekcji-flow: BFS osiągalności od ekranu wejściowego (z `flowStartingPoints` / karty intro). Wykrywa **sieroty** (ekran nieosiągalny), **dead-endy** (brak wyjścia i brak BACK), **cross-flow** (NAVIGATE poza sekcję flow) oraz **tranzycje ≠ instant** (łamią globalną regułę).

> ⚡ **Perf:** ustaw `figma.skipInvisibleInstanceChildren = true` na górze i skanuj reakcje przez `findAllWithCriteria` (filtr w silniku), nie `findAll(() => true)` — na dużej sekcji `findAll` timeoutuje. Dla długiego skanu podbij `timeout` w `figma_execute` (max 30000).

```js
// FLOWS: { 'Nazwa': { entry:'<pierwszy-ekran-id>', secs:['<section-id>', ...] } }
figma.skipInvisibleInstanceChildren = true;            // ⚡ kluczowe dla dużych stron
const RX_TYPES = ['FRAME','INSTANCE','COMPONENT','GROUP','TEXT','VECTOR','RECTANGLE'];
const FLOWS = {
  'Flow 1': { entry:'2288:30487', secs:['2288:30486'] },
  // ...
};
const report = {};
for (const [fname, cfg] of Object.entries(FLOWS)) {
  const screens = [];
  for (const sid of cfg.secs) { const sec = await figma.getNodeByIdAsync(sid);
    sec.children.filter(n => n.type === 'FRAME').forEach(f => screens.push(f)); }
  const ids = new Set(screens.map(s => s.id));
  const nameById = {}; screens.forEach(s => nameById[s.id] = s.name);
  const outNav = {}, hasBack = {}, animated = [];
  for (const s of screens) {
    outNav[s.id] = new Set(); hasBack[s.id] = false;
    const rxNodes = s.findAllWithCriteria({ types: RX_TYPES }).filter(n => n.reactions && n.reactions.length > 0);
    if (s.reactions && s.reactions.length) rxNodes.push(s);
    for (const n of rxNodes) for (const r of n.reactions) for (const a of (r.actions || [])) {
      if (a.type === 'BACK') hasBack[s.id] = true;
      if (a.type === 'NODE' && a.navigation === 'NAVIGATE' && a.destinationId) {
        outNav[s.id].add(a.destinationId);
        if (a.transition) animated.push({ from: nameById[s.id], node: n.name, t: a.transition.type }); // ≠ instant
      }
    }
  }
  const reached = new Set(), q = [cfg.entry];
  while (q.length) { const cur = q.shift(); if (reached.has(cur)) continue; reached.add(cur);
    for (const d of (outNav[cur] || [])) if (ids.has(d) && !reached.has(d)) q.push(d); }
  report[fname] = {
    total: screens.length, reached: reached.size,
    unreachable: [...ids].filter(id => !reached.has(id)).map(id => nameById[id]),
    deadEnds:    [...ids].filter(id => outNav[id].size === 0 && !hasBack[id]).map(id => nameById[id]),
    crossFlow:   screens.flatMap(s => [...outNav[s.id]].filter(d => !ids.has(d)).map(d => ({ from: nameById[s.id], destId: d }))),
    animatedTransitions: animated,   // powinno być [] — instant rule
  };
}
return report;
```

**Zielony wynik:** `reached === total`, `unreachable: []`, `deadEnds: []`, `animatedTransitions: []`. `crossFlow` ≠ [] → zwykle nieintencjonalny skok do innego flow (zgłoś userowi, nie tnij po cichu, jeśli to decyzja produktowa).

### Oś 3 — Fixed-position na ekranach > viewport (REST, read-only)

Ekran wyższy niż viewport (desktop ≈ 1080, mobile = wys. urządzenia) **scrolluje się w Present mode**. Jeśli chrome (`NavRail` / `AppTopBar` / `footer` / `page-header`) nie ma `scrollBehavior: FIXED`, odjedzie przy scrollu — wygląda zepsuto. Bridge tego nie widzi (Gotcha #7) → czytaj przez REST.

```js
// Krok A (figma_execute, tanie): wypisz ekrany > viewport + ID kandydatów chrome do przypięcia.
const SECS = ['<section-id>', /* ... */]; const VIEWPORT = 1080;
const CHROME = /navrail|apptopbar|topbar|footer|page-header|side-?rail|breadcrumb/i;
const out = [];
for (const sid of SECS) { const sec = await figma.getNodeByIdAsync(sid);
  for (const s of sec.children.filter(n => n.type === 'FRAME')) {
    if (s.height <= VIEWPORT) continue;
    const chrome = [];
    const scan = (n, d) => { for (const c of n.children || []) {
      if (CHROME.test(c.name || '')) chrome.push({ name: c.name, id: c.id });
      if (d < 2) scan(c, d + 1); } };
    scan(s, 0);
    out.push({ screen: s.name, h: Math.round(s.height), chrome });
  } }
return out;
```

Krok B — odczyt `scrollBehavior` (Plugin API go nie widzi, Gotcha #7) przez **targetowany REST**, NIE pełny dump:
`GET https://api.figma.com/v1/files/:key/nodes?ids=<chrome-id1,chrome-id2>&depth=1` (bez `geometry` — inaczej payload puchnie; `depth=0` bywa ignorowane, użyj `depth=1`). W każdym węźle pole `scrollBehavior`: `SCROLLS`|`FIXED`|`STICKY_SCROLLS`. (Header `X-Figma-Token: <PAT>`. Endpoint `nodes` jest Tier-1, ~20/min — cachuj.)

Krok C — naprawa. **`scrollBehavior` per-node jest niezapisywalny** (Plugin API ani REST), ALE **`numberOfFixedChildren` JEST zapisywalny** i to jedyna programowa dźwignia:
```js
// Przypina N wiodących dzieci-BEZPOŚREDNICH frame'a. Ekran [NavRail, Content] → pinuje NavRail.
const screen = await figma.getNodeByIdAsync('<screen-id>');
screen.numberOfFixedChildren = 1;   // NavRail (1. dziecko) zostaje przy scrollu
```
Działa tylko dla **wiodących dzieci-bezpośrednich**. AppTopBar/wizard-footer zagnieżdżone w `Content` tego nie złapią — albo przenieś je na poziom dzieci-bezpośrednich frame'a scrollującego (restrukturyzacja), albo zostaw **ręczny toggle w UI** (zaznacz → Position → „Fix position when scrolling"). Zaraportuj: co przypięto skryptem (NavRail) + listę elementów do ręcznego odklikania.

---

## Checklist przed wgraniem flow

- [ ] Node IDs zweryfikowane (skrypt inspect lub `figma_get_selection`)
- [ ] Source i destination frames są na tej samej stronie
- [ ] Flow starting point ustawiony (jeden per flow) + dopisany do `flowStartingPoints`
- [ ] **Verification pass oś 1+2:** reachable === total, brak sierot / dead-endów / cross-flow, `animatedTransitions: []`
- [ ] **Verification pass oś 3:** ekrany > viewport mają chrome `FIXED` (lub zaraportowana lista do ręcznego toggle)
- [ ] Wszystkie tranzycje = INSTANT (chyba że user prosił o animację)
- [ ] Test w Present mode: Cmd+Enter (Mac) / Ctrl+Enter (Win)
- [ ] Overlaye mają poprawną pozycję i backdrop

---

## Powiązane skille

- `figma-design-toolkit:figma-console` — **wymagany prerequisite** (`figma_execute`)
- `figma-design-toolkit:figma-design-workflow` — przed budowaniem ekranów które będą prototypowane
