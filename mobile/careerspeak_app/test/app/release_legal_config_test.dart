import 'package:careerspeak_app/app/release_legal_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const valid = ReleaseLegalConfig(
    legalName: 'Example Publisher',
    privacyEmail: 'privacy@example.com',
    privacyPolicyUrl: 'https://example.com/privacy',
    termsUrl: 'https://example.com/terms',
    supportUrl: 'https://example.com/support',
  );

  test('accepts complete HTTPS release configuration', () {
    expect(() => valid.validate(releaseMode: true), returnsNormally);
  });

  test('does not require release metadata outside release mode', () {
    const empty = ReleaseLegalConfig(
      legalName: '',
      privacyEmail: '',
      privacyPolicyUrl: '',
      termsUrl: '',
      supportUrl: '',
    );

    expect(() => empty.validate(releaseMode: false), returnsNormally);
  });

  test('fails closed when mandatory release metadata is missing', () {
    const invalid = ReleaseLegalConfig(
      legalName: '',
      privacyEmail: 'privacy@example.com',
      privacyPolicyUrl: 'https://example.com/privacy',
      termsUrl: 'https://example.com/terms',
      supportUrl: 'https://example.com/support',
    );

    expect(
      () => invalid.validate(releaseMode: true),
      throwsA(isA<StateError>()),
    );
  });

  test('fails closed on cleartext public policy URL', () {
    const invalid = ReleaseLegalConfig(
      legalName: 'Example Publisher',
      privacyEmail: 'privacy@example.com',
      privacyPolicyUrl: 'http://example.com/privacy',
      termsUrl: 'https://example.com/terms',
      supportUrl: 'https://example.com/support',
    );

    expect(
      () => invalid.validate(releaseMode: true),
      throwsA(isA<StateError>()),
    );
  });

  test('fails closed on invalid privacy contact', () {
    const invalid = ReleaseLegalConfig(
      legalName: 'Example Publisher',
      privacyEmail: 'not-an-email',
      privacyPolicyUrl: 'https://example.com/privacy',
      termsUrl: 'https://example.com/terms',
      supportUrl: 'https://example.com/support',
    );

    expect(
      () => invalid.validate(releaseMode: true),
      throwsA(isA<StateError>()),
    );
  });
}
