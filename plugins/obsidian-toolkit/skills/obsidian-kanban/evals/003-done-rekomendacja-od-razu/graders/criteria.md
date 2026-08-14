---
type: llm
weight: 2
---

PASS wymaga, żeby odpowiedź — w tej samej wypowiedzi, w której karta ląduje w `Done` —
zawierała **konkretne rozstrzygnięcie dalszego losu karty**: albo „promuj do vaultu"
(z uzasadnieniem, dlaczego warte pamięci), albo „archiwizuj" — jako propozycja do
potwierdzenia przez usera.

Dodatkowo odpowiedź powinna wymienić kroki domknięcia: wypełnienie sekcji `## Rezultat`,
stempel `done_at`, zdjęcie locka / usunięcie `claimed`.

FAIL, jeśli odpowiedź kończy się miękko — „archiwizacja opcjonalna", „daj znać jeśli chcesz
posprzątać", albo w ogóle nie porusza tematu promocji/archiwizacji.
