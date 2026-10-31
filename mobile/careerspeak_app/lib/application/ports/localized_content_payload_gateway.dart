import '../content_delivery/content_manifest.dart';
import '../content_delivery/localized_content_payload.dart';
import '../result/result.dart';

abstract interface class LocalizedContentPayloadGateway {
  Future<Result<LocalizedContentPayload>> fetch(LocalizedContentRef target);
}
