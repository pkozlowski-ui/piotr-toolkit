---
id: obsidian-feedback-sweep-005
skill: obsidian-feedback-sweep
źródło: sesja 2026-07-22 (Feedback sweep 2026-07-22, antisis prototype) — figma_get_comments bez jawnego fileUrl czyta tylko aktualnie aktywny/domyślny plik. Nowa aktywność Dominique+Kara żyła na OSOBNYM pliku ("Anti-SIS - Collaboration Board", FigJam), nie na głównym design file. Sweep na samym design file wykazał 0 nietriażowanych wątków — gdyby kanban-trigger card nie nazwała FigJam boardu wprost z nazwy, ta aktywność zostałaby przeoczona i sweep błędnie zgłosiłby "nic nowego".
status: aktywny
---

# CAPTURE enumeruje WSZYSTKIE pliki Figma projektu z aktywnymi komentarzami, nie tylko domyślny

**Scenariusz (input):** Projekt ma więcej niż jeden plik Figma z aktywnymi komentarzami (główny
design file + FigJam collaboration board, albo kilka design files). Sweep woła `figma_get_comments`
bez jawnego `fileUrl` (lub tylko dla jednego znanego pliku) i na tej podstawie ocenia "czy jest coś
nowego".

**Pass:** Faza CAPTURE explicite sprawdza / pyta, czy projekt ma dodatkowe pliki Figma poza tym
aktualnie otwartym w Desktop Bridge (design file(s), FigJam boardy referencjonowane w istniejących
rejestrach/memory — np. `Board — Registrar · Recruiter · Pre-lottery` już nazywał ten konkretny
FigJam file_key) — i ciągnie komentarze z KAŻDEGO z nich, zanim zadeklaruje "brak nowej aktywności".

**Fail wygląda tak:** Sweep czyta tylko jeden plik (domyślny/aktywny `fileUrl`), deklaruje "nic
nowego do triażu" mimo nierozwiązanej aktywności na innym pliku tego samego projektu. Realnie
uniknięte tylko dzięki temu, że kanban-trigger card nazwała FigJam board z nazwy — bez tej
podpowiedzi sweep by to przegapił.

**Jak sprawdzić:** Uruchom sweep na projekcie z ≥2 plikami Figma (design file + FigJam board, oba
z aktywnymi komentarzami). Potwierdź, że wynikowy rejestr wymienia oba źródła po nazwie/file_key i
że komentarze z obu zostały faktycznie pobrane (nie tylko z pliku aktywnego w Desktop Bridge).
