import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/content_manifest_gateway.dart';
import '../data/mock/demo_content_manifest_gateway.dart';
import '../data/remote/content_manifest_decoder.dart';
import '../data/remote/http_content_manifest_gateway.dart';
import '../domain/catalogue_source_mode.dart';
import 'api_client_providers.dart';
import 'catalogue_payload_providers.dart';
import 'catalogue_source_providers.dart';

final contentManifestDecoderProvider = Provider<ContentManifestDecoder>((ref) {
  return const ContentManifestDecoder();
});

final contentManifestGatewayProvider = Provider<ContentManifestGateway>((ref) {
  final source = ref.watch(catalogueSourceModeProvider);
  return switch (source) {
    CatalogueSourceMode.production => HttpContentManifestGateway(
        apiClient: ref.watch(apiClientProvider),
        decoder: ref.watch(contentManifestDecoderProvider),
      ),
    CatalogueSourceMode.demo => DemoContentManifestGateway(
        cataloguePayloads: ref.watch(demoCataloguePayloadsProvider).values,
      ),
  };
});
