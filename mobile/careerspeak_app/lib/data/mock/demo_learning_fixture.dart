import '../../application/content_delivery/content_manifest.dart';
import '../../application/content_delivery/content_payload.dart';
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
    assets: const <ManifestAssetDescriptor>[],
    contentAssets: const <ContentAssetRef>[],
  );
}

List<ContentPayload> buildDemoContentPayloads() {
  return [
    ContentPayload(
      ref: ContentPayloadRef(
        identity: const ContentIdentity(code: demoJavaContentCode, type: ContentType.topic),
        revision: 1,
        checksum: demoJavaContentChecksum,
      ),
      title: 'Explaining dependency injection',
      subtitle: 'Java interview communication',
      description: 'Practice explaining dependency injection clearly and concisely in an interview.',
      categoryCode: 'JAVA_INTERVIEW',
      category: 'Java Interview',
      levelCode: 'B2',
      level: 'B2',
      minutes: 6,
      hasAudio: false,
      skillCodes: const <String>['INTERVIEW_SPEAKING'],
    ),
    ContentPayload(
      ref: ContentPayloadRef(
        identity: const ContentIdentity(code: demoMedicalContentCode, type: ContentType.topic),
        revision: 1,
        checksum: demoMedicalContentChecksum,
      ),
      title: 'Patient handover essentials',
      subtitle: 'Medical English communication',
      description: 'Practice a concise patient handover using clear clinical English.',
      categoryCode: 'MEDICAL_ENGLISH',
      category: 'Medical English',
      levelCode: 'B2',
      level: 'B2',
      minutes: 7,
      hasAudio: false,
      skillCodes: const <String>['PROFESSIONAL_SPEAKING'],
    ),
    ContentPayload(
      ref: ContentPayloadRef(
        identity: const ContentIdentity(code: demoSharedContentCode, type: ContentType.topic),
        revision: 1,
        checksum: demoSharedContentChecksum,
      ),
      title: 'Professional communication basics',
      subtitle: 'Reusable demo learning material',
      description: 'Practice concise explanations, structured answers and domain vocabulary.',
      categoryCode: 'PROFESSIONAL_ENGLISH',
      category: 'Professional English',
      levelCode: 'B1',
      level: 'B1',
      minutes: 5,
      hasAudio: false,
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
          question: QuestionRevisionId(questionCode: 'JAVA_DI_Q1', revision: 1, checksum: _javaQuestionChecksum),
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
          question: QuestionRevisionId(questionCode: 'MEDICAL_HANDOVER_Q1', revision: 1, checksum: _medicalQuestionChecksum),
          points: 1,
        ),
      ],
    ),
  ];
}

List<AssessmentQuestionRevision> buildDemoAssessmentQuestions() {
  return [
    AssessmentQuestionRevision(
      id: QuestionRevisionId(questionCode: 'JAVA_DI_Q1', revision: 1, checksum: _javaQuestionChecksum),
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
        explanation: 'Dependency injection separates dependency construction from the object that consumes it.',
      ),
    ),
    AssessmentQuestionRevision(
      id: QuestionRevisionId(questionCode: 'MEDICAL_HANDOVER_Q1', revision: 1, checksum: _medicalQuestionChecksum),
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
        explanation: 'A useful handover prioritizes the current concern and the background needed for safe continuity of care.',
      ),
    ),
  ];
}
