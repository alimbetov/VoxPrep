# B6.4 Atomic Publication Contract

B6.4 introduces the first production publication transaction.

## Transaction

1. Lock publication candidate for update.
2. Return the existing immutable release for a replayed PUBLISHED candidate.
3. Require VALIDATED for a new publication.
4. Reload the persisted frozen manifest in canonical order.
5. Re-run deterministic exact-reference validation.
6. Require the recomputed root SHA-256 to equal the candidate root.
7. Lock the singleton publication_current row.
8. Allocate a monotonic content version.
9. Insert and flush the immutable publication_release.
10. Switch publication_current to the new release.
11. Mark the candidate PUBLISHED.
12. Commit all state changes atomically.

The publish operation never accepts a caller-supplied manifest or root. Both are read from the frozen B6.3 candidate state.
