/// Who submitted a given [Review] document -- see
/// rakbaan_md/12-database-structure-front-end.md §2.8 (v2.1, 2026-08-12).
/// A single job can have up to 2 review docs, one per direction.
enum RaterRole { customer, technician }

extension RaterRoleFirestore on RaterRole {
  String toFirestoreValue() => name;

  static RaterRole fromFirestoreValue(String value) =>
      value == 'technician' ? RaterRole.technician : RaterRole.customer;
}

/// A single rating+comment from one party about the other after a job.
///
/// [reviewId] always follows the `{jobId}_{raterRole}` pattern (e.g.
/// `job-24071_customer`) -- this is what lets firestore.rules block a
/// second review in the same direction for the same job without an extra
/// query (see the rules comment for `/reviews/{reviewId}`).
class Review {
  const Review({
    required this.reviewId,
    required this.jobId,
    required this.customerId,
    required this.technicianId,
    required this.raterRole,
    required this.rating,
    this.tags = const [],
    this.comment = '',
    required this.createdAt,
  });

  final String reviewId;
  final String jobId;
  final String customerId;
  final String technicianId;

  /// Who this review is *from*. The other party is who it's *about*.
  final RaterRole raterRole;

  /// 1-5 stars.
  final int rating;
  final List<String> tags;
  final String comment;
  final DateTime createdAt;

  static String reviewIdFor(String jobId, RaterRole raterRole) =>
      '${jobId}_${raterRole.toFirestoreValue()}';
}

/// Tag suggestions shown in the UI -- differ by [RaterRole] even though
/// they're stored as plain strings in [Review.tags] either way.
class ReviewTags {
  ReviewTags._();

  static const List<String> forTechnician = [
    'ตรงต่อเวลา',
    'งานเรียบร้อย',
    'สุภาพ',
    'อธิบายเข้าใจง่าย',
  ];

  static const List<String> forCustomer = [
    'ให้ความร่วมมือดี',
    'จ่ายตรงเวลา',
    'สื่อสารสุภาพ',
    'พื้นที่ทำงานสะดวก',
  ];
}
