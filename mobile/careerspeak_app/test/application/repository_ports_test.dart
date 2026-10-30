import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/application/ports/content_repository.dart';
import 'package:careerspeak_app/application/ports/learner_state_repository.dart';
import 'package:careerspeak_app/application/ports/practice_test_repository.dart';
import 'package:careerspeak_app/application/query/content_query.dart';
import 'package:careerspeak_app/application/query/practice_test_query.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/mock/mock_content_repository.dart';
import 'package:careerspeak_app/data/mock/mock_test_repository.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('content repository port supports explicit test adapter', () async {
    const ContentRepository repository = MockContentRepository();

    final page = (await repository.watchContent(const ContentQuery()).first)
        .getOrThrow();
    expect(page.items, isNotEmpty);

    final item = (await repository.getByIdentity(
      const ContentIdentity(code: 'JAVA_DI_001', type: ContentType.interview),
    )).getOrThrow();
    expect(item?.title, 'Dependency Injection');

    final wrongType = (await repository.getByIdentity(
      const ContentIdentity(code: 'JAVA_DI_001', type: ContentType.topic),
    )).getOrThrow();
    expect(wrongType, isNull);
  });

  test('assessment repository port supports explicit test adapter', () async {
    const PracticeTestRepository repository = MockTestRepository();

    final page =
        (await repository.watchTests(const PracticeTestQuery()).first)
            .getOrThrow();
    expect(page.items, isNotEmpty);

    final test = (await repository.getByCode(
      'JAVA_SENIOR_QUICK_001',
    )).getOrThrow();
    expect(test?.questions.length, 5);
  });

  test('composition root exposes Drift learner state through port', () async {
    final database = CareerSpeakDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [careerSpeakDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    addTearDown(database.close);

    final repository = container.read(learnerStateRepositoryProvider);
    expect(repository, isA<LearnerStateRepository>());

    const identity = ContentIdentity(
      code: 'JAVA_DI_001',
      type: ContentType.topic,
    );
    (await repository.setFavorite(identity, favorite: true)).getOrThrow();

    final markers = (await repository.watchMarkers().first).getOrThrow();
    expect(markers[identity]?.favorite, isTrue);
  });
}
