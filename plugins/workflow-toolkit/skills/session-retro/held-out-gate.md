# Held-out gate — jak sprawdzić, że zmiana reguły faktycznie jest lepsza

> Wykonuje doktrynę validation-gate: „waliduj na przykładach **nieużytych do wymyślenia zmiany**".
> `evals-convention.md` mówi, GDZIE żyją taski. Ten plik mówi, **skąd wziąć held-out** i **kiedy
> wolno powiedzieć „lepsza"**. Cross-plugin, jak cała konwencja.

## Problem, który to zamyka

Task w `evals/` powstaje z realnej wpadki, a jego „Pass" pisze ta sama sesja, która wpadkę zobaczyła
i wymyśliła poprawkę. Taki task jest **specyfikacją**, nie held-outem: przechodzi z definicji, bo
regułę napisano pod niego. Dlatego zbiór `evals/` może rosnąć, a pytanie „czy nowa wersja jest lepsza
od starej" pozostaje **nierozstrzygnięte** — i tak właśnie stało u mnie
(`eval 001`, `eval 004`: „niezwalidowany behawioralnie, held-out otwarty").

Held-out nie jest cechą treści przykładu. Jest cechą **kolejności**: przykład musi powstać *po*
regule albo *bez wiedzy o niej*.

## Dwa źródła held-outu

### A. Podział czasowy na realnych sesjach (domyślne, mocniejsze)

Wywołania skilla **po** dacie zmiany są held-outem z konstrukcji — nikt ich nie widział, pisząc
regułę, i są prawdziwe, nie wymyślone.

```bash
plugins/workflow-toolkit/skills/usage-audit/scripts/heldout_split.sh \
  workflow-toolkit:linear-ticket-draft 2026-08-05
```

Skrypt zwraca dev-set (okno przed zmianą — to, na czym zmiana powstała), held-out (od zmiany do dziś)
i **werdykt o wielkości held-outu**. Poniżej 3 wywołań kończy `exit 1`: „za mało danych" jest legalnym
wynikiem, „przeszło na jednym przykładzie" nie jest.

Werdykt per wywołanie, binarny: **trafiony** / **pominięty** (skill powinien wejść i nie wszedł) /
**fałszywy alarm** (wszedł, gdzie nie powinien). Pominięcia są najdroższą klasą i najłatwiej je
przegapić, bo w transkrypcie nie ma czego szukać — trzeba czytać prompty, w których skilla *brak*.

### B. Triggery syntetyczne (uzupełnienie, gdy A jest za mały)

Dwustopniowo (za cookbookiem `misc-generate-test-cases`, bo naiwne „wygeneruj 10 przykładów" daje
dziesięć wariantów tego samego zdania):

1. **Plan.** Wypisz najpierw, jak wygląda **rozkład** realnych promptów dla tego skilla: język
   (PL/EN/mieszany), długość, forma (rozkaz / pytanie / rzucone hasło), literówki, ile razy trigger
   jest zakopany w środku dłuższego promptu, jak często sąsiaduje z „REKO"/„koniec sesji".
   Wsad na plan bierz z realnych wywołań (źródło A), nie z wyobraźni.
2. **Generuj z planu**, trzymając ten rozkład — i **osobno przypadki negatywne** (prompty, przy których
   skill wejść NIE powinien). Zbiór bez negatywów mierzy czułość i milczy o fałszywych alarmach, więc
   każda rozlazła reguła go przechodzi.

Ocena **ślepa**: oceniający dostaje prompt i pyta „czy skill powinien się odpalić", nie widząc, która
wersja reguły jest testowana. Praktycznie = subagent bez historii sesji (`workflow-toolkit:verifier`).

**Granica syntetyku, wprost:** waliduje **rozpoznawanie triggera**, nie **wartość reguły**. Że skill
odpalił się na wygenerowanym zdaniu, nie znaczy, że jego treść jest lepsza niż tydzień temu.

## Kiedy wolno powiedzieć „lepsza"

Wszystkie trzy naraz:

1. **Brak regresu na dev-secie** — aktywne taski `evals/` nadal przechodzą (`evals-convention.md`, krok 2).
2. **Held-out ≥ 3** i większość werdyktów po nowej wersji nie gorsza niż po starej, **przy zerowym
   nowym fałszywym alarmie**. Nowy fałszywy alarm blokuje utwardzenie nawet przy poprawie czułości —
   skill wchodzący nieproszony kosztuje więcej niż skill, którego trzeba zawołać.
3. **Wynik zapisany z liczbą** — w commit message (`held-out: 8/10 trafione, 0 fałszywych`) albo
   w karcie. Bez liczby to nie gate, tylko wrażenie.

Nie masz kompletu → **oznacz zmianę jako HIPOTEZĘ** (w SKILL.md albo w karcie), nie jako kanon.
To jest normalne i tanie; udawany gate nie jest.

## Czego NIE robić

- **Nie liczyć `evals/` jako held-outu.** To specyfikacja. Może rosnąć równolegle — i powinna.
- **Nie wybierać kubełka z pamięci** („weźmy te trzy sesje, gdzie to widziałem"). Zawsze zawiera to,
  co zmianę zainspirowało. Granica idzie po dacie albo nie ma granicy.
- **Nie foldować reguły z jednego przypadku** bez sprawdzenia, że nie psuje reszty — to ta sama pętla
  retro→gate, tylko widziana od drugiej strony.
- **Nie mierzyć adopcji zamiast trafności.** Wzrost wywołań może oznaczać rozlazły trigger. Liczby
  z `adoption_scan.sh` są wsadem, nie werdyktem.
