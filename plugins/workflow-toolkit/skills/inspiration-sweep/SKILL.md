---
name: inspiration-sweep
description: Cykliczny przeglad zewnetrznych zrodel inspiracji (Claude Cookbook, changelog Claude Code) pod usprawnienia wlasnego toolkitu i projektow — snapshot-diff, wiec czyta TYLKO nowe pozycje. Filtruje je twarda rubryka (mapuje sie na istniejacy skill/gate? przenoszalne do Claude Code dzis? ma pomiar?), wynik → notatka w Research/ + karty w Lab. Uruchamia sie gdy user mowi "przeglad inspiracji", "inspiration sweep", "co nowego w cookbooku", "sprawdz nowe rzeczy w Claude Code", "sweep inspiracji", albo gdy odpala je zadanie cykliczne (scheduled-tasks). NIE do jednorazowego researchu tematu — do tego web-research.
---

# Skill: inspiration-sweep

## Cel

Raz na miesiac sprawdzic, czy w zewnetrznych zrodlach pojawilo sie cos, co realnie ulepszy
toolkit albo projekt — **bez czytania calosci za kazdym razem** i **bez auto-wdrazania czegokolwiek**.
Wynik to material do decyzji (notatka + karty w Lab), nie zmiana w repo.

## Auto-trigger

- „przeglad inspiracji" / „inspiration sweep" / „sweep inspiracji"
- „co nowego w cookbooku" / „sprawdz nowe rzeczy w Claude Code"
- odpalenie z zadania cyklicznego (`scheduled-tasks`)

## Dlaczego snapshot-diff, a nie przeglad

Cookbook ma ~88 pozycji i rosnie o kilka na miesiac. Przeglad calosci co miesiac to za kazdym razem
ten sam koszt tokenow i te same odrzucone pomysly wracajace jako „nowe" — czyli dokladnie ta klasa,
po ktorej rutyny cykliczne sie wylacza. Dlatego pamiec o tym, co juz przeczytane, **trzyma plik, nie
model**: `scripts/snapshot.mjs` + `state/<zrodlo>.tsv` (wersjonowane w gicie, wiec przezywa maszyne).
Brak zmian u zrodla = sweep konczy sie jedna linijka i kosztuje niemal zero.

## Zrodla (stan na 2026-08-13)

| zrodlo (`<source>`) | skad | co jest „id" |
|---|---|---|
| `cookbook` | https://platform.claude.com/cookbook/ | slug przepisu (`tool-use-memory-cookbook`) |
| `claude-code-changelog` | https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md | numer wersji (`2.1.4`) |

Nowe zrodlo dodajesz **tylko na wyrazne polecenie** — kazde dodaje staly koszt kazdego przebiegu.

## Przebieg

### 1. Pobierz indeks (jedno WebFetch per zrodlo)

Zapytanie do WebFetch ma zwrocic **plaska liste `id<TAB>tytul`**, nic wiecej — nie streszczenia.
Streszczenia sa najdrozsza czescia i maja powstac dopiero dla pozycji, ktore przejda diff.

### 2. Diff wobec snapshotu

```bash
printf '%s\n' "$LISTA" | node scripts/snapshot.mjs diff cookbook
```

Exit `0` = nic nowego → **koniec przebiegu**, zaraportuj jedna linijka („brak zmian, N pozycji
u zrodla") i nie pisz notatki. Exit `10` = sa nowe pozycje (linie `NEW\t…`).
Linie `GONE` raportuj, ale nie traktuj jako pracy — pozycja usunieta z indeksu nie staje sie
nieprzeczytana.

**`--write` dopisz DOPIERO po zakonczonym przebiegu** (patrz krok 5). Zapis przed lektura
oznacza, ze przerwany sweep cicho pominie pozycje na zawsze.

### 3. Przeczytaj nowe pozycje — subagentami, nie w sesji glownej

Nowe pozycje w paczkach po ≤5 → subagent **Haiku** (lektura mechaniczna) z poleceniem zwrotu
**maks. 120 slow per pozycja**: wzorzec w jednym zdaniu, konkretna mechanika (nazwane parametry /
kształt petli / warunek stopu), co rozwiazuje czego goly prompt nie rozwiazuje, oraz **liczby
podane w przepisie**. Zakaz rekomendacji na tym etapie — subagent ekstrahuje, nie ocenia.

Powod delegacji: kontekst subagenta nie obciaza sesji glownej, a to jest najgrubsza czesc przebiegu.

### 4. Przefiltruj rubryka (to robisz Ty, nie subagent)

Kazda nowa pozycja dostaje trzy odpowiedzi. **Kubelek A wymaga TAK na Q1 i Q2.**

- **Q1 — zaczep:** czy mapuje sie na istniejacy skill / hook / gate / regule? **Nazwij go.**
  Brak zaczepu → kubelek B (ciekawostka), nie A.
- **Q2 — przenoszalnosc:** czy mechanika jest dostepna w **Claude Code dzis**? Parametry API,
  bety (`context_management`, `advanced-tool-use`, Managed Agents, Batch, Files API) → **kubelek C**,
  jedna linia i dalej. To najczestszy wynik i trzeba go nazywac wprost, nie przemilczac.
- **Q3 — pomiar:** czy przepis podaje liczbe (oszczednosc, delta trafnosci, prog)? Bez liczby
  pozycja moze byc w A, ale **jako hipoteza** — nie jako reguła (doktryna validation-gate).

Kubelki: **A** = przenoszalne dzis (karta w Lab), **B** = wzorzec do nasladowania bez gotowej
mechaniki (tylko notatka), **C** = nieprzenoszalne (tylko notatka, jedna linia).

### 5. Zapisz wynik

1. Notatka `Research/Inspiration sweep — <YYYY-MM-DD>.md`: frontmatter (`type: research`, zrodla,
   data), TL;DR z rankingiem dzwigni, sekcje A/B/C, na koncu lista zrodel. Jesli sweep zderza sie
   z wczesniejszym przegladem tego samego zrodla — **podlinkuj go**, nie powtarzaj wnioskow.
2. Karty w **Lab** (nie To-do — to inbox pomyslow, bramke Lab→To-do przechodzi user) dla **kubelka A**:
   tytul = usprawnienie, tresc = 1 zdanie „co i po co" + nazwany zaczep z Q1 + liczba z Q3 + link do
   notatki. Skill `obsidian-kanban`, operacja B. **Propose-first: pokaz liste kart przed zapisem.**
3. `node scripts/snapshot.mjs diff <source> --write` (ten sam wsad co w kroku 2) — dopiero teraz.

## Twarde granice

- **Zero wdrozen.** Sweep nie edytuje skilli, hookow ani kodu projektu — produkuje decyzje do podjecia.
  Wdrozenie to osobna karta i osobna sesja.
- **Zero kart w To-do.** Wszystko ladzie w Lab; o promocji decyduje user.
- **Zero wysylki na zewnatrz.**
- **Nie rozdymaj zrodel.** Dwa zrodla to celowy sufit; kazde kolejne mnozy staly koszt.
- **Nie streszczaj pozycji, ktore nie przeszly diffu** — nawet jesli „wygladaja ciekawie". Byly juz raz
  ocenione; ich powrot to szum, nie sygnal. Chcesz swiadomie wrocic → `snapshot.mjs forget`.

## Zadanie cykliczne

Kanal: **`scheduled-tasks` aplikacji Claude** — nie `launchd`. LaunchAgent na katalogach chronionych
(`~/Documents`, wiec i vault) jest blokowany przez TCC i **wyglada na skonfigurowany, nie robiac nic**
(zmierzone 2026-07-31 na `kanban-archive`: log zawieral wylacznie `Operation not permitted`).

Po pierwszym odpaleniu **przeczytaj log/wynik zadania**, zanim uznasz rutyne za dzialajaca.
Zaplanowany automat bez sprawdzonego logu jest nieodroznialny od dzialajacego-cicho.

## Gotchas

- **Pusty stdin = blad, nie „brak zmian"** (`snapshot.mjs` konczy `exit 2`). Nieudany fetch nie ma
  prawa wygladac jak czysty sweep.
- **Cookbook to w wiekszosci warstwa API.** Przy pierwszym przegladzie (2026-08-13) na 23 przeczytane
  przepisy **8 wpadlo do kubelka C** jako nieprzenoszalne. To normalny rozkład — jesli wszystko ladzie
  w A, rubryka jest stosowana zbyt luzno.
- **Changelog Claude Code zmienia sie czesciej niz miesiac.** Miesieczna kadencja swiadomie akceptuje,
  ze o nowej funkcji dowiesz sie do 30 dni pozniej; nie zwiekszaj czestotliwosci bez powodu — ta
  rutyna ma byc tania.
- **Snapshot jest per-repo-toolkitu, nie per-maszyna.** Commituj `state/*.tsv` razem z wynikiem sweepu,
  inaczej druga maszyna przeczyta wszystko od nowa.

## Raport

Jedna linijka gdy brak zmian. Gdy sa: ile nowych pozycji, rozklad A/B/C, link do notatki, lista
proponowanych kart Lab — i **nazwana rekomendacja, ktore z kubelka A warto wziac pierwsze**.
