---
id: obsidian-feedback-sweep-004
skill: obsidian-feedback-sweep
źródło: sesja 2026-07-21 (rozszerzenie o oś delight) — pozytyw i inspiracja lądowały w koszu „No action", ulotny sygnał „co ląduje u kogo" przepadał zamiast budować profil stakeholderów
status: aktywny (NIEZWALIDOWANY behawioralnie — held-out gate otwarty)
---

# Pozytyw/inspiracja promowana do trwałej kolekcji Delight, nie do kosza „No action"

**Scenariusz (input):** Sweep (albo ręczny gest „zapisz do delight") napotyka sygnał pozytywny:
pochwałę z realną treścią („podoba mi się, jak ta karta oddycha — dużo whitespace") albo podrzuconą
inspirację/referencję („zróbmy nagłówki jak w tym dashboardzie <link>"). Projekt ma skonfigurowany
folder Delight.

**Pass:**
1. Item klasyfikowany jako ✨ (inspiracja) lub 💬 (pochwała) **z wartością** → dyspozycja
   `Capture → Delight`, NIE `No action`.
2. Wpis trafia do **osobnej kolekcji Delight** (`type: delight-log`), nie do rotowanego rejestru feedbacku.
3. Wpis ma wszystkie 6 pól, w tym **`Dlaczego zadziałało`** i **`Jak reużyć`** (bez nich = fail: to pamiętnik).
4. Wpis ma tag/property `#osoba` → zasila profil per-stakeholder.
5. Cytat „verbatim" pochodzi z żywego fetcha (nie z pamięci).
6. Kolekcja Delight **nie** dostaje `status`/`done`/archiwizacji i **nie** tworzy karty na Kanbanie.
7. Raport końcowy zawiera linię „Delight: N wpisów → [[…]] (kto)".

**Fail wygląda tak:** Pozytyw ląduje w `No action` i przepada. ALBO wpis idzie do rejestru feedbacku
(zostanie zarchiwizowany przy `done`). ALBO wpis to goły cytat bez `Dlaczego`/`Jak reużyć` (anegdota,
nie narzędzie). ALBO kolekcja dostaje cykl życia (`status`, `Done/`) i przestaje być wieczną bazą.
ALBO „verbatim" konfabulowany z pamięci.

**Jak sprawdzić:** (a) podaj skillowi mieszankę komentarzy z 1–2 pozytywnymi/inspiracją; sprawdź, że
pozytyw dostał `Capture → Delight` i wylądował w kolekcji Delight z 6 polami; (b) sprawdź, że rejestr
feedbacku ich NIE zawiera; (c) sprawdź frontmatter kolekcji = `delight-log` bez `status`.

**Uwaga (validation-gate):** brak obiektywnego held-out checku — to feature-hipoteza z osądu, nie
zwalidowany kanon. Utwardzić dopiero po ≥1 realnym przebiegu na żywym sweepie, gdy widać, że podział
`Delight` vs `No action` trafia bez false-positive'ów (pochwała bez treści reużycia NIE ma iść do Delight).
