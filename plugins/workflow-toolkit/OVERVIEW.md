# workflow-toolkit — przegląd

Uniwersalne skille workflow Claude Code (działają w każdym projekcie). Większość **auto-triggeruje się**
po kontekście — nie musisz ich wywoływać ręcznie. Ta mapa jest dla orientacji „faza pracy → skill".

| Faza / sytuacja | Skill | Trigger |
|---|---|---|
| Zakładasz nowy projekt | `init-project` | „zainicjalizuj projekt", „ustaw Claude dla tego projektu" |
| Świeży laptop / po przeprowadzce | `bootstrap-machine` | „nowy laptop", „odtwórz środowisko", „po przeprowadzce" |
| Zaraz piszesz/edytujesz kod | `coding-principles` | auto (przed każdym zadaniem kodowym) |
| Tworzysz komponent / pytasz o wzorzec | `design-system-lookup` | auto (przed nowym UI) |
| Skończyłeś zmianę UI | `browser-verify` | auto (po zmianie UI) — smoke check |
| Przed deployem na Vercel | `pre-deploy-vercel` | „deploy", „przed deployem", „vercel build" |
| Zapis/porządkowanie pamięci | `memory-discipline` | „gdzie to zapisać", „jak prowadzić pamięć" |
| Koniec sesji | `session-retro` | „zakończ sesję", „kończymy", „zrób retro" |
| Przekazanie kontekstu / kompaktowanie | `handoff` | „handoff", „przekaż kontekst" |

## Egzekucja niezawodności (hooki + verifier)
Deterministyczne guardy zamiast miękkich reguł, które gasną w długiej sesji (Anthropic: prawdziwy guardrail = hooki, nie instrukcja). Ładują się automatycznie gdy plugin włączony.

| Komponent | Zdarzenie | Co robi | Gasi |
|---|---|---|---|
| `hooks/guard-claudemd-bloat.sh` | PreToolUse (Write/Edit/MultiEdit) | blokuje edycje **powiększające** CLAUDE.md/AGENTS.md ponad 240 linii (skracające przechodzą) | bloat plików instrukcji |
| `hooks/reinject-rules.sh` | UserPromptSubmit | wstrzykuje 3 twarde reguły co turę (zwięzłość / zero-send / no-done-bez-dowodu) | zanik reguł w długiej sesji |
| `agents/verifier.md` | subagent (na żądanie) | black-box weryfikacja artefaktu vs kryteria, twarde „MUST run full check" | ciche „done" bez dowodu |

Próg bloatu i treść reguł edytujesz w plikach `hooks/*.sh` — jedno miejsce, przenośne przez `${CLAUDE_PLUGIN_ROOT}`.
**Świadomie NIE globalnie:** Stop-verify-gate (blok zakończenia przy niezweryfikowanym `git diff`) — fałszywe blokady w repo bez testów; wpinaj opt-in per repo kodowe.

## Doktryna pamięci
Trwałość oparta na git (3 warstwy: kanon repo / konwencje / dane prywatne) — pełny model w `memory-discipline`.
`init-project` zakłada pamięć git-trwałą, `session-retro` ją promuje, `bootstrap-machine` odtwarza po migracji.

## Dodawanie skilla
1. `skills/<nazwa>/SKILL.md` (frontmatter: `name`, `description` z triggerami).
2. Wiersz w tabeli wyżej.
3. Bump `version` w `.claude-plugin/plugin.json`; po pushu `claude plugin update workflow-toolkit@pkozlowski-ui-marketplace`.
