---
name: project-audit
description: Audyt higieny reguł pracy projektu (memory / CLAUDE.md / docs) — 2-warstwowy. Warstwa 1: deterministyczny linter (cap memory, parytet indeksu, rozmiar CLAUDE.md, dobór modelu). Warstwa 2: audyt osądu (sprzeczności, dryf, duplikaty, martwe deklaracje). Wczytaj gdy user mówi "audyt projektu", "higiena reguł", "hygiene audit", "sprawdź memory/CLAUDE.md", gdy chcesz podpiąć audyt do nowego projektu, albo gdy odpala się scheduled agent-audyt.
---

# Skill: project-audit

## Cel

Trzymać higienę reguł pracy projektu: pamięć się nie rozrasta bez kontroli, CLAUDE.md
nie puchnie treścią on-demand, indeks pamięci jest spójny, reguły nie przeczą sobie i
nie ma „martwych deklaracji" (procesów zapisanych jako istniejące, a nieobecnych).

Generyczny, reużywalny wzorzec — działa w każdym projekcie, który ma
`.claude/audit-invariants.json`. Progi są per-projekt; mechanika wspólna (żyje w
`workflow-toolkit`).

## Architektura — 2 warstwy

**Warstwa 1 — deterministyczny linter** (`scripts/hygiene-audit.mjs`, zero zależności):
mierzy twarde inwarianty, nie ocenia — tylko liczy. Czyta `.claude/audit-invariants.json`
z CWD. Checki: cap wpisów memory, build-logi do archiwum, parytet `MEMORY.md` ↔ pliki,
rozmiar CLAUDE.md (linie), markery design-detalu (opcjonalnie), istnienie `_archive/`,
higiena doboru modelu (delegacja vs mechanika, opcjonalnie). Kontrakt: **exit 0 zawsze**
— sygnał niesie treść, nie kod wyjścia (hook nie może blokować sesji).

**Warstwa 2 — audyt osądu** (scheduled agent, prompt w `judgement-audit-agent.md`):
łapie to, czego linter nie zmierzy — reguły faktycznie łamane, sprzeczności, dryf docs,
duplikaty w memory, martwe deklaracje. Czyta output warstwy 1 (`--json`) + `git log`
od ostatniego raportu, pisze raport do `docs/audits/<data>-hygiene.md`. **Propose-first**
dla zmian treści (nie modyfikuje memory/CLAUDE.md sam); commituje wyłącznie własny raport.

## Uruchomienie lintera (warstwa 1)

```bash
# pełny raport (human)
node <toolkit>/plugins/workflow-toolkit/scripts/hygiene-audit.mjs

# cichy gdy czysto, raport tylko gdy są ⚠️ (tryb hooka SessionStart)
node <toolkit>/plugins/workflow-toolkit/scripts/hygiene-audit.mjs --hook

# maszynowy JSON (dla agenta warstwy 2)
node <toolkit>/plugins/workflow-toolkit/scripts/hygiene-audit.mjs --json
```

`<toolkit>` = katalog repo `piotr-toolkit` (na maszynie Piotra:
`/Users/piotrkozlowski/Documents/piotr-toolkit`). Odpalaj z roota audytowanego repo
(CWD = korzeń projektu — linter liczy względem CWD).

Brak `.claude/audit-invariants.json` → linter cicho wychodzi (exit 0): projekt bez
skonfigurowanej higieny.

## Setup nowego projektu (3 elementy)

`init-project` robi to automatycznie. Ręcznie:

### 1. Config per-projekt (wymagane)
Skopiuj szablon i dostrój progi:
```bash
cp <toolkit>/plugins/workflow-toolkit/skills/project-audit/audit-invariants.template.json \
   .claude/audit-invariants.json
```
Wypełnij `project` (nazwa) i dobierz progi do skali projektu (patrz `_note` w każdym
kluczu). Usuń bloki `modelPolicy` / `claudeMd.designMarkerBaseline` jeśli projekt nie
używa Figma / nie ma design systemu.

### 2. Global SessionStart hook (raz na maszynę)
Linter warstwy 1 odpala się automatycznie na starcie sesji, warunkowo od obecności
configu. Hook żyje w **globalnym** `~/.claude/settings.json` (nie per-projekt) — dzięki
temu każdy projekt z configiem dostaje go za darmo:
```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ {
        "type": "command",
        "command": "test -f .claude/audit-invariants.json && node <toolkit>/plugins/workflow-toolkit/scripts/hygiene-audit.mjs --hook 2>/dev/null || true",
        "timeout": 10,
        "statusMessage": "hygiene audit"
      } ] }
    ]
  }
}
```
Ten hook jest częścią setupu maszyny → patrz `bootstrap-machine`. Jeśli już istnieje,
nowy projekt nie wymaga żadnej akcji na hooku — wystarczy config z kroku 1.

### 3. Scheduled agent-audyt (warstwa 2, opcjonalne)
Zarejestruj cron przez skill `schedule` (lub `mcp__scheduled-tasks__create_scheduled_task`).
Prompt agenta: weź `judgement-audit-agent.md` z tego skilla i wypełnij placeholdery
(`{{PROJECT_NAME}}`, `{{REPO_PATH}}`, `{{TOOLKIT_PATH}}`, `{{EVERY_DAYS}}`). Częstotliwość
= `judgementAuditEveryDays` z configu (domyślnie 3 dni). Nazwa taska:
`hygiene-audit-<nazwa-projektu>`.

## Zasady

- **Linter liczy, nie ocenia.** Twarde ⚠️ to sygnał do sprawdzenia, nie automatyczny defekt
  (np. cap memory może być przekroczony przez WIP build-log z open-items — to nie dług).
- **Warstwa 2 jest propose-first.** Agent NIE modyfikuje CLAUDE.md/memory sam — pisze raport
  z propozycjami do akceptacji Piotra. Wyjątek: własny raport commituje i pushuje.
- **Progi to świadome baseline'y, nie sztywne limity.** Gdy złożoność projektu rośnie —
  podnieś próg świadomie w tym samym commicie co zmiana (i zapisz *dlaczego* w `_note`),
  zamiast wycinać treść na siłę.
- **Nie generuj sztucznych znalezisk.** Czysto = krótki raport „czysto" i tyle.

## Powiązane
- `memory-discipline` — doktryna pamięci (schemat wpisu, cap, promocja, `_archive/`).
- `init-project` — zakłada config + rejestruje cron przy bootstrapie projektu.
- `bootstrap-machine` — global SessionStart hook (setup maszyny).
- `session-retro` — bieżąca aktualizacja memory; audyt to okresowy przegląd z lotu ptaka.
