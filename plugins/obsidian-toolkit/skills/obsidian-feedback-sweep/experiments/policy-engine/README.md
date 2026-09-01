# Eksperyment: polityka skompilowana do reguł + deterministyczny silnik

**Status: WYNIK NEGATYWNY. To nie jest kanon skilla `obsidian-feedback-sweep`** — nic z tego
katalogu nie jest wpięte w `SKILL.md`. Leży tu, bo mierzalna porażka jest warta tyle, co
sukces, a harness pomiarowy jest reużywalny.

Data: 2026-09-01 · korpus: 18 domkniętych rejestrów feedback-sweep projektu Manta.

## Co testowano

Hipoteza z karty kanban (źródło: cookbook `capabilities-content-moderation-guide`):
zamienić klasyfikację i routing feedbacku z osądu modelu per komentarz na **politykę
skompilowaną raz do reguł JSON** + **deterministyczny silnik** w logice trójwartościowej.
Model wywoływany raz na pozycję, wyłącznie do ekstrakcji obiektywnych **pól**; werdykt
wydaje silnik nad trójką (reguły, pola, kontekst) — bez wywołania modelu.

## Wyniki (held-out: 43 pozycje z 7 rejestrów, których reguły nie widziały)

| wariant | typ | dyspozycja | spójność między przebiegami |
|---|---|---|---|
| **null** (zawsze klasa większościowa) | 35% | **47%** | — |
| **baseline** — osąd modelu, same osie (3 przebiegi) | 58 / 60 / 63% | 30 / 33 / 33% | 86–93% |
| **reguły podane modelowi prozą** (2 przebiegi) | 44 / 51% | **42 / 47%** | 77% |
| **deterministyczny silnik** | 47% (pokrycie 84%, precyzja 56%) | 37% (pokrycie 72%, precyzja 52%) | 100% z definicji |

Na train (110 pozycji, po 3 rundach pętli naprawczej) silnik dawał 62%/62% — czyli
**przepaść generalizacji ~25 punktów**. Pętla naprawcza przeuczyła reguły na train.

## Co z tego wynika

1. **Niespójność nie była problemem.** Premisa karty („ta sama uwaga w dwóch przebiegach
   dostaje inny kubełek") występuje w 14% pozycji, nie w większości. Determinizm sam
   w sobie kupuje mało.
2. **Trafność na osi dyspozycji jest poniżej klasy większościowej** — i to dla KAŻDEGO
   wariantu, łącznie z dzisiejszym osądem modelu. To najważniejsza liczba z całego
   przebiegu i dotyczy skilla takim, jaki jest dziś.
3. **Reguły pomagają, silnik nie.** Te same wykopane reguły podane modelowi prozą
   podnoszą dyspozycję z 33% do 42–47%; przepuszczone przez silnik dają 37%. Wartość
   siedzi w **spisaniu polityki**, nie w deterministycznej egzekucji.
4. **Trzywartościowość działa jako mechanizm.** Silnik odmawia werdyktu na 16–28% pozycji
   i nazywa blokujące pole, zamiast zgadywać. To jedyna właściwość, której żaden wariant
   modelowy nie ma — ale sama nie wystarczyła.

## Zastrzeżenie metodyczne (bez niego liczby kłamią)

Wszystkie warianty dostały **ślepy wsad**: tekst komentarza + lokalizacja. Realny sweep
widzi ekran, wątek i historię rejestru. Część luki to głód kontekstu, nie zły osąd.
Porównania między wariantami są uczciwe (ten sam wsad); **poziom bezwzględny nie jest
oceną dzisiejszego skilla w realnej pracy**.

Drugie zastrzeżenie: gold set to etykiety z jednego przebiegu jednego człowieka, nie
konsensus. Sufit tego korpusu jest nieznany.

## Pliki

| plik | co robi |
|---|---|
| `extract_goldset.py` | parsuje rejestry `Feedback Pipeline/Done/*.md` → korpus (komentarz → typ/dyspozycja/owner); tolerancyjny na 6 wariantów formatu tabeli |
| `fields.json` | schemat 12 pól ekstraktora — obiektywne atrybuty tekstu, NIE werdykt |
| `policy.md` | polityka prozą, z dowodem przy każdej regule — źródło kompilacji |
| `rules.json` | skompilowane reguły (6 typu, 11 dyspozycji) |
| `engine.py` | silnik trójwartościowy + walidator reguł; ~260 linii, zero wywołań modelu |
| `context.template.json` | szablon kontekstu projektu (macierz właścicieli) — wypełnioną wersję trzymaj przy projekcie, nie tutaj |
| `score.py` | scorer dla wariantów modelowych (trafność + spójność między przebiegami) |
| `score_engine.py` | scorer dla silnika (pokrycie × precyzja — jedna liczba by kłamała) |

Korpus z verbatim komentarzami klienta **nie jest tutaj** (repo publiczne) — leży
w prywatnym vaulcie: `Manta Vault/Feedback Pipeline/_policy-corpus/`.

## Jak powtórzyć

```bash
python3 extract_goldset.py "<vault>/Feedback Pipeline/Done" goldset.json
python3 engine.py rules.json fields.json            # sama walidacja reguł
python3 engine.py rules.json fields.json fields_heldout.json pred.json context.<projekt>.json
python3 score_engine.py heldout.json pred.json
```
