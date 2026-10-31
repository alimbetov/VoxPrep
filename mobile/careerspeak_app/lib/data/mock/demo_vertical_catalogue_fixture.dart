import '../../application/content_delivery/catalogue_payload.dart';
import '../../application/content_delivery/catalogue_revision_ref.dart';
import 'demo_catalogue_payload_gateway.dart';

const _sectionsChecksum =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _verticalsChecksum =
    '2222222222222222222222222222222222222222222222222222222222222222';
const _presentationChecksum =
    '3333333333333333333333333333333333333333333333333333333333333333';
const _goalsChecksum =
    '4444444444444444444444444444444444444444444444444444444444444444';
const _tracksChecksum =
    '5555555555555555555555555555555555555555555555555555555555555555';
const _collectionsChecksum =
    '6666666666666666666666666666666666666666666666666666666666666666';

Map<String, CataloguePayload> buildDemoVerticalCataloguePayloads() {
  final sectionsRef = CatalogueRevisionRef(
    kind: CatalogueKind.verticalSections,
    revision: 1,
    checksum: _sectionsChecksum,
  );
  final verticalsRef = CatalogueRevisionRef(
    kind: CatalogueKind.verticals,
    revision: 1,
    checksum: _verticalsChecksum,
  );
  final presentationRef = CatalogueRevisionRef(
    kind: CatalogueKind.verticalPresentation,
    revision: 1,
    checksum: _presentationChecksum,
  );
  final goalsRef = CatalogueRevisionRef(
    kind: CatalogueKind.learningGoals,
    revision: 1,
    checksum: _goalsChecksum,
  );
  final tracksRef = CatalogueRevisionRef(
    kind: CatalogueKind.learningTracks,
    revision: 1,
    checksum: _tracksChecksum,
  );
  final collectionsRef = CatalogueRevisionRef(
    kind: CatalogueKind.learningCollections,
    revision: 1,
    checksum: _collectionsChecksum,
  );

  final sections = <Object>[
    <String, dynamic>{
      'code': 'SOFTWARE_ENGINEERING',
      'title': 'Software Engineering',
      'description': 'Interview and engineering communication.',
      'iconAssetId': 'demo-section-software',
      'sortOrder': 0,
      'active': true,
    },
    <String, dynamic>{
      'code': 'CLOUD_PLATFORM',
      'title': 'Cloud & Platform',
      'description': 'Cloud and infrastructure English.',
      'iconAssetId': 'demo-section-cloud',
      'sortOrder': 10,
      'active': true,
    },
    <String, dynamic>{
      'code': 'ENGLISH_COMMUNICATION',
      'title': 'English & Communication',
      'description': 'Professional English for domain communication.',
      'iconAssetId': 'demo-section-english',
      'sortOrder': 20,
      'active': true,
    },
  ];

  final verticals = <Object>[
    _vertical(
      code: 'JAVA_INTERVIEW',
      sectionCode: 'SOFTWARE_ENGINEERING',
      title: 'Java Interview',
      sortOrder: 0,
    ),
    _vertical(
      code: 'QA_INTERVIEW',
      sectionCode: 'SOFTWARE_ENGINEERING',
      title: 'QA Interview',
      sortOrder: 10,
    ),
    _vertical(
      code: 'DEVOPS_INTERVIEW',
      sectionCode: 'SOFTWARE_ENGINEERING',
      title: 'DevOps Interview',
      sortOrder: 20,
    ),
    _vertical(
      code: 'AWS',
      sectionCode: 'CLOUD_PLATFORM',
      title: 'AWS',
      sortOrder: 0,
    ),
    _vertical(
      code: 'KUBERNETES',
      sectionCode: 'CLOUD_PLATFORM',
      title: 'Kubernetes',
      sortOrder: 10,
    ),
    _vertical(
      code: 'MEDICAL_ENGLISH',
      sectionCode: 'ENGLISH_COMMUNICATION',
      title: 'Medical English',
      sortOrder: 0,
    ),
    _vertical(
      code: 'SALES_ENGLISH',
      sectionCode: 'ENGLISH_COMMUNICATION',
      title: 'Sales English',
      sortOrder: 10,
    ),
    _vertical(
      code: 'BANKING_ENGLISH',
      sectionCode: 'ENGLISH_COMMUNICATION',
      title: 'Banking English',
      sortOrder: 20,
    ),
  ];

  final presentation = <Object>[
    <String, dynamic>{
      'mode': 'SHELVES',
      'showFeatured': false,
      'showSeeAll': true,
      'featuredSectionCode': null,
    },
  ];

  final payloads = <CataloguePayload>[
    _payload(ref: sectionsRef, items: sections),
    _payload(ref: verticalsRef, items: verticals),
    _payload(ref: presentationRef, items: presentation),
    _payload(ref: goalsRef, items: const <Object>[]),
    _payload(ref: tracksRef, items: const <Object>[]),
    _payload(ref: collectionsRef, items: const <Object>[]),
  ];

  return Map<String, CataloguePayload>.unmodifiable(<String, CataloguePayload>{
    for (final payload in payloads)
      DemoCataloguePayloadGateway.keyOf(payload.ref): payload,
  });
}

Map<String, dynamic> _vertical({
  required String code,
  required String sectionCode,
  required String title,
  required int sortOrder,
}) {
  return <String, dynamic>{
    'code': code,
    'sectionCode': sectionCode,
    'title': title,
    'description': '$title learning path delivered by demo backend data.',
    'iconAssetId': 'demo-${code.toLowerCase()}',
    'sortOrder': sortOrder,
    'active': true,
  };
}

CataloguePayload _payload({
  required CatalogueRevisionRef ref,
  required List<Object> items,
}) {
  return CataloguePayload(
    ref: ref,
    items: items,
    wireJson: <String, Object?>{
      'kind': ref.kind.wireName,
      'revision': ref.revision,
      'checksum': ref.checksum,
      'items': items,
    },
  );
}
