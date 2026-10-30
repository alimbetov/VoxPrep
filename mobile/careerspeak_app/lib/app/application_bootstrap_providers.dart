import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/installation_registration_gateway.dart';
import '../application/result/result.dart';
import '../application/services/application_bootstrap_service.dart';
import '../application/services/installation_bootstrap_service.dart';
import '../data/remote/http_installation_registration_gateway.dart';
import 'api_client_providers.dart';
import 'content_sync_providers.dart';
import 'installation_identity_providers.dart';

final installationRegistrationGatewayProvider =
    Provider<InstallationRegistrationGateway>((ref) {
      return HttpInstallationRegistrationGateway(
        apiClient: ref.watch(apiClientProvider),
      );
    });

final installationBootstrapServiceProvider =
    Provider<InstallationBootstrapService>((ref) {
      return InstallationBootstrapService(
        identityService: ref.watch(installationIdentityServiceProvider),
        registrationGateway: ref.watch(installationRegistrationGatewayProvider),
      );
    });

final applicationBootstrapServiceProvider = Provider<ApplicationBootstrapService>(
  (ref) {
    final contentSync = ref.watch(preferenceAwareContentSyncProvider);
    return ApplicationBootstrapService(
      installationBootstrapService: ref.watch(
        installationBootstrapServiceProvider,
      ),
      synchronizeContent: contentSync.synchronize,
    );
  },
);

final applicationBootstrapProvider =
    FutureProvider<Result<ApplicationBootstrapOutcome>>((ref) {
      return ref.watch(applicationBootstrapServiceProvider).bootstrap();
    });

final class ProductionBootstrapHost extends ConsumerWidget {
  const ProductionBootstrapHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(applicationBootstrapProvider);
    return child;
  }
}
