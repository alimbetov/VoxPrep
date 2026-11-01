import 'package:flutter/foundation.dart';

const _legalName = String.fromEnvironment('CAREERSPEAK_LEGAL_NAME');
const _privacyEmail = String.fromEnvironment('CAREERSPEAK_PRIVACY_EMAIL');
const _privacyPolicyUrl = String.fromEnvironment('CAREERSPEAK_PRIVACY_POLICY_URL');
const _termsUrl = String.fromEnvironment('CAREERSPEAK_TERMS_URL');
const _supportUrl = String.fromEnvironment('CAREERSPEAK_SUPPORT_URL');

final class ReleaseLegalConfig {
  const ReleaseLegalConfig({
    required this.legalName,
    required this.privacyEmail,
    required this.privacyPolicyUrl,
    required this.termsUrl,
    required this.supportUrl,
  });

  factory ReleaseLegalConfig.fromEnvironment() => const ReleaseLegalConfig(
        legalName: _legalName,
        privacyEmail: _privacyEmail,
        privacyPolicyUrl: _privacyPolicyUrl,
        termsUrl: _termsUrl,
        supportUrl: _supportUrl,
      );

  final String legalName;
  final String privacyEmail;
  final String privacyPolicyUrl;
  final String termsUrl;
  final String supportUrl;

  void validate({bool releaseMode = kReleaseMode}) {
    if (!releaseMode) return;

    final missing = <String>[
      if (legalName.trim().isEmpty) 'CAREERSPEAK_LEGAL_NAME',
      if (privacyEmail.trim().isEmpty) 'CAREERSPEAK_PRIVACY_EMAIL',
      if (privacyPolicyUrl.trim().isEmpty) 'CAREERSPEAK_PRIVACY_POLICY_URL',
      if (termsUrl.trim().isEmpty) 'CAREERSPEAK_TERMS_URL',
      if (supportUrl.trim().isEmpty) 'CAREERSPEAK_SUPPORT_URL',
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Release legal configuration is incomplete: ${missing.join(', ')}',
      );
    }

    if (!_looksLikeEmail(privacyEmail)) {
      throw StateError('CAREERSPEAK_PRIVACY_EMAIL is invalid.');
    }
    _requireHttps('CAREERSPEAK_PRIVACY_POLICY_URL', privacyPolicyUrl);
    _requireHttps('CAREERSPEAK_TERMS_URL', termsUrl);
    _requireHttps('CAREERSPEAK_SUPPORT_URL', supportUrl);
  }
}

void validateReleaseLegalConfiguration({
  ReleaseLegalConfig? config,
  bool releaseMode = kReleaseMode,
}) {
  (config ?? ReleaseLegalConfig.fromEnvironment()).validate(
    releaseMode: releaseMode,
  );
}

bool _looksLikeEmail(String value) {
  final trimmed = value.trim();
  final at = trimmed.indexOf('@');
  return at > 0 && at < trimmed.length - 1 && !trimmed.contains(RegExp(r'\s'));
}

void _requireHttps(String key, String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      uri.scheme.toLowerCase() != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw StateError('$key must be an absolute HTTPS URL without credentials.');
  }
}
