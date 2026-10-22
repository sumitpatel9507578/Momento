class ReportModel {
  final String id;
  final String reporterId;
  final String reporterUsername;
  final String targetId;
  final String targetType; // user, post, reel, comment, story
  final String targetTitle;
  final String reason;
  final String details;
  final String status; // open, under_review, resolved, dismissed
  final String adminNote;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.reporterId,
    this.reporterUsername = '',
    required this.targetId,
    required this.targetType,
    this.targetTitle = '',
    required this.reason,
    this.details = '',
    this.status = 'open',
    this.adminNote = '',
    required this.createdAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: (map['id'] ?? map['report_id'] ?? '').toString(),
      reporterId: (map['reporterId'] ?? map['reporter_id'] ?? map['userId'] ?? '').toString(),
      reporterUsername: map['reporterUsername'] ?? map['reporter_username'] ?? map['username'] ?? '',
      targetId: (map['targetId'] ?? map['target_id'] ?? '').toString(),
      targetType: map['targetType'] ?? map['target_type'] ?? 'post',
      targetTitle: map['targetTitle'] ?? map['target_title'] ?? '',
      reason: map['reason'] ?? 'Other',
      details: map['details'] ?? map['explanation'] ?? '',
      status: map['status'] ?? 'open',
      adminNote: map['adminNote'] ?? map['admin_note'] ?? '',
      createdAt: _parseDate(map['createdAt'] ?? map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': reporterId,
      'reporterId': reporterId,
      'reporterUsername': reporterUsername,
      'targetId': targetId,
      'targetType': targetType,
      'targetTitle': targetTitle,
      'reason': reason,
      'details': details,
      'status': status,
      'adminNote': adminNote,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }
}
