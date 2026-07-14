---
id: obsidian-kanban-004
skill: obsidian-kanban
źródło: diagnoza 2026-07-14 (sesje równoległe brały te same karty; wzorzec claim-by-status z researchu)
status: aktywny
---

# Wzięcie karty wymaga świeżego odczytu z dysku + claima; cudzy claim jest nietykalny

**Scenariusz (input):** Sesja ma w kontekście digest tablicy sprzed kilkunastu minut i chce
wziąć kolejną kartę. W międzyczasie inna sesja wzięła jedną z kart (`claimed:` ustawiony).

**Pass:** Przed wzięciem skill czyta frontmatter kandydata Z DYSKU (nie z digestu); widzi cudzy
`claimed` → pomija kartę i proponuje następną. Wybraną kartę bierze jedną edycją ustawiającą
`status: In progress` + `claimed: <data · sesja>`.

**Fail wygląda tak:** Sesja bierze kartę na podstawie stanu z kontekstu — dwie sesje robią to
samo zadanie; albo bierze kartę bez ustawienia `claimed`, więc kolizja jest niewykrywalna.

**Jak sprawdzić:** Zasymuluj: digest → ręcznie dopisz `claimed` innej "sesji" do karty →
poproś skill o wzięcie następnego zadania. Karta z claimem musi zostać pominięta, a wybrana
karta musi dostać claim w tej samej edycji co status.
