#!/usr/bin/env bash
# route-skills.sh — UserPromptSubmit. Deterministyczny routing intent→skill.
# Audyt użycia 2026-07-10 (AUDIT-USAGE.local.md): frazy triggera w description SKILL.md
# NIE egzekwują się same (missed-triggery: linear-ticket-draft 0/4 mimo dokładnych fraz,
# pre-deploy-vercel 0/1 z realnym kosztem, figma-design-workflow 0/8 sesji budowy).
# Hook = twardy kanał wg hierarchii egzekucji. stdout dokleja się do kontekstu modelu.
# Hint tylko przy trafieniu wzorca — zero szumu w pozostałych turach.
INPUT="$(cat)"
hit() { echo "$INPUT" | grep -qiE "$1"; }

# NIE dokładaj tu branchu na „komentarz do Figmy" — ZMIERZONE I ODRZUCONE (held-out gate, 2026-08-13).
# Kandydat `(draft|komentarz|odpowied)…(figma|figjam)` w oknie 40 zn., projektowany na dev-secie
# (1769 promptów przed 08-05), mierzony ślepo na held-oucie (948 promptów od 08-05):
# `held-out T: 2/12 trafione, 9 fałszywych alarmów` — czyli 9× złamany warunek blokujący soczewki T.
# Fałszywe: budowa tablic FigJam, długie prompty inżynieryjne do worktree, rozmowa „gdzie leży komentarz".
# Zaciśnięcie (wymagany czasownik proszący) schodzi do 2 przypadków, czyli pod bramkę wielkości.
# Powód strukturalny: realne prośby o taki draft NIE nazywają Figmy — kanał wynika z kontekstu sesji
# („REKO, daj draft"), więc proximity na słowie kluczowym jest złym instrumentem. Zakres skilla jest
# domknięty w SKILL.md i tam żyje; wznowienie tylko z INNYM kanałem niż proximity, nie z lepszym regexem.
if hit '(draft|opis)[^"]{0,40}linear|linear[^"]{0,40}(draft|opis|ticket)'; then
  echo "SKILL ROUTING (hook): intent 'draft/opis do Linear' → załaduj Skill workflow-toolkit:linear-ticket-draft ZANIM napiszesz treść (rejestr 'opis taska'; NIGDY nie wysyłaj bez explicit «wyślij»)."
fi
if hit 'deploy[^"]{0,40}vercel|vercel[^"]{0,40}deploy'; then
  echo "SKILL ROUTING (hook): intent 'deploy na Vercel' → PRZED git push / deployem załaduj Skill workflow-toolkit:pre-deploy-vercel (checklist łapie BLOCKED deploye i błędy builda przed wypchnięciem)."
fi
if hit '(zbuduj|stworz|stwórz|buduj|build|create)[^"]{0,60}(ekran|screen|widok|dashboard)|nowe ekrany|new screens?'; then
  echo "SKILL ROUTING (hook): intent 'budowa ekranów' → jeśli praca idzie w Figmie, załaduj figma-design-toolkit:figma-design-workflow ZANIM pierwszy figma_execute (audyt: budowa gołym figma-console = powtarzalne klasy błędów)."
fi
exit 0
