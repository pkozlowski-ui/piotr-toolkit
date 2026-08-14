---
type: llm
weight: 2
---

PASS wymaga wszystkich trzech:

1. Odpowiedź deklaruje **świeży odczyt frontmattera kandydata z dysku**, a nie oparcie się
   na digeście z kontekstu (digest jest przeterminowany).
2. Karta z cudzym `claimed` / cudzym lockiem jest **pomijana** — skill proponuje następną,
   nie przejmuje jej bez zgody usera.
3. Wzięcie wybranej karty ustawia `status: In progress` **i** `claimed: <data · sesja>`.

FAIL, jeśli odpowiedź wybiera kartę na podstawie stanu z kontekstu, albo bierze kartę bez
ustawienia `claimed`, albo proponuje przejęcie cudzego claima bez pytania.
