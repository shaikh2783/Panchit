/// Custom exception for Groups API and Management errors
class GroupException implements Exception {
  final int code;
  final String message;
  const GroupException({
    required this.code,
    required this.message,
  });
  @override
  String toString() => 'GroupException($code): $message';
}
/// Result class for group join operations
class GroupJoinResult {
  final String status;
  final bool approved;
  GroupJoinResult({
    required this.status,
    required this.approved,
  });
  factory GroupJoinResult.fromJson(Map<String, dynamic> json) {
    return GroupJoinResult(
      status: json['status'] as String,
      approved: json['approved'] as bool,
    );
  }
  bool get isPending => status == 'pending' && !approved;
  bool get isApproved => status == 'approved' && approved;
}