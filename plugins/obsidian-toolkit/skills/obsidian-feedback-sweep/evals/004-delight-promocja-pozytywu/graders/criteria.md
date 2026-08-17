---
type: llm
weight: 2
---

PASS wymaga obu:
1. Komentarz — pochwała z realną treścią do reużycia (nie gołe „ok, dzięki") — klasyfikowany
   jako dyspozycja **Capture → Delight**, NIE `No action` i NIE zwykły wpis w rotowanym rejestrze
   feedbacku.
2. Wpis w kolekcji Delight ma komplet pól, w tym **„Dlaczego zadziałało"** i **„Jak reużyć"** —
   nie tylko goły cytat komentarza.

FAIL, jeśli komentarz ląduje w `No action` albo w rejestrze feedbacku (zostanie zarchiwizowany
przy jego domknięciu), albo wpis pomija „Dlaczego zadziałało"/„Jak reużyć".
