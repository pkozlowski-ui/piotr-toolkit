# motion-toolkit

Warstwa **motion craft dla UI w kodzie** — obszar, którego w toolkicie nie było wcale
(zmierzone 2026-09-02: wzmianki o easing/motion w `design-toolkit` = 1, w `ui-polish-loop`
i `code-design-audit` = 0).

Treść merytoryczna jest vendorowana 1:1 z `emilkowalski/skills` (MIT) — patrz [UPSTREAM.md](UPSTREAM.md).
Nasza warstwa to **kontekstowe komendy** w `commands/`, bo triggery w `description` same się nie
egzekwują (audyt użycia 2026-07-10).

## Komendy

| Komenda | Robi |
|---|---|
| `/motion-toolkit:animate <co>` | buduje animację od zera — krzywa, czas, właściwości, przerywalność, reduced-motion |
| `/motion-toolkit:review-motion [zakres]` | strict review ruchu w diffie; werdykt Block/Approve (skill ma `disable-model-invocation`, więc odpala się tylko stąd) |
| `/motion-toolkit:motion-audit [obszar]` | audyt motion całego projektu → ranking + plany dla tańszych modeli |
| `/motion-toolkit:motion-ideas [ekran]` | gdzie warto dodać ruch — z obowiązkową listą odrzuconych |
| `/motion-toolkit:motion-name <opis>` | opis efektu → precyzyjny termin (do ticketu / komentarza) |

## Granice wobec reszty toolkitu

- **Figma ≠ ten plugin.** Prototypy w Figmie mają globalną regułę `INSTANT` (brak animacji);
  te skille dotyczą wyłącznie ruchu w kodzie. Zero konfliktu, ale i zero przenoszenia w drugą stronę.
- **`design-toolkit:design-tweaker`** ma 7 soczewek i żadnej dla ruchu — soczewka „Motion"
  delegująca tutaj to **tura druga**, świadomie niezrobiona, dopóki nie ma pomiaru, że te komendy
  faktycznie się odpalają tam, gdzie chcę (validation-gate).
- **`workflow-toolkit:browser-verify`** zostaje kanałem dowodu po zmianie — „gotowe" bez dowodu
  obowiązuje tu tak samo.

## Otwarte (tura druga, po pomiarze)

1. Soczewka 8 „Motion" w `design-tweaker` + wymiar motion w `code-design-audit` / `ui-polish-loop`.
2. Sekcja **motion spec** (tabela durations/easing) w `figma-handoff-prep` — to jedyne miejsce,
   gdzie ta wiedza staje się deliverable dla devów.
3. Branch w `route-skills.sh` na intent „animacja/motion" — dopiero gdy będzie dev-set i held-out,
   nie z lepszego regexa.
