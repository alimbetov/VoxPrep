import '../../application/content_delivery/content_payload.dart';
import '../../application/ports/content_payload_gateway.dart';
import '../../application/result/result.dart';
import 'demo_learning_fixture.dart';

final class DemoContentPayloadGateway implements ContentPayloadGateway {
  DemoContentPayloadGateway({
    Iterable<ContentPayload>? payloads,
    this.latency = const Duration(milliseconds: 120),
  }) : _payloads = <String, ContentPayload>{
         for (final payload in payloads ?? buildDemoContentPayloads())
           _key(payload.ref): payload,
       };

  final Map<String, ContentPayload> _payloads;
  final Duration latency;

  @override
  Future<Result<ContentPayload>> fetch(ContentPayloadRef target) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    final payload = _payloads[_key(target)];
    if (payload == null) {
      return FailureResult<ContentPayload>(
        ApplicationFailure(
          code: 'DEMO_CONTENT_NOT_FOUND',
          message: 'Demo backend has no exact content revision.',
          details: <String, Object?>{
            'contentCode': target.identity.code,
            'contentType': target.identity.type.name,
            'revision': target.revision,
          },
        ),
      );
    }
    return Success<ContentPayload>(payload);
  }

  static String _key(ContentPayloadRef ref) =>
      '${ref.identity.type.name}|${ref.identity.code}|${ref.revision}|${ref.checksum}';
}
