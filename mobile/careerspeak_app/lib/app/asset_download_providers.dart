import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../application/ports/asset_byte_source.dart';
import '../application/ports/asset_file_store.dart';
import '../application/services/asset_download_manager.dart';
import '../data/local/file_system_asset_store.dart';
import '../data/remote/http_asset_byte_source.dart';
import 'api_client_providers.dart';

const _cdnBaseUrl = String.fromEnvironment(
  'CAREERSPEAK_CDN_BASE_URL',
  defaultValue: 'https://cdn.careerspeak.invalid/',
);

final cdnBaseUriProvider = Provider<Uri>((ref) => Uri.parse(_cdnBaseUrl));

final assetByteSourceProvider = Provider<AssetByteSource>((ref) {
  return HttpAssetByteSource(
    client: ref.watch(httpClientProvider),
    baseUri: ref.watch(cdnBaseUriProvider),
  );
});

final assetRootDirectoryProvider = FutureProvider<Directory>((ref) async {
  final support = await getApplicationSupportDirectory();
  final directory = Directory('${support.path}/managed_assets');
  await directory.create(recursive: true);
  return directory;
});

final assetFileStoreProvider = FutureProvider<AssetFileStore>((ref) async {
  return FileSystemAssetStore(
    await ref.watch(assetRootDirectoryProvider.future),
  );
});

final assetDownloadManagerProvider = FutureProvider<AssetDownloadManager>((
  ref,
) async {
  return AssetDownloadManager(
    source: ref.watch(assetByteSourceProvider),
    store: await ref.watch(assetFileStoreProvider.future),
  );
});
