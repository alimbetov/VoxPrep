# CareerSpeak Accessibility & Security Commitments

## Accessibility

CareerSpeak should remain operable with platform accessibility settings and assistive technologies supported by the released platforms. The product architecture already follows system text direction and reduced-motion preferences; production acceptance additionally requires physical qualification.

Release requirements:

- VoiceOver on iPhone/iPad;
- TalkBack on Android;
- large text / text scaling up to at least 200% without loss of core functionality;
- keyboard/focus traversal where the target platform supports keyboard input;
- sufficient semantic labels for interactive controls;
- no information conveyed only by color;
- reduced-motion behavior that preserves navigation/functionality;
- RTL layout qualification for declared RTL locales;
- captions/transcripts or equivalent accessible alternatives where required for audio learning content.

Accessibility defects that prevent access to purchased core functionality are release blockers.

## Security and responsible disclosure

CareerSpeak uses a pseudonymous installation credential for service authentication. Release builds must use HTTPS for API traffic and platform secure storage for installation credentials.

The product must not intentionally log authorization headers, installation tokens, secrets, or raw protected payloads. Learner-facing errors should expose stable safe messages/trace identifiers rather than backend internals.

Security reports must be accepted through the production support/privacy contact published with the release. Reports should include affected version, reproduction steps and impact where possible. The publisher should acknowledge, triage and remediate credible reports without requiring the reporter to collect unnecessary user data.

Researchers must not exploit vulnerabilities against other users, access data beyond what is necessary to demonstrate the issue, disrupt production services, or publicly disclose an unremediated issue in a way that creates material user risk.

## Release gates

Before production acceptance:

- physical accessibility matrix completed;
- HTTPS fail-closed qualification green;
- dependency/security review completed for exact release SHA;
- application/store permissions minimized;
- secrets absent from repository and production logs;
- public support/security contact operational;
- incident response owner and escalation path documented.
