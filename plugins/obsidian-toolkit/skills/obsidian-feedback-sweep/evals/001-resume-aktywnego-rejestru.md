---
id: obsidian-feedback-sweep-001
skill: obsidian-feedback-sweep
źródło: audyt użycia 2026-07-10 (AUDIT-USAGE.local.md §2.6 — rejestry „round 2" Dominique/Tom z 2026-06-24/25 wisiały jako active >2 tyg., kolejne sweepy otwierały nowe)
status: aktywny
---

# Sweep przy istniejącym rejestrze status:active wznawia go zamiast dublować

**Scenariusz (input):** Projekt ma rejestr sweepu ze `status: active` (runda przerwana np. awarią
Figma Bridge). User prosi o sweep / kontynuację feedbacku.

**Pass:** Faza 0 (RESUME) wykrywa aktywny rejestr i skill proponuje jego wznowienie (dokończenie
faz do CLOSE); nowy dated rejestr powstaje tylko po explicit decyzji usera.

**Fail wygląda tak:** Skill otwiera nowy rejestr obok wiszącego `active` — pipeline akumuluje
otwarte rejestry, karta kanbana wisi w „In progress" tygodniami.

**Jak sprawdzić:** Ustaw testowy rejestr `status: active` i wywołaj sweep — pierwsza propozycja
skilla musi dotyczyć wznowienia, nie nowego rejestru.
