# C2 Qualification Ledger

C1 is frozen at `4620142f28de20bc0bf84b686d879fd082df7e95` and is not modified by C2.

## C2.1 / C2.2 — typed domain and small catalogue components

Qualified source baseline:

```text
4d3597447e933724c06c2dcc4c75c9b46aab248e
```

Production qualification:

```text
Flutter Production Adapters run 41193064139
format                         PASS
Drift v6 reproducibility       PASS
flutter analyze                PASS
full flutter test              PASS
```

## C2.3 — production typed canonical-content decode

Production typed source:

```text
2a1a478942ad16c075556a8e01cecb819a6f9fb7
```

The production decoder requires `skillCodes` and exactly one typed `body`, enforces `contentType == body.kind`, rejects unsupported body fields and rejects legacy untyped server payloads.

The first full-suite attempt exposed only stale mock backend acceptance fixtures. Those fixtures were upgraded to the C2 typed payload contract and the seven previously failing P2.10.7/P2.11 acceptance scenarios all passed in targeted qualification before commit:

```text
fixture repair commit
9038bd76a1a9f668bbbfdfa91867ad72e487d57c

targeted acceptance
p2_10_7_production_e2e_test.dart       PASS
p2_11_recovery_acceptance_test.dart    PASS
```

The production format gate then exposed one remaining package-context formatting difference in the P2.11 recovery fixture. The exact production formatter sequence (`flutter pub get` followed by `dart format` inside `mobile/careerspeak_app`) produced the formatter-only repair:

```text
24a7fde15a529d59b4ceefb3f09ff2e271cb763a
style(c2): format recovery typed fixture
```

All one-shot formatter workflows were removed atomically before this qualification trigger. This commit therefore starts the clean exact-SHA full-production qualification for C2.3.
