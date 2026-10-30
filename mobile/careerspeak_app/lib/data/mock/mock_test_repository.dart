import '../../application/ports/practice_test_repository.dart';
import '../../application/query/page.dart';
import '../../application/query/practice_test_query.dart';
import '../../application/result/result.dart';
import '../../domain/practice_test.dart';

class MockTestRepository implements PracticeTestRepository {
  const MockTestRepository();

  static const _tests = <PracticeTest>[
    PracticeTest(
      code: 'JAVA_SENIOR_QUICK_001',
      title: 'Java Senior · Quick Test',
      subtitle: '5 questions · Java Core, Concurrency, Spring',
      mode: PracticeTestMode.quick,
      questions: [
        PracticeQuestion(
          code: 'JAVA_Q_001',
          prompt: 'Which collection guarantees unique elements?',
          options: ['ArrayList', 'HashSet', 'LinkedList', 'ArrayDeque'],
          correctIndex: 1,
          skill: 'Java Collections',
          explanation:
              'HashSet stores unique elements according to equals/hashCode semantics.',
        ),
        PracticeQuestion(
          code: 'JAVA_Q_002',
          prompt: 'What is the primary purpose of dependency injection?',
          options: [
            'Increase coupling',
            'Move object creation outside consumers',
            'Replace interfaces',
            'Disable testing',
          ],
          correctIndex: 1,
          skill: 'Spring Core',
          explanation:
              'Dependency injection separates dependency construction from the object that consumes it.',
        ),
        PracticeQuestion(
          code: 'JAVA_Q_003',
          prompt: 'Which type is designed for concurrent key/value access?',
          options: ['HashMap', 'TreeMap', 'ConcurrentHashMap', 'WeakHashMap'],
          correctIndex: 2,
          skill: 'Concurrency',
          explanation:
              'ConcurrentHashMap provides thread-safe concurrent access without globally locking the map.',
        ),
        PracticeQuestion(
          code: 'JAVA_Q_004',
          prompt: 'What does JVM stand for?',
          options: [
            'Java Variable Manager',
            'Java Virtual Machine',
            'Java Version Module',
            'Joint Virtual Memory',
          ],
          correctIndex: 1,
          skill: 'JVM',
          explanation: 'JVM means Java Virtual Machine.',
        ),
        PracticeQuestion(
          code: 'JAVA_Q_005',
          prompt: 'Which Spring annotation marks a REST controller?',
          options: [
            '@Service',
            '@Repository',
            '@RestController',
            '@ConfigurationProperties',
          ],
          correctIndex: 2,
          skill: 'Spring MVC',
          explanation:
              '@RestController combines @Controller semantics with response-body handling.',
        ),
      ],
    ),
    PracticeTest(
      code: 'IELTS_ENV_EXAM_001',
      title: 'IELTS · Environment',
      subtitle: '4 questions · Vocabulary and speaking concepts',
      mode: PracticeTestMode.exam,
      questions: [
        PracticeQuestion(
          code: 'IELTS_Q_001',
          prompt: 'Which phrase best introduces a balanced opinion?',
          options: [
            'There is only one possible answer.',
            'On the one hand…, while on the other hand…',
            'I refuse to consider alternatives.',
            'Obviously everybody agrees.',
          ],
          correctIndex: 1,
          skill: 'Speaking coherence',
          explanation:
              'A balanced structure explicitly contrasts two perspectives.',
        ),
        PracticeQuestion(
          code: 'IELTS_Q_002',
          prompt: 'What does “sustainable transport” most closely mean?',
          options: [
            'Transport with lower long-term environmental impact',
            'Only private cars',
            'Transport used once',
            'The fastest possible transport',
          ],
          correctIndex: 0,
          skill: 'Environment vocabulary',
          explanation:
              'Sustainable transport aims to meet mobility needs while reducing long-term environmental and social costs.',
        ),
        PracticeQuestion(
          code: 'IELTS_Q_003',
          prompt: 'Which answer is most appropriate for IELTS Part 3?',
          options: [
            'Yes.',
            'No.',
            'A developed answer with reasons and an example',
            'One memorized sentence unrelated to the question',
          ],
          correctIndex: 2,
          skill: 'Speaking development',
          explanation:
              'Part 3 rewards developed, relevant answers supported by explanation and examples.',
        ),
        PracticeQuestion(
          code: 'IELTS_Q_004',
          prompt:
              'Which word is closest to “significant” in an academic context?',
          options: ['trivial', 'substantial', 'tiny', 'irrelevant'],
          correctIndex: 1,
          skill: 'Academic vocabulary',
          explanation:
              'Substantial can mean considerable or significant in amount or importance.',
        ),
      ],
    ),
  ];

  @override
  Stream<Result<Page<PracticeTestSummary>>> watchTests(
    PracticeTestQuery query,
  ) {
    final filtered = _tests
        .where((test) => query.mode == null || test.mode == query.mode)
        .map((test) => test.summary)
        .toList(growable: false);

    return Stream.value(Success(_page(filtered, query.page)));
  }

  @override
  Future<Result<PracticeTest?>> getByCode(String code) async {
    for (final test in _tests) {
      if (test.code == code) return Success(test);
    }
    return const Success(null);
  }
}

Page<PracticeTestSummary> _page(
  List<PracticeTestSummary> items,
  PageRequest request,
) {
  final cursorIndex = request.cursor == null
      ? -1
      : items.indexWhere((item) => item.code == request.cursor);
  final start = cursorIndex < 0 ? 0 : cursorIndex + 1;
  final end = start + request.limit > items.length
      ? items.length
      : start + request.limit;
  final pageItems = items.sublist(start, end);
  final hasMore = end < items.length;

  return Page(
    items: pageItems,
    hasMore: hasMore,
    nextCursor: hasMore && pageItems.isNotEmpty ? pageItems.last.code : null,
  );
}
