import '../../application/content_delivery/catalogue_payload.dart';
import '../../application/content_delivery/catalogue_revision_ref.dart';
import 'demo_catalogue_payload_gateway.dart';
import 'demo_learning_fixture.dart';

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
    _section(
      'SOFTWARE_ENGINEERING',
      'Software Engineering',
      'Interview and engineering communication.',
      'demo-section-software',
      0,
    ),
    _section(
      'CLOUD_PLATFORM',
      'Cloud & Platform',
      'Cloud and infrastructure English.',
      'demo-section-cloud',
      10,
    ),
    _section(
      'ENGLISH_COMMUNICATION',
      'English & Communication',
      'Professional English for domain communication.',
      'demo-section-english',
      20,
    ),
  ];

  final specs = <_DemoVerticalSpec>[
    const _DemoVerticalSpec(
      'JAVA_INTERVIEW',
      'SOFTWARE_ENGINEERING',
      'Java Interview',
      'Pass a Java backend interview',
      'Java backend interview track',
      'JAVA',
      0,
    ),
    const _DemoVerticalSpec(
      'QA_INTERVIEW',
      'SOFTWARE_ENGINEERING',
      'QA Interview',
      'Pass a QA interview',
      'QA interview track',
      'QA',
      10,
    ),
    const _DemoVerticalSpec(
      'DEVOPS_INTERVIEW',
      'SOFTWARE_ENGINEERING',
      'DevOps Interview',
      'Pass a DevOps interview',
      'DevOps interview track',
      'DEVOPS',
      20,
    ),
    const _DemoVerticalSpec(
      'AWS',
      'CLOUD_PLATFORM',
      'AWS',
      'Communicate AWS knowledge',
      'AWS communication track',
      'AWS',
      0,
    ),
    const _DemoVerticalSpec(
      'KUBERNETES',
      'CLOUD_PLATFORM',
      'Kubernetes',
      'Communicate Kubernetes knowledge',
      'Kubernetes communication track',
      'KUBERNETES',
      10,
    ),
    const _DemoVerticalSpec(
      'MEDICAL_ENGLISH',
      'ENGLISH_COMMUNICATION',
      'Medical English',
      'Communicate safely in clinical contexts',
      'Medical English track',
      'MEDICAL',
      0,
    ),
    const _DemoVerticalSpec(
      'SALES_ENGLISH',
      'ENGLISH_COMMUNICATION',
      'Sales English',
      'Communicate clearly in sales conversations',
      'Sales English track',
      'SALES',
      10,
    ),
    const _DemoVerticalSpec(
      'BANKING_ENGLISH',
      'ENGLISH_COMMUNICATION',
      'Banking English',
      'Communicate clearly in banking contexts',
      'Banking English track',
      'BANKING',
      20,
    ),
  ];

  final verticals = <Object>[
    for (final spec in specs)
      _vertical(
        code: spec.code,
        sectionCode: spec.sectionCode,
        title: spec.title,
        sortOrder: spec.sortOrder,
      ),
  ];

  final goals = <Object>[
    for (final spec in specs)
      <String, dynamic>{
        'code': '${spec.code}_GOAL',
        'verticalCode': spec.code,
        'title': spec.goalTitle,
        'description': '${spec.title} demo learning goal.',
        'sortOrder': 0,
        'active': true,
      },
  ];

  final tracks = <Object>[
    for (final spec in specs)
      <String, dynamic>{
        'code': '${spec.code}_TRACK',
        'verticalCode': spec.code,
        'goalCode': '${spec.code}_GOAL',
        'title': spec.trackTitle,
        'description': '${spec.title} structured demo track.',
        'levelCode': 'B2',
        'careerTrackCode': spec.careerTrackCode,
        'sortOrder': 0,
        'active': true,
      },
  ];

  final collections = <Object>[
    for (final spec in specs)
      <String, dynamic>{
        'code': '${spec.code}_COLLECTION',
        'verticalCode': spec.code,
        'trackCode': '${spec.code}_TRACK',
        'title': '${spec.title} Essentials',
        'description': 'Representative demo collection for ${spec.title}.',
        'sortOrder': 0,
        'active': true,
        'members': _membersFor(spec.code),
      },
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
    _payload(ref: goalsRef, items: goals),
    _payload(ref: tracksRef, items: tracks),
    _payload(ref: collectionsRef, items: collections),
  ];

  return Map<String, CataloguePayload>.unmodifiable(<String, CataloguePayload>{
    for (final payload in payloads)
      DemoCataloguePayloadGateway.keyOf(payload.ref): payload,
  });
}

List<Object> _membersFor(String verticalCode) {
  if (verticalCode == 'JAVA_INTERVIEW') {
    return <Object>[
      _contentMember(0, demoJavaContentCode, demoJavaContentChecksum),
      _testMember(1, demoJavaTestCode, demoJavaTestChecksum),
    ];
  }
  if (verticalCode == 'MEDICAL_ENGLISH') {
    return <Object>[
      _contentMember(0, demoMedicalContentCode, demoMedicalContentChecksum),
      _testMember(1, demoMedicalTestCode, demoMedicalTestChecksum),
    ];
  }
  return <Object>[
    _contentMember(0, demoSharedContentCode, demoSharedContentChecksum),
  ];
}

Map<String, dynamic> _contentMember(
  int position,
  String code,
  String checksum,
) => <String, dynamic>{
  'position': position,
  'type': 'CONTENT',
  'content': <String, dynamic>{
    'contentCode': code,
    'contentType': 'topic',
    'revision': 1,
    'checksum': checksum,
  },
  'practiceTest': null,
};

Map<String, dynamic> _testMember(int position, String code, String checksum) =>
    <String, dynamic>{
      'position': position,
      'type': 'PRACTICE_TEST',
      'content': null,
      'practiceTest': <String, dynamic>{
        'practiceTestCode': code,
        'revision': 1,
        'checksum': checksum,
      },
    };

Map<String, dynamic> _section(
  String code,
  String title,
  String description,
  String iconAssetId,
  int sortOrder,
) => <String, dynamic>{
  'code': code,
  'title': title,
  'description': description,
  'iconAssetId': iconAssetId,
  'sortOrder': sortOrder,
  'active': true,
};

Map<String, dynamic> _vertical({
  required String code,
  required String sectionCode,
  required String title,
  required int sortOrder,
}) => <String, dynamic>{
  'code': code,
  'sectionCode': sectionCode,
  'title': title,
  'description': '$title learning path delivered by demo backend data.',
  'iconAssetId': 'demo-${code.toLowerCase()}',
  'sortOrder': sortOrder,
  'active': true,
};

CataloguePayload _payload({
  required CatalogueRevisionRef ref,
  required List<Object> items,
}) => CataloguePayload(
  ref: ref,
  items: items,
  wireJson: <String, Object?>{
    'kind': ref.kind.wireName,
    'revision': ref.revision,
    'checksum': ref.checksum,
    'items': items,
  },
);

final class _DemoVerticalSpec {
  const _DemoVerticalSpec(
    this.code,
    this.sectionCode,
    this.title,
    this.goalTitle,
    this.trackTitle,
    this.careerTrackCode,
    this.sortOrder,
  );

  final String code;
  final String sectionCode;
  final String title;
  final String goalTitle;
  final String trackTitle;
  final String careerTrackCode;
  final int sortOrder;
}
