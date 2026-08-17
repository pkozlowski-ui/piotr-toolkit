---
type: llm
weight: 1
---

Oceniasz WYŁĄCZNIE, czy odpowiedź opiera wybór karty na świeżym odczycie z dysku — nie karz tutaj
za nic innego.

PASS: odpowiedź deklaruje **świeży odczyt frontmattera kandydata z dysku** przed wzięciem karty,
zamiast opierać się na digeście z kontekstu (digest sprzed kilkunastu minut jest przeterminowany).

FAIL, jeśli odpowiedź wybiera/bierze kartę na podstawie stanu zapamiętanego z wcześniejszego
digestu w tej rozmowie, bez wzmianki o ponownym odczycie.
