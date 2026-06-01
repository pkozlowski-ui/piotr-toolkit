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

```js
await node.setReactionsAsync([{
  trigger: { type: 'ON_CLICK' },
  actions: [{                      // ZAWSZE 'actions' (tablica), nigdy 'action'
    type: 'NODE',
    destinationId: 'target-frame-id',
    navigation: 'NAVIGATE',        // 'NAVIGATE' | 'OVERLAY' | 'SWAP' | 'SCROLL_TO'
    transition: {
      type: 'SMART_ANIMATE',
      duration: 0.3,
      easing: { type: 'EASE_OUT' }
    }
  }]
}]);
```

## ⚠️ Gotchas API (dynamic-page) — czytaj zanim napiszesz pierwszy skrypt

Te trzy pułapki wywalają każdy `figma_execute` po kolei. Realne błędy z sesji Flow 1 (2026-06-01):

1. **`node.reactions = [...]` rzuca błąd** `Cannot call with documentAccess: dynamic-page`. Plugin działa w trybie dynamic-page → ZAWSZE `await node.setReactionsAsync([...])`. Odczyt: `await node.reactions` (getter nadal działa).
2. **`action:` (l. poj.) rzuca** `Please update the 'actions' field instead of the 'action' field in order to prevent data loss`. ZAWSZE `actions: [ {...} ]` (tablica) — nawet dla pojedynczej akcji. Pole `action` jest deprecated.
3. **`flowStartingPoints` nie znosi zduplikowanych `nodeId`** → `Found duplicate input nodeIds`. Frame bywa już punktem startowym pod inną nazwą. Filtruj po **`nodeId`**, nie po nazwie, zanim dopiszesz swój.

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
const flow = [
  ['111:01', '111:02', 'ON_CLICK', 'SMART_ANIMATE'],
  ['111:02', '111:03', 'ON_CLICK', 'PUSH'],
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

## Checklist przed wgraniem flow

- [ ] Node IDs zweryfikowane (skrypt inspect lub `figma_get_selection`)
- [ ] Source i destination frames są na tej samej stronie
- [ ] Flow starting point ustawiony (jeden per flow)
- [ ] Test w Present mode: Cmd+Enter (Mac) / Ctrl+Enter (Win)
- [ ] Overlaye mają poprawną pozycję i backdrop

---

## Powiązane skille

- `figma-design-toolkit:figma-console` — **wymagany prerequisite** (`figma_execute`)
- `figma-design-toolkit:figma-design-workflow` — przed budowaniem ekranów które będą prototypowane
