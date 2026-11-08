import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/content_delivery/external_learning_video.dart';
import '../application/ports/api_client.dart';
import '../application/result/result.dart';
import '../domain/catalogue_source_mode.dart';
import '../domain/content_identity.dart';
import 'api_client_providers.dart';
import 'catalogue_source_providers.dart';

typedef ExternalVideoRequest = ({ContentIdentity identity, int revision});

/// Network-only optional enrichment, never mutates CURRENT or Drift.
final externalLearningVideoProvider =
    FutureProvider.family<ExternalLearningVideo?, ExternalVideoRequest>((
      ref,
      request,
    ) async {
      if (ref.watch(catalogueSourceModeProvider) !=
          CatalogueSourceMode.production) {
        return null;
      }
      final api = ref.watch(apiClientProvider);
      final result = await api.send(
        ApiRequest(
          method: ApiMethod.get,
          path:
              '/api/v2/content/${Uri.encodeComponent(request.identity.type.name)}/${Uri.encodeComponent(request.identity.code)}/external-video',
        ),
      );
      if (result case FailureResult<ApiResponse>()) return null;
      final response = (result as Success<ApiResponse>).value;
      if (response.statusCode == 204 || response.statusCode == 404) return null;
      if (response.statusCode != 200) return null;
      try {
        return ExternalLearningVideo.parse(
          response.jsonBody,
          identity: request.identity,
          revision: request.revision,
        );
      } on FormatException {
        return null;
      }
    });
