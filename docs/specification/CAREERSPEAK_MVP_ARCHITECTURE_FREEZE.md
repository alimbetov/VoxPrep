# CareerSpeak — MVP Architecture Freeze

After R1 Review Policy, Flutter learner-domain architecture is frozen for CareerSpeak v1.

Allowed implementation streams after R1:

```text
C4 Atomic Publication
C5 Installation / Security
Backend schema + modular-monolith implementation
Cross-system acceptance
correctness hardening required by those streams
minimal UX/accessibility fixes
```

Disallowed without a versioned product change:

```text
new learner-domain aggregates
new recommendation/personalization layer
new workflow/rules layer
server learner profile
new distributed infrastructure dependency
new account system
new ML/AI learning subsystem
```

The purpose of the freeze is to move investment from speculative Flutter architecture into real Backend ↔ Flutter production integration.
