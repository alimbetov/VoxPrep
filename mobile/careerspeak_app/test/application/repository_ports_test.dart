import 'package:careerspeak_app/app/repository_providers.dart';
import 'package:careerspeak_app/application/ports/content_repository.dart';
import 'package:careerspeak_app/application/ports/practice_test_repository.dart';
import 'package:careerspeak_app/application/query/content_query.dart';
import 'package:careerspeak_app/application/query/practice_test_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'composition root exposes reactive content repository through port',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(contentRepositoryProvider);

      expect(repository, isA<ContentRepository>());

      final page = (await repository.watchContent(const ContentQuery()).first)
          .getOrThrow();
      expect(page.items, isNotEmpty);

      final item = (await repository.getByCode('JAVA_DI_001')).getOrThrow();
      expect(item?.title, 'Dependency Injection');
    },
  );

  test(
    'composition root exposes reactive assessment repository through port',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(practiceTestRepositoryProvider);

      expect(repository, isA<PracticeTestRepository>());

      final page =
          (await repository.watchTests(const PracticeTestQuery()).first)
              .getOrThrow();
      expect(page.items, isNotEmpty);

      final test = (await repository.getByCode(
        'JAVA_SENIOR_QUICK_001',
      )).getOrThrow();
      expect(test?.questions.length, 5);
    },
  );
}
