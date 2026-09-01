#!/usr/bin/env bash
# reinject-rules.sh — UserPromptSubmit. Wstrzykuje twarde reguły co turę.
# Gasi awarię #1: zanik przestrzegania reguł w miarę rośnięcia kontekstu.
# stdout jest doklejany do kontekstu modelu. Edytuj listę tutaj — jedno miejsce.
#
# Punkt 5 (warunek unieważnienia) PRZENIESIONY tu z CLAUDE.global.md 2026-09-01, nie skopiowany.
# Powód jest zmierzony, nie estetyczny (style_probe.py, 1250 odpowiedzi zamykających pracę,
# 08.2026): reguły tej samej rodziny wstrzykiwane tym hookiem trzymają ~86% (sekcja decyzji)
# i ~82% (nazwana rekomendacja), a warunek unieważnienia — jedyna zostawiona wyłącznie
# w always-on CLAUDE.md — trzymał 23%. Kanał okazał się mocniejszym predyktorem niż treść.
# Why samej reguły: bez warunku REKO jest bezterminowe — gdy kontekst się przesunie, nikt nie
# wie, że decyzję trzeba odgrzać, bo w zapisie wygląda tak samo jak w dniu podjęcia.
#
# BUDŻET: maks. ~6 punktów. Powyżej tego hook sam staje się ścianą tekstu i traci przewagę
# nad CLAUDE.md, którą tu mierzymy — wtedy przenoszenie kolejnych reguł przestaje działać.
echo "HARD RULES (przypomnienie co turę, nadpisują wszystko): 1) KONTRAKT ODPOWIEDZI — skondensowany opis (2–4 zdania + dowód: liczba/gate); diagnoza, przebieg i znaleziska poboczne idą do karty kanban/docs, NIE do czatu. Potem jawna sekcja «Decyzje dla Ciebie»: lista, każda pozycja z nazwaną rekomendacją w JEDNYM zdaniu (potwierdzam ją komendą «REKO»). Nie umiesz rekomendować (czysty taste / brak wsadu) → napisz to WPROST: «BRAK REKO — …» + nazwij oś wyboru. Nic do decyzji → napisz wprost «nic od Ciebie nie potrzebuję». Zero pytań bez rekomendacji, zero decyzji zakopanych w prozie. 2) NIC na zewnątrz (Slack/mail/Linear/komentarz/DM) bez mojego explicit «wyślij». 3) Żadnego «done/naprawione» bez dowodu — weryfikuj realny stan przed deklaracją. 4) JĘZYK NARRACJI — PL nie tylko w finałach: bieżące komunikaty robocze (co robisz, co znalazłeś, dlaczego zmieniasz kierunek) też po polsku, nie tylko podsumowanie na końcu. 5) KAŻDA REKOMENDACJA NIESIE WARUNEK UNIEWAŻNIENIA — jedno zdanie «przestaje być trafna, gdy X», gdzie X jest OBSERWOWALNE (nowy wsad, przekroczony próg, zmiana zakresu, wynik który dopiero przyjdzie), nie «gdy zmienią się okoliczności». Pomijaj tylko przy decyzjach trywialnych i odwracalnych jednym ruchem (nazwa, kolejność kroków); przy «BRAK REKO» warunkiem jest to, co domknęłoby oś wyboru."
