import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('installation token string representation is always redacted', () {
    final token = InstallationToken('super-secret-token-value');

    expect(token.toString(), '<redacted>');
    expect(token.toString(), isNot(contains('super-secret-token-value')));
  });

  test('credential string representation never exposes token value', () {
    final credentials = InstallationCredentials(
      installationId: InstallationId('installation-1'),
      installationToken: InstallationToken('super-secret-token-value'),
    );

    final rendered = credentials.toString();

    expect(rendered, contains('installation-1'));
    expect(rendered, contains('<redacted>'));
    expect(rendered, isNot(contains('super-secret-token-value')));
  });
}
