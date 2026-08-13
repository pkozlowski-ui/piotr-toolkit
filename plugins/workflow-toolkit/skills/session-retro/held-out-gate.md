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

**Licznik wywołań to GÓRNA GRANICA, nie wielkość held-outu (zmierzone 2026-08-13).** Zanim uznasz
bramkę za przeszłą, odejmij od niego:
- **case'y „nie dotyczy"** — wywołania, w których testowana reguła nie miała zastosowania (reguła
  o linkach, a draft bez linków). „Nie dotyczy" nie jest dowodem, że reguła działa;
- **case będący ŹRÓDŁEM fixa** — wpadka, po której regułę napisano, wpada do held-outu, gdy fix
  poszedł tego samego dnia (granica idzie po dacie, nie po „przed/po wpadce"). To dev-set, nie held-out.

Realny przypadek: `linear-ticket-draft`, reguła „zero linków do PR", zmiana 2026-08-10 → skrypt
zaraportował 4 wywołania („≥ 3, oceniaj"), a ocenianych przypadków było **2** (jeden draft bez linków,
jeden = MAN-825, źródło fixa). Werdykt brzmi wtedy „za mało danych", mimo zielonej bramki skryptu.

### Rubryka zależy od tego, CO zmieniłeś — dwie soczewki, nie jedna

Rozstrzygnij to **zanim** wybierzesz rubrykę, bo pomyłka daje liczby ortogonalne do zmiany:

**Soczewka T (zmiana triggera)** — ruszyłeś `description`, frazy triggera, hook routingu.
Werdykt per wywołanie: **trafiony** / **pominięty** (skill powinien wejść i nie wszedł) / **fałszywy
alarm** (wszedł, gdzie nie powinien). Pominięcia są najdroższą klasą i najłatwiej je przegapić, bo
w transkrypcie nie ma czego szukać — trzeba czytać prompty, w których skilla *brak*.

**Soczewka C (zmiana treści reguły)** — ruszyłeś to, co skill *nakazuje* w środku (format, zakazy,
struktura outputu). Werdykt **per wymaganie, nie per wywołanie**: **spełnione** / **złamane** /
**nie dotyczy**. Wypisz wymagania jako osobne, sprawdzalne punkty (R1, R2, …) i oceniaj każdy z nich
niezależnie na każdym case'ie.

**Nie mieszaj soczewek — soczewka T nie mierzy zmiany treści i nie może jej zmierzyć.** Gdy trigger
jest wymuszany twardym kanałem (hook `route-skills.sh` i pokrewne), liczba trafień odbija **regex
hooka**, nie treść `SKILL.md`: edycja treści nie przesunie jej ani w górę, ani w dół. Zmierzone
2026-08-13 na trzech sierpniowych fixach `linear-ticket-draft` — wszystkie trzy były zmianami treści,
a soczewka T dała `7/10 trafione, 2 fałszywe` przy baseline dev-setu `17/19, 1 fałszywy`, czyli liczbę
kompletnie niezależną od tego, co zmieniono. Soczewka C na tym samym held-oucie dała werdykt użyteczny:
`6/6 spełnione, 0 złamań` dla reguły jednej listy linków.

### Soczewkę T na deterministycznym triggerze mierz OFFLINE — nie czekaj na wywołania po zmianie

Gdy trigger jest regexem w hooku, kandydata da się ocenić **przed** wdrożeniem, bo funkcja jest
deterministyczna: aplikujesz go na korpusie promptów i patrzysz, co łapie ponad obecny wzorzec.
Podział czasowy zostaje w mocy, tylko przenosi się na korpus:

- **regex PROJEKTUJESZ na dev-secie** (prompty przed datą zmiany) — tam wolno patrzeć na trafienia
  i dostrajać okno;
- **regex MIERZYSZ na held-oucie** (prompty od daty zmiany) — tam nie wolno nic dostrajać, bo pierwszy
  powrót do regexa po zobaczeniu wyniku zamienia held-out w dev-set;
- **oceniane przypadki** = prompty, które łapie KANDYDAT, a nie łapie obecny wzorzec. Pozostałe to
  „nie dotyczy" — kandydat nic w nich nie zmienia;
- korpus musi być tym, co hook realnie widzi: prompty usera bez sidechainów subagentów, bez meta
  i `<task-notification>`. Wpuszczenie sidechainów zawyża i trafienia, i fałszywe alarmy.

Zmierzone 2026-08-13 (`linear-ticket-draft`, kandydat „komentarz do Figmy"): dev-set 1769 promptów,
held-out 948, kandydat łapał ponad wzorzec 13 promptów, ocena ślepa dała
`held-out T: 2/12 trafione, 9 fałszywych alarmów` → odrzucone, zero wdrożeń, zero czekania na sesje.

**Gdy oba końce zawodzą naraz, problem jest w instrumencie, nie w progu.** Rozluźnienie regexa mnoży
fałszywe alarmy, a zaciśnięcie zbija liczbę ocenianych przypadków pod bramkę wielkości — i to jest
sygnał, że intent nie mieszka w słowach kluczowych promptu (tu: kanał odpowiedzi wynikał z kontekstu
sesji, nie z treści promptu — „REKO, daj draft"). Wtedy **werdyktem jest „inny kanał", nie „lepszy
regex"**; szukaj wsadu, którego proximity nie widzi, albo zostaw regułę w treści skilla.

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
2. **Held-out ≥ 3 przypadków OCENIANYCH** (po odjęciu „nie dotyczy" i case'a-źródła — patrz wyżej;
   licznik wywołań ze skryptu nie wystarcza) i większość werdyktów po nowej wersji nie gorsza niż
   po starej, **w soczewce właściwej dla zmiany**.
3. **Warunek blokujący dotyczy tylko soczewki, którą zmiana rusza:**
   - **zmiana triggera (T)** → **zerowy nowy fałszywy alarm**. Blokuje utwardzenie nawet przy poprawie
     czułości: skill wchodzący nieproszony kosztuje więcej niż skill, którego trzeba zawołać.
   - **zmiana treści (C)** → **zerowe nowe złamanie** któregokolwiek wymagania, którego zmiana dotyczy.
     Fałszywe alarmy w soczewce T **NIE blokują** zmiany treści — zmierzone 2026-08-13: literalne
     zastosowanie starego warunku blokowało trzy fixy treści za dwa fałszywe alarmy pochodzące z regexa
     hooka i własnej inicjatywy modelu, czyli za coś, czego te fixy nie tykały.
4. **Wynik zapisany z liczbą** — w commit message albo w karcie, **z nazwaną soczewką**:
   `held-out T: 8/10 trafione, 0 fałszywych` albo `held-out C: R2 6/6 spełnione, 0 złamań`.
   Bez liczby to nie gate, tylko wrażenie; bez soczewki nie wiadomo, czego liczba dotyczy.

Nie masz kompletu → **oznacz zmianę jako HIPOTEZĘ** (w SKILL.md albo w karcie), nie jako kanon,
**i dopisz ją do `hipotezy-otwarte.md`** — z warunkiem wznowienia i komendą, która go sprawdza.
Adnotacja bez wpisu w rejestrze nie ma wywoływacza: retro czyta rejestr (krok 4b), a treści skilla
pod tym kątem nie przegląda. To jest normalne i tanie; udawany gate nie jest.

## Czego NIE robić

- **Nie liczyć `evals/` jako held-outu.** To specyfikacja. Może rosnąć równolegle — i powinna.
- **Nie wybierać kubełka z pamięci** („weźmy te trzy sesje, gdzie to widziałem"). Zawsze zawiera to,
  co zmianę zainspirowało. Granica idzie po dacie albo nie ma granicy.
- **Nie foldować reguły z jednego przypadku** bez sprawdzenia, że nie psuje reszty — to ta sama pętla
  retro→gate, tylko widziana od drugiej strony.
- **Nie oceniać pominięć, gdy skill nie ma domkniętego zakresu.** Klasa „pominięty" znaczy „powinien
  wejść i nie wszedł" — a to jest rozstrzygalne tylko wtedy, gdy wiadomo, co należy do rejestru skilla.
  Zmierzone 2026-08-13: jedyny kandydat na pominięcie `linear-ticket-draft` okazał się draftem
  komentarza do Figmy, a `SKILL.md` rozciągał swoją dyscyplinę na Figma-comment drafty, nie mówiąc,
  czy sam ma tam wchodzić → werdykt nierozstrzygalny. **Napotkasz taką lukę → najpierw domknij zakres
  w `SKILL.md`, potem oceniaj pominięcia.**
- **Nie mierzyć adopcji zamiast trafności.** Wzrost wywołań może oznaczać rozlazły trigger. Liczby
  z `adoption_scan.sh` są wsadem, nie werdyktem.
