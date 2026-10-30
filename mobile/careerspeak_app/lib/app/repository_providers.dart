import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/content_repository.dart';
import '../application/ports/practice_test_repository.dart';
import '../data/mock/mock_content_repository.dart';
import '../data/mock/mock_test_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => const MockContentRepository(),
);

final practiceTestRepositoryProvider = Provider<PracticeTestRepository>(
  (ref) => const MockTestRepository(),
);
