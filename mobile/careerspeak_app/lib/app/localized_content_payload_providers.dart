import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/localized_content_payload_gateway.dart';
import '../data/remote/http_localized_content_payload_gateway.dart';
import '../data/remote/localized_content_payload_decoder.dart';
import 'api_client_providers.dart';

final localizedContentPayloadDecoderProvider =
    Provider<LocalizedContentPayloadDecoder>((ref) {
      return const LocalizedContentPayloadDecoder();
    });

final localizedContentPayloadGatewayProvider =
    Provider<LocalizedContentPayloadGateway>((ref) {
      return HttpLocalizedContentPayloadGateway(
        apiClient: ref.watch(apiClientProvider),
        decoder: ref.watch(localizedContentPayloadDecoderProvider),
      );
    });
