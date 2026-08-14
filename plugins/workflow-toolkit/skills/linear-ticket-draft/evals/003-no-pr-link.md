---
id: linear-ticket-draft-003
skill: linear-ticket-draft
źródło: regresja MAN-825 (2026-08-10) — draft opisu zawierał 2 linki do GitHub PR (#323, #328) w
  sekcji "Links"; Piotr poprawił to samo ≥3. raz ("pare razy juz Ci to pisalem")
status: aktywny
---

# Draft do Linear nigdy nie zawiera linku do GitHub PR

**Scenariusz (input):** Sesja dostarczyła feature z konkretnymi PR-ami (znane numery/URL-e),
user prosi o draft opisu/komentarza do Linear podsumowujący robotę.

**Pass:** Draft nie zawiera żadnego `github.com/.../pull/...`. Sekcja `**Links**`/`**Figma**`
zawiera tylko deliverable-level linki (prototyp/Vercel, Figma per-ekran/sekcja) — nigdy PR jako
przykład czy pozycję na liście.

**Fail wygląda tak:** Draft dodaje bullet `- PR: https://github.com/.../pull/NNN` "dla
transparentności" albo bo poprzednia wersja skilla wymieniała "PR, repo" jako przykład treści
sekcji Links (SKILL.md przed 2026-08-10 to explicite dopuszczał w punkcie 6 struktury).

**Jak sprawdzić:** Po wygenerowaniu draftu zgrepuj treść po `github.com` i `/pull/` — 0 trafień.
Baseline przed fixem: 1/1 draft (MAN-825) miał 2 linki PR.

---

**Warstwa bramy (CLI, 2026-08-14).** Case żyje jako `003-no-pr-link/` z darmowym graderem `regex`
(`not_contains` na `github\.com/[^\s)]*/pull/`). Prompt jawnie prosi o „sam draft, bez komentarza" —
bez tego zastrzeżenia regex karałby odpowiedź za zdanie „PR-y celowo pomijam", czyli za poprawne
wytłumaczenie reguły (ta sama klasa buga, która wywaliła gradery z `obsidian-kanban` 006 i 009).
`criteria` niesie tę granicę jawnie w uwadze dla oceniającego.
