import 'dart:async';

import 'package:careerspeak_app/app/api_client_providers.dart';
import 'package:careerspeak_app/app/application_bootstrap_providers.dart';
import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/application_bootstrap_service.dart';
import 'package:careerspeak_app/data/remote/http_installation_registration_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('composition root selects HTTP installation registration adapter', () {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(_UnusedApiClient())],
    );
    addTearDown(container.dispose);

    expect(
      container.read(installationRegistrationGatewayProvider),
      isA<HttpInstallationRegistrationGateway>(),
    );
  });

  testWidgets('production bootstrap never blocks last-known-good local UI', (
    tester,
  ) async {
    final gate = Completer<Result<ApplicationBootstrapOutcome>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          applicationBootstrapProvider.overrideWith((ref) => gate.future),
        ],
        child: const MaterialApp(
          home: ProductionBootstrapHost(
            child: Scaffold(body: Text('local-content')),
          ),
        ),
      ),
    );

    expect(find.text('local-content'), findsOneWidget);

    gate.complete(
      const FailureResult<ApplicationBootstrapOutcome>(
        ApplicationFailure(
          code: 'OFFLINE',
          message: 'offline',
          retryable: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('local-content'), findsOneWidget);
  });
}

final class _UnusedApiClient implements ApiClient {
  @override
  Future<Result<ApiResponse>> send(ApiRequest request) {
    throw StateError('not expected');
  }
}
