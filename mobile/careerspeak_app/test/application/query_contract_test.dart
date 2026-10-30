import 'package:careerspeak_app/application/query/content_query.dart';
import 'package:careerspeak_app/application/query/page.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/mock/mock_content_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('content pagination uses opaque cursor semantics', () async {
    const repository = MockContentRepository();

    final first = (await repository
            .watchContent(
              const ContentQuery(page: PageRequest(limit: 2)),
            )
            .first)
        .getOrThrow();

    expect(first.items.length, 2);
    expect(first.hasMore, isTrue);
    expect(first.nextCursor, first.items.last.code);

    final second = (await repository
            .watchContent(
              ContentQuery(
                page: PageRequest(limit: 2, cursor: first.nextCursor),
              ),
            )
            .first)
        .getOrThrow();

    expect(second.items.length, 2);
    expect(second.items.first.code, isNot(first.items.first.code));
  });

  test('typed failure contract throws an application failure exception', () {
    const result = FailureResult<int>(
      ApplicationFailure(
        code: 'TEST_FAILURE',
        message: 'Qualification failure',
        retryable: true,
      ),
    );

    expect(
      result.getOrThrow,
      throwsA(
        isA<ApplicationFailureException>().having(
          (error) => error.failure.retryable,
          'retryable',
          isTrue,
        ),
      ),
    );
  });
}
