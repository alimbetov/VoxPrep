import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/asset_catalog_repository.dart';
import '../application/services/asset_resolver.dart';
import '../data/local/drift_asset_catalog_repository.dart';
import 'asset_download_providers.dart';
import 'learner_state_providers.dart';

final assetCatalogRepositoryProvider = Provider<AssetCatalogRepository>((ref) {
  return DriftAssetCatalogRepository(ref.watch(careerSpeakDatabaseProvider));
});

final assetResolverProvider = FutureProvider<AssetResolver>((ref) async {
  final catalog = ref.watch(assetCatalogRepositoryProvider);
  final store = ref.watch(assetFileStoreProvider.future);
  final downloads = ref.watch(assetDownloadManagerProvider.future);
  return AssetResolver(
    catalog: catalog,
    store: await store,
    downloads: await downloads,
  );
});
