sealed class Result<T> {
  const Result();

  T getOrThrow() => switch (this) {
        Success<T>(:final value) => value,
        FailureResult<T>(:final failure) => throw ApplicationFailureException(failure),
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final ApplicationFailure failure;
}

class ApplicationFailure {
  const ApplicationFailure({
    required this.code,
    required this.message,
    this.retryable = false,
  });

  final String code;
  final String message;
  final bool retryable;
}

class ApplicationFailureException implements Exception {
  const ApplicationFailureException(this.failure);

  final ApplicationFailure failure;

  @override
  String toString() => '${failure.code}: ${failure.message}';
}
