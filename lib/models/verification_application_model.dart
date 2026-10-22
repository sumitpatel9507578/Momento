class VerificationApplicationModel {
  final String id;
  final String userId;
  final String userName;
  final String userHandle;
  final String userAvatar;
  final String userEmail;
  final String legalName;
  final String displayName;
  final String category;
  final String country;
  final String reason;
  final String websiteUrl;
  final String documentType;
  final String documentUrl;
  final String status; // draft, submitted, under_review, additional_info_required, approved, rejected, revoked
  final String adminNote;
  final DateTime submittedAt;
  final DateTime updatedAt;

  VerificationApplicationModel({
    required this.id,
    required this.userId,
    this.userName = '',
    this.userHandle = '',
    this.userAvatar = '',
    this.userEmail = '',
    required this.legalName,
    required this.displayName,
    required this.category,
    required this.country,
    required this.reason,
    this.websiteUrl = '',
    required this.documentType,
    required this.documentUrl,
    required this.status,
    this.adminNote = '',
    required this.submittedAt,
    required this.updatedAt,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'submitted' || status == 'under_review';
  bool get isDraft => status == 'draft';
  bool get isNeedsInfo => status == 'additional_info_required';
  bool get isRejected => status == 'rejected';
  bool get isRevoked => status == 'revoked';

  factory VerificationApplicationModel.fromMap(Map<String, dynamic> map) {
    return VerificationApplicationModel(
      id: (map['id'] ?? map['application_id'] ?? '').toString(),
      userId: (map['userId'] ?? map['user_id'] ?? '').toString(),
      userName: map['userName'] ?? map['full_name'] ?? map['name'] ?? '',
      userHandle: map['userHandle'] ?? map['username'] ?? '',
      userAvatar: map['userAvatar'] ?? map['profile_image'] ?? map['profileImage'] ?? '',
      userEmail: map['userEmail'] ?? map['email'] ?? '',
      legalName: map['legalName'] ?? map['legal_name'] ?? '',
      displayName: map['displayName'] ?? map['display_name'] ?? '',
      category: map['category'] ?? 'Creator',
      country: map['country'] ?? '',
      reason: map['reason'] ?? '',
      websiteUrl: map['websiteUrl'] ?? map['website_url'] ?? '',
      documentType: map['documentType'] ?? map['document_type'] ?? 'Govt ID',
      documentUrl: map['documentUrl'] ?? map['document_url'] ?? '',
      status: map['status'] ?? 'submitted',
      adminNote: map['adminNote'] ?? map['admin_note'] ?? '',
      submittedAt: _parseDate(map['submittedAt'] ?? map['created_at']),
      updatedAt: _parseDate(map['updatedAt'] ?? map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userHandle': userHandle,
      'userAvatar': userAvatar,
      'userEmail': userEmail,
      'legalName': legalName,
      'displayName': displayName,
      'category': category,
      'country': country,
      'reason': reason,
      'websiteUrl': websiteUrl,
      'documentType': documentType,
      'documentUrl': documentUrl,
      'status': status,
      'adminNote': adminNote,
      'submittedAt': submittedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }
}
