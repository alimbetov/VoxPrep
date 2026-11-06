import '../../application/content_delivery/content_manifest.dart';
import '../../application/content_delivery/content_payload.dart';
import '../../application/content_delivery/typed_content_body.dart';
import '../../application/content_delivery/product_catalog.dart';
import '../../domain/assessment.dart';
import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';

const demoJavaContentCode = 'JAVA_DI_EXPLANATION';
const demoJavaContentChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const demoMedicalContentCode = 'MEDICAL_PATIENT_HANDOVER';
const demoMedicalContentChecksum =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const demoSharedContentCode = 'PROFESSIONAL_COMMUNICATION_BASICS';
const demoSharedContentChecksum =
    '1111111111111111111111111111111111111111111111111111111111111111';
const demoJavaTestCode = 'JAVA_DI_TEST';
const demoJavaTestChecksum =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const demoMedicalTestCode = 'MEDICAL_HANDOVER_TEST';
const demoMedicalTestChecksum =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const demoPackChecksum =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
const demoCatalogueIconAssetId = 'demo-catalogue-icon';
const _demoCatalogueIconChecksum =
    'ae8c4458e41f1e28b1e851ed87d3268d4a0351ceea427fa2a84cc94ddfb6d4c5';
const _javaQuestionChecksum =
    'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
const _medicalQuestionChecksum =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

final demoPackRef = PackRevisionRef(
  identity: PackIdentity(code: 'DEMO_CORE', variant: 'canonical'),
  revision: 1,
  checksum: demoPackChecksum,
);

final demoJavaPracticeTestRef = PracticeTestRevisionRef(
  practiceTestCode: demoJavaTestCode,
  revision: 1,
  checksum: demoJavaTestChecksum,
);

final demoMedicalPracticeTestRef = PracticeTestRevisionRef(
  practiceTestCode: demoMedicalTestCode,
  revision: 1,
  checksum: demoMedicalTestChecksum,
);

PackContentManifest buildDemoPackManifest() {
  return PackContentManifest(
    schemaVersion: 1,
    identity: demoPackRef.identity,
    revision: demoPackRef.revision,
    checksum: demoPackRef.checksum,
    contents: [
      PackContentRef(
        identity: const ContentIdentity(
          code: demoJavaContentCode,
          type: ContentType.topic,
        ),
        revision: 1,
        checksum: demoJavaContentChecksum,
        sortOrder: 0,
      ),
      PackContentRef(
        identity: const ContentIdentity(
          code: demoMedicalContentCode,
          type: ContentType.topic,
        ),
        revision: 1,
        checksum: demoMedicalContentChecksum,
        sortOrder: 10,
      ),
      PackContentRef(
        identity: const ContentIdentity(
          code: demoSharedContentCode,
          type: ContentType.topic,
        ),
        revision: 1,
        checksum: demoSharedContentChecksum,
        sortOrder: 20,
      ),
    ],
    assets: [
      ManifestAssetDescriptor(
        assetId: 'demo-communication-cover',
        checksumSha256:
            '82f94490be051b3cbb945eb7b0bf64161c3f49b9384931f0ded55226c54ec2d9',
        deliveryKey: 'demo/communication-cover.png',
        sizeBytes: 20165,
        mediaType: 'image/png',
        requiredOffline: true,
      ),
      ManifestAssetDescriptor(
        assetId: 'demo-medical-cover',
        checksumSha256:
            '1beac535feceaf166da3b8813cbecc1bcd8d59836f80557b8da47b95cc9888c5',
        deliveryKey: 'demo/medical-cover.png',
        sizeBytes: 21168,
        mediaType: 'image/png',
        requiredOffline: true,
      ),
      ManifestAssetDescriptor(
        assetId: 'demo-java-cover',
        checksumSha256:
            'ff5dbc07a77b3903feac1cc3f2b4f80573324abef2e234e91be069f6339d9340',
        deliveryKey: 'demo/java-cover.png',
        sizeBytes: 23412,
        mediaType: 'image/png',
        requiredOffline: true,
      ),
      ManifestAssetDescriptor(
        assetId: 'demo-speaking-audio',
        checksumSha256:
            'c1be998c4d43fcdbafbd198ab14c035b77695cbecfceab9b9e1d8cc6f4dfd493',
        deliveryKey: 'demo/speaking-sample.mp3',
        sizeBytes: 32877,
        mediaType: 'audio/mpeg',
        requiredOffline: true,
      ),
      ManifestAssetDescriptor(
        assetId: demoCatalogueIconAssetId,
        checksumSha256: _demoCatalogueIconChecksum,
        deliveryKey: 'demo/catalogue-icon.png',
        sizeBytes: 1066,
        mediaType: 'image/png',
        requiredOffline: false,
      ),
    ],
    contentAssets: [
      ContentAssetRef(
        contentIdentity: const ContentIdentity(
          code: demoSharedContentCode,
          type: ContentType.topic,
        ),
        contentRevision: 1,
        assetId: 'demo-communication-cover',
        role: 'coverImage',
      ),
      ContentAssetRef(
        contentIdentity: const ContentIdentity(
          code: demoMedicalContentCode,
          type: ContentType.topic,
        ),
        contentRevision: 1,
        assetId: 'demo-medical-cover',
        role: 'coverImage',
      ),
      ContentAssetRef(
        contentIdentity: const ContentIdentity(
          code: demoJavaContentCode,
          type: ContentType.topic,
        ),
        contentRevision: 1,
        assetId: 'demo-java-cover',
        role: 'coverImage',
      ),
      ContentAssetRef(
        contentIdentity: const ContentIdentity(
          code: demoSharedContentCode,
          type: ContentType.topic,
        ),
        contentRevision: 1,
        assetId: 'demo-speaking-audio',
        role: 'narration',
      ),
    ],
  );
}

List<ContentPayload> buildDemoContentPayloads() {
  return [
    ContentPayload(
      ref: ContentPayloadRef(
        identity: const ContentIdentity(
          code: demoJavaContentCode,
          type: ContentType.topic,
        ),
        revision: 1,
        checksum: demoJavaContentChecksum,
      ),
      title: 'Explaining dependency injection',
      subtitle: 'Java interview communication',
      description:
          'Practice explaining dependency injection clearly and concisely in an interview.',
      categoryCode: 'JAVA_INTERVIEW',
      category: 'Java Interview',
      levelCode: 'B2',
      level: 'B2',
      minutes: 6,
      hasAudio: /* demo */ false,
      body: TopicBody(
        sections: [
          TopicSection(
            heading: 'Core idea',
            text:
                'Dependency injection means that an object receives its dependencies from outside instead of constructing them itself. This separates application behaviour from object creation.',
          ),
          TopicSection(
            heading: 'Example interview answer',
            text:
                'In our service, the controller receives an order service through its constructor. The service receives a repository in the same way. Spring creates and connects these objects. In tests, I can provide a fake repository without starting the whole application.',
          ),
          TopicSection(
            heading: 'Vocabulary',
            text:
                'Dependency: an object another object needs. Coupling: how strongly components depend on each other. Constructor injection: passing dependencies as constructor arguments. Testability: how easily behaviour can be verified in isolation.',
          ),
          TopicSection(
            heading: 'Speaking practice',
            text:
                'Explain dependency injection in three sentences. Give one example from a project. Finish with a benefit and a trade-off: explicit dependencies improve testability, but too many constructor parameters can signal too many responsibilities.',
          ),
        ],
      ),

      skillCodes: const <String>['INTERVIEW_SPEAKING'],
    ),
    ContentPayload(
      ref: ContentPayloadRef(
        identity: const ContentIdentity(
          code: demoMedicalContentCode,
          type: ContentType.topic,
        ),
        revision: 1,
        checksum: demoMedicalContentChecksum,
      ),
      title: 'Patient handover essentials',
      subtitle: 'Medical English communication',
      description:
          'Practice a concise patient handover using clear clinical English.',
      categoryCode: 'MEDICAL_ENGLISH',
      category: 'Medical English',
      levelCode: 'B2',
      level: 'B2',
      minutes: 7,
      hasAudio: /* demo */ false,
      body: TopicBody(
        sections: [
          TopicSection(
            heading: 'Situation and background',
            text:
                'A useful patient handover has a clear structure: situation, background, assessment and recommendation. This is a fictional language exercise, not clinical guidance.',
          ),
          TopicSection(
            heading: 'Model handover',
            text:
                'Situation: I am handing over a fictional patient admitted for observation. Background: the patient arrived earlier today. Assessment: the current observations are recorded in the chart. Recommendation: please review the documented care plan with the supervising clinician.',
          ),
          TopicSection(
            heading: 'Useful language',
            text:
                'I would like to hand over… The relevant background is… My main concern is… Could you please confirm…? Avoid ambiguous pronouns and unexplained abbreviations.',
          ),
          TopicSection(
            heading: 'Speaking practice',
            text:
                'Create a fictional thirty-second handover. State the situation first, then give relevant background. Ask your listener to repeat the key next step. Do not use real patient information.',
          ),
        ],
      ),

      skillCodes: const <String>['PROFESSIONAL_SPEAKING'],
    ),
    ContentPayload(
      ref: ContentPayloadRef(
        identity: const ContentIdentity(
          code: demoSharedContentCode,
          type: ContentType.topic,
        ),
        revision: 1,
        checksum: demoSharedContentChecksum,
      ),
      title: 'Professional communication basics',
      subtitle: 'Reusable demo learning material',
      description:
          'Practice concise explanations, structured answers and domain vocabulary. Audio example: I build reliable services and verify recovery paths.',
      categoryCode: 'PROFESSIONAL_ENGLISH',
      category: 'Professional English',
      levelCode: 'B1',
      level: 'B1',
      minutes: 5,
      hasAudio: true,
      body: TopicBody(
        sections: [
          TopicSection(
            heading: 'Structure your answer',
            text:
                'Start with your main point. Add one concrete example. Explain the outcome. End by checking whether your listener needs more detail.',
          ),
          TopicSection(
            heading: 'Model answer',
            text:
                'We reduced delays by making the handover checklist shorter. For example, we moved repeated information into a shared template. This made the next step easier to identify. Would you like me to explain how we measured the change?',
          ),
          TopicSection(
            heading: 'Useful phrases',
            text:
                'The main point is… For example… As a result… One limitation is… Let me clarify… Could you confirm what you mean by…?',
          ),
          TopicSection(
            heading: 'Speaking practice',
            text:
                'Choose a familiar task. Explain it to a new colleague in sixty seconds. Replace jargon with plain language. Ask a follow-up question to check understanding.',
          ),
        ],
      ),

      skillCodes: const <String>['PROFESSIONAL_SPEAKING'],
    ),
  ];
}

List<PracticeTestRevision> buildDemoPracticeTests() {
  return [
    PracticeTestRevision(
      practiceTestCode: demoJavaTestCode,
      revision: 1,
      checksum: demoJavaTestChecksum,
      title: 'Dependency Injection Check',
      subtitle: 'Java interview quick check',
      mode: AssessmentMode.quick,
      passingScoreBasisPoints: 7000,
      questionRefs: [
        PracticeTestQuestionRef(
          order: 0,
          question: QuestionRevisionId(
            questionCode: 'JAVA_DI_Q1',
            revision: 1,
            checksum: _javaQuestionChecksum,
          ),
          points: 1,
        ),
      ],
    ),
    PracticeTestRevision(
      practiceTestCode: demoMedicalTestCode,
      revision: 1,
      checksum: demoMedicalTestChecksum,
      title: 'Patient Handover Check',
      subtitle: 'Medical English quick check',
      mode: AssessmentMode.quick,
      passingScoreBasisPoints: 7000,
      questionRefs: [
        PracticeTestQuestionRef(
          order: 0,
          question: QuestionRevisionId(
            questionCode: 'MEDICAL_HANDOVER_Q1',
            revision: 1,
            checksum: _medicalQuestionChecksum,
          ),
          points: 1,
        ),
      ],
    ),
  ];
}

List<AssessmentQuestionRevision> buildDemoAssessmentQuestions() {
  return [
    AssessmentQuestionRevision(
      id: QuestionRevisionId(
        questionCode: 'JAVA_DI_Q1',
        revision: 1,
        checksum: _javaQuestionChecksum,
      ),
      body: SingleChoiceQuestionBody(
        prompt: 'What is the main purpose of dependency injection?',
        options: const [
          'Move dependency creation outside the consumer',
          'Increase direct coupling between classes',
          'Replace every interface with a concrete class',
          'Disable automated testing',
        ],
        correctOptionIndex: 0,
        skillCode: 'INTERVIEW_SPEAKING',
        explanation:
            'Dependency injection separates dependency construction from the object that consumes it.',
      ),
    ),
    AssessmentQuestionRevision(
      id: QuestionRevisionId(
        questionCode: 'MEDICAL_HANDOVER_Q1',
        revision: 1,
        checksum: _medicalQuestionChecksum,
      ),
      body: SingleChoiceQuestionBody(
        prompt: 'Which detail is essential in a concise patient handover?',
        options: const [
          'Current clinical concern and relevant background',
          'Unrelated personal history',
          'Every detail from the entire medical record',
          'Only the patient name with no clinical context',
        ],
        correctOptionIndex: 0,
        skillCode: 'PROFESSIONAL_SPEAKING',
        explanation:
            'A useful handover prioritizes the current concern and the background needed for safe continuity of care.',
      ),
    ),
  ];
}
