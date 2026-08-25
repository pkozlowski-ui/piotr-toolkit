---
id: session-retro-003
skill: session-retro
źródło: realna sesja 2026-08-25 (PR 26 educator-os-demo) — krok 4b zapisany do kopii w plugin-cache, potem `cp cache → repo` wywalił 93 linie werdyktów
status: aktywny
---

# Krok 4b edytuje rejestr hipotez w REPO ŹRÓDŁOWYM, nie w katalogu, z którego skill się załadował

**Scenariusz (input):** Retro dochodzi do kroku 4b. Skill został załadowany z
`~/.claude/plugins/cache/<marketplace>/workflow-toolkit/<wersja>/skills/session-retro/`, a repo
źródłowe (`piotr-toolkit`) ma NOWSZĄ wersję `hipotezy-otwarte.md` — poprzednie retro dopisało tam
werdykty, których cache jeszcze nie widzi.

**Pass:** Zapis przebiegu idzie do `piotr-toolkit/plugins/workflow-toolkit/skills/session-retro/hipotezy-otwarte.md`,
edycja jest **przyrostowa na aktualnej treści tego pliku** (dopisana linia/blok), a po edycji
`git diff --stat` pokazuje same dodania — albo dodania wyraźnie przewyższające usunięcia.

**Fail wygląda tak:** (a) zapis do ścieżki cache — ginie przy następnej aktualizacji pluginu,
zero śladu; albo (b) „synchronizacja" przez `cp cache → repo` / przepisanie pliku całością —
kasuje werdykty zapisane w repo przez poprzednie retro. Realny objaw: `1 file changed,
28 insertions(+), 93 deletions(-)` przy intencji „dopisuję jedną linię", w tym utrata zamkniętego
branchu wariantu A z hipotezy H1.

**Jak sprawdzić:** Rozjedź celowo obie kopie (dopisz linię w repo, nie w cache), odpal retro na
sesji z otwartymi hipotezami i sprawdź: (1) czy zmiana wylądowała w repo, (2) czy dopisana linia
z kroku (1) nadal tam jest, (3) czy `git diff --stat` nie raportuje masowych usunięć.
