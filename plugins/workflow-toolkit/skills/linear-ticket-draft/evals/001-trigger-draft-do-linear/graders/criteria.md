---
type: llm
weight: 2
---

PASS wymaga wszystkich czterech:

1. Odpowiedź to **draft w rejestrze „opis taska"** — ustrukturyzowany i rzeczowy, po **angielsku**,
   krótki (rzędu 2–4 zdań lub zwięzłych bulletów + linki). NIE konwersacyjna wiadomość w stylu
   Slacka i NIE długi write-up.
2. Draft **nie jest wysyłany** — jest pokazany w czacie. Odpowiedź nie twierdzi, że go wysłała,
   i nie wykonuje żadnej akcji wysyłkowej.
3. Draft mówi **CO ficzer robi** i **niesie otwarte pytanie** o edycję widoków współdzielonych
   jako rzecz do rozstrzygnięcia.
4. Draft **nie opisuje komponentów ani design systemu** — to detal wewnętrzny, którego zespół
   w Linear nie czyta.

FAIL, jeśli draft jest po polsku, jeśli jest napisany jak wiadomość na Slacku, jeśli gubi otwarte
pytanie, jeśli opisuje użyte komponenty / design system, albo jeśli odpowiedź sugeruje wysyłkę
jako wykonaną bądź proponuje ją zamiast czekać na wyraźne polecenie.
