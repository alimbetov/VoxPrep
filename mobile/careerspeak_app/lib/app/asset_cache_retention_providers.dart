import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/asset_cache_retention_repository.dart';
import '../application/services/asset_cache_retention_manager.dart';
import '../data/local/drift_asset_cache_retention_repository.dart';
import '../data/local/file_system_asset_store.dart';
import 'asset_download_providers.dart';
import 'learner_state_providers.dart';

final assetCacheRetentionRepositoryProvider =
    Provider<AssetCacheRetentionRepository>((ref) {
      return DriftAssetCacheRetentionRepository(
        ref.watch(careerSpeakDatabaseProvider),
      );
    });

final assetCacheRetentionManagerProvider =
    FutureProvider<AssetCacheRetentionManager>((ref) async {
      final store = await ref.watch(assetFileStoreProvider.future);
      if (store is! FileSystemAssetStore) {
        throw StateError(
          'Production managed asset store must support cache eviction.',
        );
      }
      return AssetCacheRetentionManager(
        retention: ref.watch(assetCacheRetentionRepositoryProvider),
        evictionStore: store,
      );
    });
