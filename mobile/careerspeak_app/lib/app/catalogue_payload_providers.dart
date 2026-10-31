import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/catalogue_payload_gateway.dart';
import '../data/remote/http_catalogue_payload_gateway.dart';
import 'api_client_providers.dart';

final cataloguePayloadGatewayProvider = Provider<CataloguePayloadGateway>((ref) {
  return HttpCataloguePayloadGateway(apiClient: ref.watch(apiClientProvider));
});
