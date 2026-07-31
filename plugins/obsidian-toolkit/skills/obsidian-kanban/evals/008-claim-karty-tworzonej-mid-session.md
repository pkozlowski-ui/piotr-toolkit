---
id: obsidian-kanban-008
skill: obsidian-kanban
źródło: realna kolizja 2026-07-31 (antisis-prototype, karta długu lintowego — sesja utworzyła kartę mid-session, zaczęła na niej pracę bez claima, równoległa sesja wzięła ją z `To-do` i dostarczyła szerzej; dwa pełne cykle roboty do kosza)
status: aktywny
---

# Karta utworzona MID-SESSION i podjęta przez tę samą sesję dostaje atomowy lock — hook jej nie złapie

**Scenariusz (input):** W trakcie pracy nad kartą A sesja odkrywa poboczny dług i **tworzy nową
kartę B** (np. „Dług lintowy — 42 znaleziska"). Nazwa karty B nie pojawiła się w żadnym promptcie
usera. Sesja zamierza od razu pracować nad B (albo user mówi „to weź to teraz"). Równolegle chodzi
druga sesja, która skanuje `To-do` w poszukiwaniu następnego zadania.

**Pass:** przed pierwszą linią pracy nad B sesja woła
`kanban-claim.sh claim <dir> "<B>" <session_id>`, dostaje exit 0, ustawia `status: In progress` +
`claimed:` — więc druga sesja na `claim`/`check` dostaje exit 3 i B jest dla niej nietykalna.
Wariant parkowania: jeśli sesja NIE bierze B teraz, zostawia ją w `To-do` **bez** claima i bez
`In progress` — brak locka jest wtedy poprawnym sygnałem „wolne, bierzcie".

**Fail wygląda tak:** sesja traktuje utworzenie karty jako „autorstwo", nie „wzięcie karty", więc
protokół claim się nie odpala; karta stoi w `To-do` bez locka, wygląda na wolną i druga sesja
słusznie ją bierze. Objaw diagnostyczny, który **myli**: `.claims/` nie zawiera locka dla B, więc
przy retro łatwo orzec „mutex zawiódł" — a mutex jest sprawny, tylko **nikt go nie założył**.
Drugi wariant fail: sesja zakłada, że `kanban-claim-guard.sh` (UserPromptSubmit) załatwi sprawę —
nie może, bo guard wyprowadza nazwę karty z **promptu usera**, a kartę B żaden prompt nie nazwał.

**Jak sprawdzić:** odegraj scenariusz — utwórz kartę mid-session i zacznij nad nią pracować;
`ls <kanban>/.claims/` musi zawierać katalog dla B (pass) albo być bez niego (fail).
Kontrola negatywna na drugą gałąź: gdy sesja kartę **parkuje**, locka być NIE MOŻE — inaczej
zaparkowana karta jest zablokowana dla wszystkich do końca sesji. Test guarda:
`printf '{"session_id":"sessX","prompt":"popracujmy nad czymś innym"}' | kanban-claim-guard.sh`
nie może założyć locka na B (dowód, że hook tej ścieżki nie pokrywa i skill musi ją pokryć sam).
