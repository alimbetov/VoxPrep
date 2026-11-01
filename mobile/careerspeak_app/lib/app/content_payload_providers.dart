import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/content_payload_gateway.dart';
import '../data/mock/demo_content_payload_gateway.dart';
import '../data/remote/content_payload_decoder.dart';
import '../data/remote/http_content_payload_gateway.dart';
import '../domain/catalogue_source_mode.dart';
import 'api_client_providers.dart';
import 'catalogue_source_providers.dart';

final contentPayloadDecoderProvider = Provider<ContentPayloadDecoder>((ref) {
  return const ContentPayloadDecoder();
});

final contentPayloadGatewayProvider = Provider<ContentPayloadGateway>((ref) {
  final source = ref.watch(catalogueSourceModeProvider);
  return switch (source) {
    CatalogueSourceMode.demo => DemoContentPayloadGateway(),
    CatalogueSourceMode.production => HttpContentPayloadGateway(
      apiClient: ref.watch(apiClientProvider),
      decoder: ref.watch(contentPayloadDecoderProvider),
    ),
  };
});
