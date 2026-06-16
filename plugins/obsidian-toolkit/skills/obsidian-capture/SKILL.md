---
name: obsidian-capture
description: Gest „promote to vault" — bierze gotowy, trwały artefakt (decyzja+uzasadnienie, spec/wymagania, synteza researchu, notatki ze spotkań) i zapisuje go jako poprawną notatkę we właściwym folderze vaultu z frontmatter + backlinkami. Uruchamia się gdy user mówi (EN+PL) "zapisz to do vaultu", "promuj do vaultu", "udokumentuj tę decyzję", "to warto zachować", "capture", "save to vault", "document this decision", "worth keeping", lub gdy karta Done / przemyślenie z Lab jest warte pamięci.
---

# Skill: obsidian-capture

## Cel
Sprawić, by Obsidian był naturalnym miejscem na **wartościową dokumentację dla człowieka**. Bierzesz gotowy
artefakt z sesji/tablicy i zapisujesz go jako trwałą notatkę we właściwym folderze — z frontmatter i backlinkami,
nie jako luźny wrzut. To lustrzane odbicie `session-retro`: tamten promuje wiedzę do **pamięci agenta** (git),
ten promuje do **dokumentacji dla człowieka** (vault).

## Auto-trigger
- "zapisz to do vaultu" / "promuj do vaultu" / "udokumentuj to" / "to warto zachować" / "capture"
- karta **Done** warta pamięci dla zespołu (hook z `obsidian-kanban`)
- przemyślenie z **Lab** warte zachowania
- sesja wyprodukowała trwałą **decyzję / spec / syntezę researchu / notatki ze spotkania**

## Wymagania
- **MCP `obsidian`** (`mcp__obsidian__*`) do zapisu/edycji notatek + dostęp do plików vaultu do ew. przeniesień. Brak `mcp__obsidian__*` → najpierw skill `obsidian-setup`.

## Brama promocji (co graduuje — a co NIE)
Promuj tylko **trwałe + dla człowieka**. Cztery kategorie:
1. **Decyzje + uzasadnienia** — co zdecydowano, *dlaczego*, jakie opcje odrzucono.
2. **Specy / wymagania** — requirements, user stories, IA, definicje zakresu.
3. **Synteza researchu** — wnioski z analiz, konkurencji, wywiadów, archetypy.
4. **Notatki ze spotkań** — ustalenia, decyzje, action items.

**NIE promuj** (zostaw efemeryczne / w innej warstwie):
- plany, które robi agent, rozumowanie pośrednie, scratch → nigdzie (efemeryczne),
- reguły/gotchy/ID/konwencje *dla agenta* → `.claude/memory` + `CLAUDE.md` (to robota `session-retro`, nie tu).
> Decyzja bywa dwustronna: **ADR-owy „dlaczego" → vault** (dla człowieka) + **1-liniowa reguła → CLAUDE.md** (dla agenta). To nie dublowanie — różne warstwy, różni odbiorcy.

## Protokół

### 1 — Bramka
Czy artefakt jest trwały i dla człowieka (jedna z 4 kategorii)? Jeśli nie — **nie zapisuj do vaultu**; zaproponuj właściwą warstwę (memory / efemeryczne) i skończ.

### 2 — Kategoria + folder docelowy (routing by-temat, nie by-typ)
Vault organizowany **tematycznie** — kieruj notatkę do istniejącego folderu tematu (odkryj strukturę vaultu),
a **typ** zapisz we frontmatter (`type: decision|spec|research|meeting`). Nie twórz płaskiego folderu „Decisions",
chyba że vault już tak działa. Przy niejasności — zaproponuj 2 najlepsze foldery i rekomendację.
(Manta: `Anti SIS Strategy/` · `Anti SIS Staff|Guardian Experience/` · `Design Guidelines/`; mapping → config projektu.)

### 3 — Zapisz notatkę (propose-first)
Tytuł rzeczowy (nie „Notatka 1"). Frontmatter + treść wg szablonu kategorii (`reference/templates.md`).
Pokaż treść **przed** zapisem. Aktualizuj istniejącą notatkę zamiast tworzyć duplikat, jeśli temat już jest.

### 4 — Backlinki w obie strony
- Nowa notatka linkuje do **źródła**: karta Kanban, rejestr feedbacku, plik/board Figma (URL), repo/PR.
- W źródle zostaw **pointer** do nowej notatki (wikilink listą, w cudzysłowach).

### 5 — Domknij źródło
- Promocja z **karty Done** → zaproponuj **archiwizację** karty (`mv` do folderu archiwum boardu; **nie kasuj** — spójnie z `obsidian-kanban`).
- Promocja z **Lab** → zaproponuj usunięcie przemyślenia z inboxu (już żyje w vaulcie) — sygnalizuj, że to destrukcyjne.

## Frontmatter (wzór)
```
---
type: decision | spec | research | meeting
created: YYYY-MM-DD
source: "[[karta/rejestr]]" | Figma URL | repo
status: draft | accepted        # dla decyzji/spec
---
```

## Gotchas
- **Routing by-temat**, nie po typie — szanuj istniejącą strukturę vaultu (odkryj foldery, nie zakładaj).
- **Wikilinki we frontmatter** → lista w cudzysłowach (`source:\n  - "[[X]]"`), inaczej psują parsing (patrz feedback-sweep/kanban).
- **Nie dubluj `session-retro`** — kanon agenta (reguły/gotchy/ID) idzie do memory, nie do vaultu.
- **Nie promuj efemeryd** — jeśli to plan/scratch, odmów grzecznie i wskaż właściwą warstwę.
- **Propose-first** — pokaż notatkę + miejsce zapisu przed utworzeniem; aktualizuj istniejące zamiast duplikować.

## Raport
Co zapisano i gdzie (folder + typ), jakie backlinki dodano, co zaproponowano domknąć w źródle (karta/Lab).
