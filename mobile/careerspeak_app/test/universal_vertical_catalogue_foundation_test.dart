import 'package:careerspeak_app/application/content_delivery/catalogue_payload.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/data/mock/demo_catalogue_payload_gateway.dart';
import 'package:careerspeak_app/data/remote/learning_vertical_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const checksum =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  test('verticals is a backend-owned catalogue kind', () {
    expect(CatalogueKind.fromWireName('verticals'), CatalogueKind.verticals);
  });

  test('decoder accepts previously unknown vertical code without branching', () {
    const decoder = LearningVerticalDecoder();

    final vertical = decoder.decode(<String, dynamic>{
      'code': 'NEW_VERTICAL_2027',
      'title': 'New Vertical',
      'description': 'Delivered only by backend data.',
      'iconAssetId': 'asset-vertical-new',
      'sortOrder': 50,
      'active': true,
    });

    expect(vertical.code, 'NEW_VERTICAL_2027');
    expect(vertical.title, 'New Vertical');
    expect(vertical.active, isTrue);
  });

  test('decoder rejects mutable runtime fields', () {
    const decoder = LearningVerticalDecoder();

    expect(
      () => decoder.decode(<String, dynamic>{
        'code': 'JAVA_INTERVIEW',
        'title': 'Java Interview',
        'description': 'Interview English',
        'iconAssetId': 'asset-java',
        'sortOrder': 1,
        'active': true,
        'downloadProgress': 0.5,
      }),
      throwsFormatException,
    );
  });

  test('demo gateway uses the same exact catalogue payload contract', () async {
    final ref = CatalogueRevisionRef(
      kind: CatalogueKind.verticals,
      revision: 1,
      checksum: checksum,
    );
    final payload = CataloguePayload(
      ref: ref,
      items: <Object>[
        <String, dynamic>{
          'code': 'MEDICAL_ENGLISH',
          'title': 'Medical English',
          'description': 'Medical communication',
          'iconAssetId': 'asset-medical',
          'sortOrder': 1,
          'active': true,
        },
      ],
      wireJson: <String, Object?>{
        'kind': 'verticals',
        'revision': 1,
        'checksum': checksum,
        'items': <Object>[],
      },
    );
    final gateway = DemoCataloguePayloadGateway(
      payloads: <String, CataloguePayload>{
        DemoCataloguePayloadGateway.keyOf(ref): payload,
      },
      latency: Duration.zero,
    );

    final loaded = (await gateway.fetch(ref)).getOrThrow();

    expect(loaded.ref.kind, CatalogueKind.verticals);
    expect(loaded.items, hasLength(1));
  });
}
