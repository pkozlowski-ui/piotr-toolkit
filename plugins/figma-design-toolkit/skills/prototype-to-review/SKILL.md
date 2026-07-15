---
name: prototype-to-review
description: >
  Zamienia działający prototyp w kodzie (Claude Code / lokalny frontend) w ustrukturyzowany plik
  Figma do async review — jedna klatka per stan interakcji, elementy mapowane na komponenty DS
  (brak matcha → prymityw + nota „DS Drift"), adnotacje flow-critical wpięte w węzły. Ładuj gdy
  user mówi (EN+PL): „prototype to Figma", „prototyp do Figmy", „zrób to reviewable", „rozbij
  prototyp na flow", „Figma specs z kodu", „design review z prototypu", „break prototype into
  flows". NIE dla: pojedynczego ekranu z opisu (→ figma-generate-design), okablowania istniejących
  ekranów (→ figma-prototype), design→code (→ oficjalny plugin).
---

# prototype-to-review

Cel: reviewer przegląda flow w Figmie i **rozumie go bez odpalania kodu** — komentuje na klatkach,
czyta adnotacje interakcji, widzi gdzie prototyp odjechał od design systemu.

**To nie jest re-implementacja `figma-generate-design`.** Ten skill = warstwa orkiestracji:
*jak rozbić prototyp na stany, co zaadnotować, jak zdegradować gdy brak Dev Mode*. Silnik kod→klatka
(`figma-generate-design`), mechanikę zapisu (`figma-console`/`figma-cloud`) i opcjonalne spięcie flow
(`figma-prototype`) **wywołuje**, nie powiela.

**Prerequisite (zależnie od kanału):**
- Desktop Bridge → `figma-design-toolkit:figma-console` (`figma_execute`)
- Headless/cloud → `figma-design-toolkit:figma-cloud` (→ oficjalny `figma-use`)
- Silnik budowy klatek → oficjalny `figma:figma-generate-design`

---

## When to load

- User ma **działający prototyp w kodzie** (nie sam opis) i chce go dać do review w Figmie
- „Rozbij ten flow na ekrany/stany do komentowania"
- „Zrób z tego spec dla PM/QA/eng bez odpalania kodu"
- Design review async na wielu stanach interakcji jednego ficzera

**NIE tutaj:**
- Pojedynczy ekran/layout z opisu lub jednego widoku → `figma-design-workflow` + `figma-generate-design`
- Łączenie już istniejących ekranów w klikalny prototyp → `figma-prototype`
- Figma → kod → oficjalny plugin (`implement-design`)

---

## Cztery twarde reguły (non-negotiable)

1. **Buduj ZE ŹRÓDŁA kodu, nigdy z pikseli.** Czytaj CSS modules / Tailwind config / inline styles
   / komponenty React. **Zakaz** browser-capture, screenshot-to-design, HTML-to-design. Zgodne z
   twardym kanałem toolkitu (`figma-router` → „Kanał zapisu"; `figma-console` → placement).
2. **Nigdy nie twórz nowego komponentu DS.** Brak matcha w design systemie → zbuduj **prymityw**
   (auto-layout frame z tokenami) i dopnij adnotację **DS Drift**. Tworzenie nowych masterów DS to
   robota `figma-ds-init`/DS-ownera, nie tego skilla.
3. **Żaden widoczny element nie ginie.** Każdy element prototypu ląduje w Figmie jako instancja DS
   albo prymityw. Jeśli świadomie pomijasz (np. dev-only debug) — zapisz to w klatce flow-overview.
4. **Adnotacje tylko wpięte w węzeł, tylko flow-critical.** Nigdy floating text obok klatki.
   Dwie kategorie, 2–4 adnotacje **Interaction** na klatkę (patrz „Annotation discipline").

> **House rule — font.** Prymitywy **dziedziczą font z DS/pliku docelowego**; NIGDY nie wstrzykuj
> własnego kroju (żadnego twardego „Inter"). Font = decyzja brandowa (user-level `CLAUDE.md → Design`).
> Czytaj font z istniejącej instancji DS albo z text-style pliku; brak → zapytaj, nie zgaduj.

---

## Faza 0 — Resolve pliku + wykryj capability

1. **Plik docelowy:** URL od usera → istniejący plik; brak → utwórz nowy (`create_new_file` przez
   oficjalny plugin). Zapisz `fileKey`/deep-link do raportu (Faza 6).
2. **Kanał zapisu** (reguła `figma-router` → „Kanał zapisu"): budowa N klatek to zwykle **bulk write**
   → domyślnie `use_figma` przez `figma-cloud` (atomowy, bez sufitu 5 s). Iteracyjne poprawki pojedynczej
   klatki → `figma-console`. Bridge pada mid-session → przełącz na cloud, nie pętl reconnectów.
3. **Dev Mode / annotations** — natywne adnotacje Figmy wymagają Dev Mode (płatny seat). Wykryj raz:

```js
// figma_execute — probe: czy annotations API żyje w tym pliku/seacie?
let annotationsOk = false;
try { await figma.annotations.getAnnotationCategoriesAsync(); annotationsOk = true; }
catch (e) { annotationsOk = false; }
return { annotationsOk };
```

`annotationsOk:false` → tryb **fallback** (adnotacja = wpięty child text-node, patrz niżej). Nie pada,
degraduje. Zapisz który tryb w raporcie.

---

## Faza 1 — Analiza źródła prototypu

Zinwentaryzuj **ze źródła**, nie z uruchomionej apki:

- **Elementy:** każdy widoczny komponent/element per widok (nazwa, rola, wariant).
- **Stany interakcji:** wylicz stany, które zmieniają to, co widzi user — nie każdy re-render.
  Stan = klatka. Np.: `empty` → `filled` → `loading` → `success` / `error`; `list` → `item selected`
  → `sheet open`; `default` → `hover` → `disabled` (jeśli istotne dla review).
- **Layout/rozmiary:** zmierz viewport z kodu (breakpointy, `width`, container max-width) → rozmiar
  klatki. Desktop ≈ 1440/1280, mobile = wys. urządzenia. Nie zgaduj.
- **Wartości:** czytaj kolory/spacing/radius/typografię ze źródła → do zmapowania na tokeny (Faza 2).

Wynik: lista `{ view, state, elements[], viewport }` — plan klatek.

## Faza 1b — Gate zakresu (≥3 stany/flow)

Jeśli inwentarz daje **≥3 stany albo ≥3 flow** → pokaż userowi zwięzły plan (ile klatek, jakie stany)
i **poczekaj na wybór zakresu** zanim zbudujesz. ≤2 → leć bez pytania. (Chroni przed 40-klatkowym
wysypem, którego nikt nie chciał — kontrola decyzji > tempo.)

---

## Faza 2 — Mapowanie element → DS

Dla każdego elementu: znajdź match w design systemie **zanim** zbudujesz prymityw.

- Kanał wyszukania: oficjalny `search_design_system` / `figma_search_components` (Bridge) /
  katalog `docs/design-system/components.md` jeśli projekt ma DS-init.
- **Match** → użyj instancji DS (przez silnik budowy, Faza 4). Nie detachuj (reguła
  `figma-design-workflow` → „Never detach instances").
- **Brak matcha** → prymityw (Faza 4) + zanotuj drift: `{ element, why-no-match }` → adnotacja DS Drift.

Zapisz `driftNotes[]` — trafiają do adnotacji per-węzeł i do podsumowania w klatce flow-overview.

---

## Faza 3 — Plan stron/klatek

- **Jedna klatka = jeden stan interakcji.** Nazwa klatki: `<Flow> / <View> — <state>`
  (np. `Checkout / Payment — error`).
- Ułóż klatki w **sekcji per flow**, w kolejności przejść (lewo→prawo = kolejność w flow).
- Rozmiar klatki = zmierzony viewport (Faza 1). Mobile i desktop nie mieszaj w jednym rzędzie.
- Zarezerwuj miejsce na **klatkę flow-overview** (Faza 5) na początku sekcji.

---

## Faza 4 — Budowa klatek + adnotacje

**Budowa (silnik, nie tutaj):** dla każdej zaplanowanej klatki wywołaj `figma:figma-generate-design`
z opisem stanu ze źródła (elementy + zmapowane instancje DS + tokeny). Prymitywy dla elementów bez
matcha — auto-layout frame z **tokenami DS** (nie hardcode) i fontem dziedziczonym z pliku (House rule).
Bulk → `use_figma`/`figma-cloud`; pojedyncze poprawki → `figma-console`.

**Adnotacje — wpinaj OD RAZU po zbudowaniu klatki, nie na końcu.** Dwie kategorie:

| Kategoria | Kolor | Co adnotuje |
|---|---|---|
| **Interaction** | `BLUE` | Trigger + skutek: „Tap → opens filter sheet", „Submit → advances to `success`". Stan-advancing CTA, nietrywialny tap-target. |
| **DS Drift** | `ORANGE` | Element-prymityw bez matcha w DS: „No DS match — built as primitive; needs `Chip/filter`". |

Native (Dev Mode, `annotationsOk:true`):

```js
// figma_execute — kategorie idempotentnie, potem wpięcie w węzeł
async function ensureCategory(label, color) {
  const cats = await figma.annotations.getAnnotationCategoriesAsync();
  return cats.find(c => c.label === label)
      || await figma.annotations.addAnnotationCategory({ label, color });
}
const interaction = await ensureCategory('Interaction', 'BLUE');
const dsDrift      = await ensureCategory('DS Drift', 'ORANGE');

const node = await figma.getNodeByIdAsync('<node-id>');
node.annotations = [{ labelMarkdown: '**Tap** → opens filter sheet', categoryId: interaction.id }];
```

Fallback (`annotationsOk:false`): adnotacja = **child text-node wpięty przy elemencie** w tej samej
klatce (mały label z prefiksem `⟶` dla Interaction / `⚠ DS` dla Drift), NIGDY floating text na canvasie.
Reguła #4 („wpięte w węzeł") obowiązuje w obu trybach.

### Annotation discipline (żeby review zajęło <30 s/klatkę)

- **Target 2–4 Interaction / klatkę.** Więcej = szum, reviewer gubi flow.
- Grupę kontrolek adnotuj **raz** (nie każdy chip osobno).
- Adnotuj: stan-advancing CTA, nietrywialny/ukryty tap-target, przejście między stanami.
- **NIE adnotuj:** close/back, nav items, akcje drugorzędne, elementy dekoracyjne.

---

## Faza 5 — Klatka flow-overview

Na początku sekcji-flow zbuduj jedną klatkę-podsumowanie (czytelną bez wchodzenia w kod):

- **Nazwa ficzera** + jednozdaniowy cel flow.
- **Legenda adnotacji** (Interaction = niebieski, DS Drift = pomarańczowy).
- **Luki DS** — lista `driftNotes[]` z Fazy 2 (co jest prymitywem i czego brakuje w DS).
- **Otwarte pytania** — miejsca gdzie prototyp był niejednoznaczny (nie zgaduj — wypisz).

**Opcjonalnie: klikalny prototyp.** Domyślnie klatki są **statyczne** (przegląd). Tylko gdy user
wyraźnie poprosi o klikalny prototyp → spnij stany przez `figma-prototype` (`applyFlow()`,
tranzycje **INSTANT**). Wtedy uruchom też jego Verification pass (reachability/dead-ends).

---

## Faza 6 — Weryfikacja + raport

**Nie deklaruj „done" bez sprawdzenia realnego stanu** (twarda reguła). Zweryfikuj programowo:

```js
// figma_execute — kompletność: klatki, adnotacje, prymitywy
const page = figma.currentPage;
const frames = page.findAll(n => n.type === 'FRAME' && /—/.test(n.name)); // klatki-stany
const annotated = frames.filter(f => f.findAll(x => x.annotations && x.annotations.length).length > 0);
return {
  frames: frames.length,
  annotatedFrames: annotated.length,       // powinno ≈ frames (minus overview)
  framesBezAdnotacji: frames.filter(f => !annotated.includes(f)).map(f => f.name),
};
```

Raport do usera (zwięźle):
- **Deep-link** do pliku/strony.
- **Liczby:** ile flow / ile klatek-stanów / ile prymitywów (luki DS).
- **Tryb adnotacji:** native / fallback.
- **Otwarte pytania** z Fazy 5, jeśli są.

Zielony wynik: każda klatka-stan (poza overview) ma ≥1 adnotację; `framesBezAdnotacji` puste lub
świadomie uzasadnione.

---

## Degradacja po kanale (capability tiers)

| Sytuacja | Output |
|---|---|
| Bridge/cloud write + Dev Mode | Plik Figma: instancje DS + prymitywy + **native annotations** |
| Write bez Dev Mode | Plik Figma + adnotacje **fallback** (wpięte child text-nodes) |
| Tylko read/inspect (brak write) | **Prototype Spec (markdown)** — flow, inwentarz, stany, mapowanie DS, build-notes |
| Brak dostępu do Figmy | Spec z samej analizy kodu (jak wyżej, bez weryfikacji w pliku) |

Spec markdown zapisz przez `obsidian-capture` jeśli ma zostać w vaulcie.

---

## Powiązane skille

- `figma:figma-generate-design` — **silnik** kod→klatka (oficjalny plugin)
- `figma-design-toolkit:figma-console` / `figma-cloud` — kanał zapisu (Bridge / headless)
- `figma-design-toolkit:figma-design-workflow` — metodologia komponent-first (nie detachuj, tokeny)
- `figma-design-toolkit:figma-prototype` — opcjonalne spięcie stanów w klikalny prototyp (INSTANT)
- `figma-design-toolkit:figma-ds-tools` — po review: audyt driftu / podpięcie prymitywów pod DS
