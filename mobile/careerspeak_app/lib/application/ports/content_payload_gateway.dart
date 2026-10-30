import '../content_delivery/content_payload.dart';
import '../result/result.dart';

abstract interface class ContentPayloadGateway {
  Future<Result<ContentPayload>> fetch(ContentPayloadRef target);
}
