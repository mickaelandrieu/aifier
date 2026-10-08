# Learned rules

Rules captured from reviews and incidents. Every agent reads this file before building or
reviewing. A rule is a repeatable pattern with a detection, not a closed ticket.

Format:

```
## RULE-NNN: slug
Severity: critical | major | minor · Learned from: PR or issue · Date
Rule: one sentence.
Wrong: minimal example.
Right: minimal example.
Detection: grep, lint rule, or review question.
```

No rule yet. An empty catalogue after a clean cycle is a valid outcome.
