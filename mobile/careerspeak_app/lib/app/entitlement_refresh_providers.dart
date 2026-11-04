import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/services/entitlement_status_refresh_service.dart';
import 'access_providers.dart';
import 'api_client_providers.dart';

final entitlementStatusRefreshServiceProvider =
    Provider<EntitlementStatusRefreshService>((ref) {
      return EntitlementStatusRefreshService(
        apiClient: ref.watch(apiClientProvider),
        repository: ref.watch(accessSnapshotRepositoryProvider),
      );
    });
