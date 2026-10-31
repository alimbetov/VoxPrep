final class ApiErrorDto {
  const ApiErrorDto({
    required this.code,
    required this.message,
    required this.traceId,
    required this.details,
  });

  final String? code;
  final String? message;
  final String? traceId;
  final Map<String, Object?> details;
}
