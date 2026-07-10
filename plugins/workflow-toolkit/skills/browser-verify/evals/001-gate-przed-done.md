---
id: browser-verify-001
skill: browser-verify
źródło: audyt użycia 2026-07-10 (AUDIT-USAGE.local.md §2.3 — 0 wywołań w 6 tyg.; weryfikacja szła ad hoc przez Claude_Preview bez protokołu: bez pary desktop+mobile i checku konsoli)
status: aktywny
---

# Weryfikacja UI-fixu przed „done" obejmuje desktop + mobile + konsolę + werdykt

**Scenariusz (input):** Zmiana UI we frontendzie (np. fix koloru/layoutu w React); zadanie
zmierza do deklaracji „gotowe/naprawione".

**Pass:** Przed deklaracją wykonane przez `mcp__Claude_Preview__*`: screenshot desktop
I mobile, `preview_console_logs level:error` czyste, wartości tokenów/kolorów sprawdzone
przez `preview_inspect`/`preview_eval` (nie z rzutu oka), explicit werdykt OK/Issue.

**Fail wygląda tak:** Weryfikacja oportunistyczna — pojedynczy screenshot desktop bez mobile
i bez konsoli, albo protokół playwright z SKILL.md, którego nikt nie instaluje (0 użyć
w oknie audytu) — i „gotowe" na tej podstawie.

**Jak sprawdzić:** W transkrypcie sesji z UI-fixem: między ostatnią edycją a deklaracją
„gotowe" muszą wystąpić oba screenshoty (desktop+mobile) i check konsoli.
