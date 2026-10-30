import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/mock_practice_test.dart';

final mockTestRepositoryProvider = Provider<MockTestRepository>(
  (ref) => const MockTestRepository(),
);

class MockTestRepository {
  const MockTestRepository();

  List<MockPracticeTest> get all => const [
        MockPracticeTest(
          code: 'JAVA_SENIOR_QUICK_001',
          title: 'Java Senior · Quick Test',
          subtitle: '5 questions · Java Core, Concurrency, Spring',
          mode: MockTestMode.quick,
          questions: [
            MockQuestion(
              code: 'JAVA_Q_001',
              prompt: 'Which collection guarantees unique elements?',
              options: ['ArrayList', 'HashSet', 'LinkedList', 'ArrayDeque'],
              correctIndex: 1,
              skill: 'Java Collections',
              explanation: 'HashSet stores unique elements according to equals/hashCode semantics.',
            ),
            MockQuestion(
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
              explanation: 'Dependency injection separates dependency construction from the object that consumes it.',
            ),
            MockQuestion(
              code: 'JAVA_Q_003',
              prompt: 'Which type is designed for concurrent key/value access?',
              options: ['HashMap', 'TreeMap', 'ConcurrentHashMap', 'WeakHashMap'],
              correctIndex: 2,
              skill: 'Concurrency',
              explanation: 'ConcurrentHashMap provides thread-safe concurrent access without globally locking the map.',
            ),
            MockQuestion(
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
            MockQuestion(
              code: 'JAVA_Q_005',
              prompt: 'Which Spring annotation marks a REST controller?',
              options: ['@Service', '@Repository', '@RestController', '@ConfigurationProperties'],
              correctIndex: 2,
              skill: 'Spring MVC',
              explanation: '@RestController combines @Controller semantics with response-body handling.',
            ),
          ],
        ),
        MockPracticeTest(
          code: 'IELTS_ENV_EXAM_001',
          title: 'IELTS · Environment',
          subtitle: '4 questions · Vocabulary and speaking concepts',
          mode: MockTestMode.exam,
          questions: [
            MockQuestion(
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
              explanation: 'A balanced structure explicitly contrasts two perspectives.',
            ),
            MockQuestion(
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
              explanation: 'Sustainable transport aims to meet mobility needs while reducing long-term environmental and social costs.',
            ),
            MockQuestion(
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
              explanation: 'Part 3 rewards developed, relevant answers supported by explanation and examples.',
            ),
            MockQuestion(
              code: 'IELTS_Q_004',
              prompt: 'Which word is closest to “significant” in an academic context?',
              options: ['trivial', 'substantial', 'tiny', 'irrelevant'],
              correctIndex: 1,
              skill: 'Academic vocabulary',
              explanation: 'Substantial can mean considerable or significant in amount or importance.',
            ),
          ],
        ),
      ];

  MockPracticeTest? byCode(String code) {
    for (final test in all) {
      if (test.code == code) return test;
    }
    return null;
  }
}
