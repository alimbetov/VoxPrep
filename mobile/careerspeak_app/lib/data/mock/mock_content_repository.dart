import '../../application/ports/content_repository.dart';
import '../../domain/content_item.dart';

class MockContentRepository implements ContentRepository {
  const MockContentRepository();

  @override
  List<ContentItem> get all => const [
        ContentItem(
          code: 'JAVA_DI_001',
          type: ContentType.interview,
          title: 'Dependency Injection',
          subtitle: 'Java Backend · Senior interview',
          description:
              'Explain dependency injection, why it improves testability, and how Spring resolves dependencies.',
          category: 'Java Backend',
          level: 'Senior',
          minutes: 8,
        ),
        ContentItem(
          code: 'JAVA_CONCURRENCY_001',
          type: ContentType.interview,
          title: 'ConcurrentHashMap',
          subtitle: 'Java · Concurrency',
          description:
              'Describe the concurrency guarantees of ConcurrentHashMap and compare it with HashMap.',
          category: 'Java Backend',
          level: 'Senior',
          minutes: 10,
        ),
        ContentItem(
          code: 'VOCAB_SIGNIFICANT',
          type: ContentType.vocabulary,
          title: 'significant',
          subtitle: '/sɪɡˈnɪfɪkənt/ · adjective · B2',
          description:
              'Sufficiently great or important to be worthy of attention; noteworthy.',
          category: 'Vocabulary',
          level: 'B2',
          minutes: 3,
        ),
        ContentItem(
          code: 'VOCAB_SUBSTANTIAL',
          type: ContentType.vocabulary,
          title: 'substantial',
          subtitle: '/səbˈstænʃəl/ · adjective · C1',
          description: 'Large in amount, value or importance.',
          category: 'Vocabulary',
          level: 'C1',
          minutes: 3,
        ),
        ContentItem(
          code: 'IELTS_ENV_001',
          type: ContentType.topic,
          title: 'Urban Environment',
          subtitle: 'IELTS Speaking · Part 3',
          description:
              'Discuss how cities can reduce congestion and improve quality of life.',
          category: 'IELTS',
          level: 'B2-C1',
          minutes: 12,
        ),
        ContentItem(
          code: 'SHADOW_SYSTEM_DESIGN_001',
          type: ContentType.shadowing,
          title: 'Explaining System Design',
          subtitle: 'Shadowing · Software Engineering',
          description:
              'Practice a concise explanation of scalability, caching and database trade-offs.',
          category: 'Professional English',
          level: 'C1',
          minutes: 7,
        ),
        ContentItem(
          code: 'PHRASE_CLARIFY_001',
          type: ContentType.phrase,
          title: 'Could you clarify what you mean by…?',
          subtitle: 'Interview phrase · Clarification',
          description:
              'A professional phrase for requesting clarification before answering.',
          category: 'Phrase Bank',
          level: 'B1+',
          minutes: 2,
        ),
      ];

  @override
  ContentItem? byCode(String code) {
    for (final item in all) {
      if (item.code == code) return item;
    }
    return null;
  }
}
