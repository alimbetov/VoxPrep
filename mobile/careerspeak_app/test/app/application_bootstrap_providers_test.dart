import 'package:careerspeak_app/app/api_client_providers.dart';
import 'package:careerspeak_app/app/application_bootstrap_providers.dart';
import 'package:careerspeak_app/app/bootstrap_status_frame.dart';
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

  testWidgets(
    'bootstrap failure keeps local UI, hides raw failure, and retries',
    (tester) async {
      var bootstrapCalls = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            applicationBootstrapProvider.overrideWith((ref) async {
              bootstrapCalls += 1;
              return const FailureResult<ApplicationBootstrapOutcome>(
                ApplicationFailure(
                  code: 'OFFLINE',
                  message: 'raw transport details must stay hidden',
                  retryable: true,
                ),
              );
            }),
          ],
          child: const MaterialApp(
            home: BootstrapStatusFrame(
              child: Scaffold(body: Text('local-content')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(bootstrapCalls, 1);
      expect(find.text('local-content'), findsOneWidget);
      expect(
        find.text('Could not refresh data. Saved content remains available.'),
        findsOneWidget,
      );
      expect(find.text('raw transport details must stay hidden'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(bootstrapCalls, 2);
      expect(find.text('local-content'), findsOneWidget);
    },
  );
}

final class _UnusedApiClient implements ApiClient {
  @override
  Future<Result<ApiResponse>> send(ApiRequest request) {
    throw StateError('not expected');
  }
}
