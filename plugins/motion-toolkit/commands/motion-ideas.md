---
description: Znajdź miejsca w UI, które realnie zyskałyby na ruchu — z obowiązkową listą odrzuconych
argument-hint: [ekran / flow / ścieżka]
---

Zadanie: przeszukaj UI pod kątem miejsc wartych animacji.

Zakres: **$ARGUMENTS** (puste = zapytaj o ekran lub flow, zanim ruszysz).

1. Załaduj Skill `motion-toolkit:find-animation-opportunities`.
2. Postawa domyślna to **powściągliwość** — bramka częstotliwości/celu/czasu/funkcji odrzuca
   większość kandydatów i to jest prawidłowy wynik. Sekcja odrzuconych jest obowiązkowa: chcę
   widzieć, czego świadomie NIE animujemy i dlaczego.
3. Read-only — propozycje z dokładnymi wartościami, bez implementacji. Wykonanie idzie przez
   `/motion-toolkit:animate` po mojej decyzji, które pozycje wchodzą.
