import 'package:careerspeak_app/app/repository_providers.dart';
import 'package:careerspeak_app/application/ports/content_repository.dart';
import 'package:careerspeak_app/application/ports/practice_test_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('composition root exposes content repository through port', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final repository = container.read(contentRepositoryProvider);

    expect(repository, isA<ContentRepository>());
    expect(repository.all, isNotEmpty);
    expect(repository.byCode('JAVA_DI_001')?.title, 'Dependency Injection');
  });

  test('composition root exposes assessment repository through port', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final repository = container.read(practiceTestRepositoryProvider);

    expect(repository, isA<PracticeTestRepository>());
    expect(repository.all, isNotEmpty);
    expect(repository.byCode('JAVA_SENIOR_QUICK_001')?.questions.length, 5);
  });
}
