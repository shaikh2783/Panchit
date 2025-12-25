class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  @override
  String toString() {
    final codePart = statusCode != null ? ' (code: $statusCode)' : '';
    return 'ApiException$codePart: $message';
  }
}
