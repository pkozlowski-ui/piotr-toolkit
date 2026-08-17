---
type: llm
weight: 1
---

Oceniasz WYŁĄCZNIE, co dokładnie zapisuje wzięcie wybranej karty — nie karz tutaj za nic innego.

PASS: wzięcie wybranej karty ustawia **oba** pola: `status: In progress` I `claimed: <data ·
sesja>`.

FAIL, jeśli odpowiedź bierze kartę bez ustawienia `claimed`, albo zmienia tylko `status` bez
lustra locka.
