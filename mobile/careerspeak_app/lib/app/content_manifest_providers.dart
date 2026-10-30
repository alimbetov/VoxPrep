import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/content_manifest_gateway.dart';
import '../data/remote/content_manifest_decoder.dart';
import '../data/remote/http_content_manifest_gateway.dart';
import 'api_client_providers.dart';

final contentManifestDecoderProvider = Provider<ContentManifestDecoder>((ref) {
  return const ContentManifestDecoder();
});

final contentManifestGatewayProvider = Provider<ContentManifestGateway>((ref) {
  return HttpContentManifestGateway(
    apiClient: ref.watch(apiClientProvider),
    decoder: ref.watch(contentManifestDecoderProvider),
  );
});
