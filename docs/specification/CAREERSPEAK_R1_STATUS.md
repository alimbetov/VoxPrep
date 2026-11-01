# CareerSpeak — R1 Status

Current implementation slices:

```text
R1.1 policy contract                    DONE
R1.2 pure ReviewSchedulingPolicy        DONE
R1.3 ReviewScheduler persistence port   DONE
R1.4 Riverpod integration               DONE
R1.5 Review UI outcome actions          DONE
R1.6 restart/adversarial qualification  DONE
R1.7 exact-SHA regression               PENDING
```

Qualification evidence already present in the Flutter branch:
- deterministic `incorrect / hard / correct / known` scheduling policy;
- Review UI outcome actions wired through `ReviewScheduler`;
- persisted review schedule survives repository reopen;
- invalid negative review stage fails closed;
- strict `Due = nextReviewAt <= now` semantics;
- recording a future schedule removes the item from Due immediately.

R1 must not expand into advanced spaced repetition. Its only remaining gate is an exact-SHA analyzer/full-regression pass. After that R1 is CLOSED and the Flutter learner-domain architecture stays feature-frozen except for demonstrated correctness defects.
