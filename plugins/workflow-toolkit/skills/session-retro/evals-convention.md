# Konwencja `evals/` — taski specyfikacyjne skilli

> Wykonuje doktrynę validation-gate (SKILL.md → „Validation-gate"): „waliduj na przykładach
> nieużytych do wymyślenia zmiany". Ten plik definiuje, GDZIE te przykłady żyją i jak wyglądają.
>
> **Nazwa poprawiona 2026-08-13:** wcześniej ten plik nazywał się „zmaterializowany held-out",
> co było nieprawdą — task pisany z tej samej wpadki, która zrodziła poprawkę, jest specyfikacją
> i przechodzi z definicji. Held-out ma własny mechanizm: [`held-out-gate.md`](held-out-gate.md).
> Konwencja jest cross-plugin — dotyczy każdego skilla w każdym pluginie tego marketplace'u.
>
> Rodowód: Evaluation-Driven Development (Anthropic „Demystifying evals for AI agents", Hamel
> Husain „Evals FAQ") — zbiór tasków rośnie z REALNYCH wpadek, nie z syntetycznych pomysłów.
> Utwardzone po held-out checku na 3 historycznych wpadkach (2026-07-10, sesja EDD-research).

## Dwie warstwy, obie zostają

Od 2026-08-14 `evals/` ma **dwie warstwy o różnych zadaniach** — nie zastępują się, uzupełniają:

| Warstwa | Plik | Kto to czyta | Do czego |
|---|---|---|---|
| **Rationale** (proza) | `evals/NNN-<slug>.md` | człowiek | rodowód wpadki („źródło: realna sesja"), pomiary, historia werdyktów |
| **Brama** (CLI) | `evals/<case>/prompt.md` + `graders/*.md` | `claude plugin eval` | realny gate: score, exit 1 poniżej progu, ablacja with/without |

Loader CLI skanuje wyłącznie `evals/**/prompt.md` i `evals/**/case.yaml`, więc **pliki prozy są
ignorowane i nie trzeba ich kasować przy przepisywaniu na format CLI.** Rodowód należy do prozy
i do pola `description` w `prompt.md` — **nigdy do treści promptu** (patrz „Prompt musi być
wykonalny w pustym sandboxie").

## Layout

```
plugins/<plugin>/skills/<skill>/evals/
  001-<slug>.md                      # rationale (proza, dla człowieka)
  001-<slug>/                        # case dla CLI — ta sama numeracja i slug
    prompt.md                        #   frontmatter + treść promptu
    graders/criteria.md              #   grader llm
    graders/skill-loaded.md          #   grader tool_used (darmowy)
```

Numeracja rosnąca, nigdy nie reużywaj numeru. Task wycofany dostaje `status: wycofany`
(nie kasuj — historia werdyktów to też dane).

## Schemat taska

```markdown
---
id: <skill>-NNN
skill: <nazwa skilla>
źródło: <retro YYYY-MM-DD / commit / realna sesja — skąd wzięła się wpadka>
status: aktywny | wycofany
---

# <Jedno zdanie: jakie zachowanie ten task testuje>

**Scenariusz (input):** <sytuacja/dane wejściowe; gdy potrzebny plik — ścieżka do fixture obok>
**Pass:** <co skill MUSI zrobić w tym scenariuszu — werdykt binarny, bez skali>
**Fail wygląda tak:** <antywzorzec, który realnie wystąpił>
**Jak sprawdzić:** <manualnie: odpal skill na scenariuszu / porównaj zachowanie z Pass>
```

Dobry task = dwóch niezależnych oceniających da ten sam werdykt pass/fail (Anthropic, krok 2).
Jeśli nie umiesz napisać jednoznacznego „Pass" — to materiał na wpis w pattern-library, nie eval.

## Format CLI (brama)

> Schemat odczytany ze scaffoldu `claude plugin eval init --bare <nazwa>` + z loadera w binarce
> CLI 2.1.228. **Nie zgaduj go z `--help`** — `--help` nie opisuje ani kluczy frontmattera,
> ani typów graderów. Gdy CLI podskoczy o wersję i coś nie ładuje się — przescaffolduj `--bare`
> na czysto i porównaj, nie zgaduj.

`--bare` scaffolduje `prompt.md` + `graders/criteria.md` (NIE `case.yaml`). Oba formaty są dla
loadera równoważne; **kanoniczna jest forma scaffoldowana** — `case.yaml` tylko gdy potrzebujesz
kluczy kontekstowych (`scaffold_script`, `history_file`, `add_dirs`), których w `prompt.md` nie ma.

### `prompt.md`

```markdown
---
name: 001-<slug>                     # równe nazwie katalogu
description: <jedno zdanie: jakie zachowanie ten case testuje>
tags: [<skill>, <os-doktryny>]       # --tag filtruje przebieg
runs: 2                              # default 3, max 50
max_turns: 10                        # default 10, max 200
timeout_seconds: 300                 # default 300, max 3600
allowed_tools: [Read, Glob, Grep, Skill]
---

<treść promptu — dokładnie to, co „napisałby user">
```

Pozostałe klucze: `schema_version`, `plugins`, `expected_outcome` (top); `model`,
`append_system_prompt`, `env` (execution).

### Gradery — 6 typów

Jeden plik = jeden grader; **nazwa pliku = nazwa gradera** (widoczna w raporcie, więc nazywaj
po tym, co sprawdza). Ciało pliku mapuje się na pole zależnie od typu: `llm` → `criteria`,
`baseline` → `criteria`, `regex` → `pattern`. Reszta typów ma wszystko we frontmatterze.

| Typ | Klucze | Koszt | Do czego |
|---|---|---|---|
| `tool_used` | `tool`, `input_match`, `min`, `max` | **darmowy** | czy skill/narzędzie zostało wywołane |
| `regex` | `target`, `pattern`, `flags`, `match: contains \| not_contains \| count:N` | **darmowy** | literalny token, który MUSI (nie) wystąpić |
| `tool_order` | `before`, `after` | **darmowy** | kolejność wywołań (np. claim przed edycją) |
| `file_exists` | `path`, `exists` | **darmowy** | efekt na dysku |
| `llm` | `criteria`, `focus` | **płatny** (3 głosy sędziego) | osąd doktrynalny, którego nie da się złapać regexem |
| `baseline` | `baseline_file`, `criteria` | **płatny** | porównanie z wzorcową odpowiedzią |

Każdy grader ma `weight` (default 1) i opcjonalny `arm`: `with-only` | `both`.
`target`/`focus`: `trace` | `last_message` | `files` | `{source: file, path: …}`.

**Każdy case dostaje darmowy grader `skill-loaded`** (`tool_used` na `Skill` + `input_match:
<skill>`, `arm: with-only`) — sam wykrywa regres triggera, bez kosztu sędziego:

```markdown
---
type: tool_used
tool: Skill
input_match: obsidian-kanban
min: 1
weight: 1
arm: with-only
---
```

Tam, gdzie o werdykcie decyduje **literalny token** (nazwa skryptu, nazwa komendy, zakazana
wartość statusu) — dołóż darmowy `regex` obok `llm`. Odwrotnie: **nie dawaj `regex` na coś,
co odpowiedź może zgodnie z prawdą zacytować jako antywzorzec.** Case 009 obsidian-kanban miał
regex „brak `#` w nazwie pliku", który karał odpowiedź za poprawne wytłumaczenie, dlaczego `#`
jest złe (`criteria` PASS 3/3, całość 0.75). Grader usunięty — `llm` już ten warunek pokrywał.

## Cztery twarde reguły bramy

### 1. Bump wersji pluginu = warunek działania bramy, nie kosmetyka

Cache pluginu jest **przypięty per wersja**. Bez bumpa `claude plugin update` odpowiada
„already at the latest version" i **gate cicho testuje poprzednią kopię case'ów** — dostajesz
zielone/czerwone lampki z pliku, którego już nie ma. Pętla przy KAŻDEJ zmianie w `evals/`:

```bash
# 1. bump plugins/<plugin>/.claude-plugin/plugin.json  2. commit + push  3. dopiero potem:
claude plugin update <plugin>@pkozlowski-ui-marketplace
```

### 2. Target po nazwie pluginu, NIGDY po ścieżce

Przy targecie-ścieżce (`claude plugin eval .`) **skill nie jest dostępny agentowi** — dostajesz
`Skill called 0x` i fałszywe FAIL-e na całej suicie. Ten sam case: 0.00 po ścieżce, 1.00 po
nazwie. Kanoniczna komenda bramy:

```bash
claude plugin eval <plugin>@pkozlowski-ui-marketplace \
  --runs 2 --ablation none --threshold 0.8 --no-publish --judge-model sonnet
```

Ta różnica 0.00 vs 1.00 jest jednocześnie dowodem, że brama mierzy **realny wkład skilla**,
a nie wiedzę modelu.

### 4. Sędzia = sonnet, NIE domyślny haiku

Domyślny sędzia (haiku) **produkuje fałszywe FAIL-e na długich odpowiedziach.** Zmierzone na
obsidian-kanban: case'y 003 i 004 dostały od haiku `FAIL FAIL FAIL` w **dwóch** kolejnych runach
(score 0.33, stabilnie — więc nie szum), a ten sam case z `--judge-model sonnet` dał
`PASS PASS PASS` (score 1.00). Zmieniony był wyłącznie sędzia: prompt, `criteria` i SKILL.md
nietknięte. To były dwie najdłuższe odpowiedzi w suicie (6310 i 5096 znaków) z warunkami
zaszytymi głęboko w strukturze — haiku nie utrzymuje trzech warunków „ALL must hold" na takim
materiale.

Koszt tej poprawki jest pomijalny: sędzia haiku ~$0.008/run, sonnet ~$0.032/run, przy runie
agenta ~$0.41. **+6% do przebiegu za usunięcie całej klasy fałszywych czerwonych lampek.**

Nie ma klucza per-case (`judge_model` nie występuje w schemacie `prompt.md`) — sędzia idzie
**flagą na komendzie**, więc musi być w kanonicznej komendzie bramy, inaczej wypada przy
każdym ręcznym przebiegu.

**Konsekwencja dla triage:** zanim uznasz `criteria FAIL` za dziurę w SKILL.md, sprawdź, czy
odpowiedź nie jest długa — i przepuść case przez sonnet. Fałszywy FAIL od haiku wygląda
identycznie jak realna dziura w doktrynie, a prowadzi do dokładnie złej naprawy: rozluźnienia
kryterium, które było poprawne.

### 3. Prompt musi być wykonalny w PUSTYM sandboxie — bez vaultu, bez MCP

Sandbox evala ma **pusty katalog roboczy i zero narzędzi `mcp__*`**. Prompt zlecający operację
na nieistniejącym stanie („przesuń tę kartę", „odczytaj notatkę X") sprawia, że agent robi
jedyną uczciwą rzecz: diagnozuje brak środowiska i odmawia pracy na ślepo — zużywa tury na
`ToolSearch`/`Glob`/`Grep` i **nigdy nie dochodzi do wywołania skilla**. Wynik: `skill-loaded 0x`
i score 0.00, wyglądające jak regres triggera, a będące artefaktem promptu.

Dlatego:
- **Prompt pyta o procedurę/doktrynę**, którą agent zastosuje — nie zleca operacji na stanie.
- Gdy scenariusz i tak brzmi operacyjnie, dopisz jawną notkę: *„nie masz teraz podpiętego
  vaultu ani narzędzi `mcp__*` — nie próbuj niczego wykonywać ani szukać plików; odpowiedz
  z pamięci procedury"*.
- **Zero ścieżek relatywnych w treści promptu.** Linijka „Rationale: `../NNN-*.md`" rozwija się
  w sandboxie na nieistniejącą ścieżkę w tempie i wysyła agenta na poszukiwania. Rodowód →
  plik prozy + `description`.
- `allowed_tools` zawężony do tego, co case realnie potrzebuje (zwykle `[Read, Glob, Grep, Skill]`)
  — odcina drogi ucieczki w diagnozę środowiska.

Wariant wierniejszy — fixture vaultu przez `scaffold_script` + `--scaffold` — jest możliwy, ale
droższy i odpala cudzy bash jako Ty. Świadoma decyzja per suita, nie default.

## Koszt i dyscyplina wydatku

Zmierzone (nie szacowane) na obsidian-kanban, 3 głosy sędziego:

| Zakres | Koszt |
|---|---|
| 1 run: agent | ~$0.40 |
| 1 run: sędzia haiku / sędzia sonnet | ~$0.008 / ~$0.032 |
| 1 case × 2 runy | ~$0.80 |
| 9 case'ów × 2 runy | ~$7 |
| 9 case'ów × 2 runy + `--ablation with-without` | ~$14 |

**Prompty w formie „opisz procedurę" są ~2× tańsze od operacyjnych.** Wersja promptów zlecająca
operację na nieistniejącym vaulcie kosztowała ~$0.74 za run — agent przepalał tury na diagnozę
środowiska (reguła 3). Po przeramowaniu ten sam case kosztuje ~$0.40. Reguła 3 nie jest tylko
o poprawności sygnału; jest też o połowie rachunku.

Stąd doktryna:
- **`--ablation none` w codziennym użyciu.** Pełne `with-without` świadomie, raz na większą
  zmianę skilla.
- **Gate ręczny, NIE hook `pre-push`** — w hooku to niekontrolowany wydatek.
- **Pytaj usera przed każdym przebiegiem płatnym** (twardy sufit: zero paid overage).
- **`--case <glob>` + `--tag`** — nie płać za case'y, które już są zielone i których nie ruszałeś.
  `--case` matchuje **prefiksem po nazwie case'a**: `002*` działa. Matcher **nie jest minimatchem** —
  klasa znaków (`00[23478]*`) nie matchuje niczego, więc selekcję kilku case'ów robisz pętlą
  osobnych wywołań, nie jednym globem. Niedopasowany glob kończy się natychmiast i **za darmo**
  („No eval cases found matching"), więc próbowanie składni nic nie kosztuje — ale próbuj tylko
  globami, które w razie trafienia odpalą wyłącznie to, za co chcesz zapłacić.
- **`--max-cost-usd <n>`** jako twardy sufit przebiegu (exit 2 przy przekroczeniu; overrun
  ograniczony do jednego runu, płatne gradery są wtedy pomijane, darmowe nadal scorują).
- **`--runs 1` nadaje się do SZUKANIA zepsutych case'ów, nie do certyfikowania baseline'u** —
  pojedynczy run jest szumny (ten sam grader `regex` dał FAIL i PASS na tym samym case'ie
  w dwóch przebiegach). Baseline certyfikuj przy `--runs 2`+.
- **`--keep-temp` jest do diagnozy potrzebny RZADKO.** `aggregate-result.json` ma w każdym
  graderze `llm` pole **`evidence` z pełną ostatnią odpowiedzią agenta** — czyli materiał,
  na którym sędzia głosował, dostajesz za darmo z zakończonego przebiegu:

  ```bash
  python3 -c "import json;d=json.load(open('evals/results/<run>/aggregate-result.json'));\
  print([g for g in d['cases'][0]['arms']['with'][0]['graders'] if g['name']=='criteria'][0]['evidence'])"
  ```

  Sięgaj po `--keep-temp` + `out/trace.jsonl` tylko wtedy, gdy pytanie dotyczy **przebiegu**
  (które narzędzia, w jakiej kolejności, na czym zszedł z torów), a nie **treści odpowiedzi**.
  Pierwsza diagnoza obsidian-kanban wydała $3.44 na runy z `--keep-temp`, żeby zobaczyć to,
  co już leżało w darmowym JSON-ie z poprzedniego przebiegu.
- **Uzasadnień sędziego CLI nie zapisuje** — w JSON-ie jest tylko `judgeVotes: [bool, bool, bool]`.
  Przy `FAIL` nie wiadomo, KTÓRY warunek `criteria` poległ; wnioskuj z `evidence` i z kształtu
  kryterium, albo rozbij wielowarunkowe `criteria` na osobne gradery, gdy case czerwieni się
  powtarzalnie i nie umiesz wskazać warunku.

## Diagnoza czerwonego case'a — cztery klasy, cztery różne naprawy

**Nie wolno rozluźniać graderów, żeby case'y zzieleniały.** Czerwony case to pytanie „co
konkretnie jest zepsute", i odpowiedzi są cztery. Idź tą kolejnością — każdy krok jest tańszy
od następnego i wyklucza klasę, która wygląda identycznie:

| # | Klasa | Sygnatura | Naprawa |
|---|---|---|---|
| 1 | **Niewykonalny prompt** | `skill-loaded 0x`, score dokładnie 0.00 | przepisz prompt wg reguły 3 — gradery nietknięte |
| 2 | **Bug evala** | darmowy grader FAIL przy `criteria` PASS 3/3 | popraw/usuń grader — zły jest eval, nie skill |
| 3 | **Fałszywy FAIL sędziego** | `criteria` FAIL na **długiej** odpowiedzi, sędzia = haiku | re-run z `--judge-model sonnet` (reguła 4) |
| 4 | **Realna dziura w SKILL.md** | `criteria` FAIL **także u sonneta** | uzupełnij doktrynę w SKILL.md; bump + re-run |

Kolejność nie jest kosmetyczna — klasy 3 i 4 mają **identyczną sygnaturę** (`skill-loaded` ✓ +
`criteria` FAIL 3/3, powtarzalnie w wielu runach), a naprawy są przeciwne: jedna nie tyka
kryterium, druga dopisuje doktrynę. Pomyłka w tę stronę kończy się rozluźnieniem kryterium,
które było poprawne — dokładnie tym, czego ta konwencja zabrania.

Dwa darmowe checki przed każdą płatną diagnozą:
1. **`score == 0.00`** przy darmowym `skill-loaded` to sygnatura „skill się nie załadował" (klasa 1) —
   sprawdź to, ZANIM zaczniesz diagnozować treść odpowiedzi.
2. **Przeczytaj `evidence`** z `aggregate-result.json` i sam sprawdź kryterium wobec odpowiedzi.
   Gdy Twój odczyt mówi PASS, a sędzia dał FAIL — jesteś w klasie 3, nie 4.

## Cykl życia

1. **Retro → task.** Realna wpadka skilla/reguły w sesji → dopisz task (krok w `session-retro`).
2. **Zmiana skilla → run.** ZANIM utwardzisz zmianę w SKILL.md — przejdź `evals/` tego skilla
   i sprawdź, że nowa wersja nadal przechodzi wszystkie aktywne taski. Regres = nie utwardzaj.
   **To jest warunek konieczny, nie wystarczający:** taski tutaj pisała ta sama sesja, która wymyśliła
   poprawkę, więc przechodzą z definicji. Pytanie „czy nowa wersja jest LEPSZA od starej" rozstrzyga
   [`held-out-gate.md`](held-out-gate.md) — podział czasowy realnych wywołań
   (`usage-audit/scripts/heldout_split.sh`), a syntetyki dopiero gdy realnych jest za mało.
3. **Bump wersji pluginu** — gdy zmieniasz skill mający `evals/`, odnotuj w commit message
   wynik: `evals: N/N pass`. Przy case'ach w formacie CLI bump jest **warunkiem koniecznym
   działania bramy**, nie adnotacją — patrz „Trzy twarde reguły bramy" → reguła 1.
4. **Saturacja** — gdy skill od dawna przechodzi wszystko i wpadek brak, to sygnał zdrowia,
   nie powód do generowania sztucznych tasków.

## Kiedy NIE dodawać taska

- **Wpadka jednorazowa / ludzka** (misclick, literówka w prompcie usera) — nie zachowanie skilla.
- **Pokryte deterministycznym checkiem** (hook, skrypt typu `hygiene-audit.mjs`, gate w repo
  projektu) — wtedy TEN check jest evalem; nie dubluj go w markdown.
- **Hipotetyczny scenariusz** („a co gdyby…") — tylko realne porażki; syntetyki dopiero gdy
  zbiór z życia ma dziury klasowe (i wtedy oznacz `źródło: syntetyczny`).
- **Duplikat** — istniejący task pokrywa zachowanie → ewentualnie doostrz jego „Pass".
