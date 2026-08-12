/// Billing milestone for a construction/renovation job
/// (`jobs/{jobId}/milestones/{milestoneId}` --
/// rakbaan_md/12-database-structure-front-end.md §2.14). Repair jobs never
/// have these; only [Job.jobType] == `construction` jobs use them.
enum MilestoneStatus { pending, inProgress, completed, approved, paid }

extension MilestoneStatusLabel on MilestoneStatus {
  String get label => switch (this) {
        MilestoneStatus.pending => 'รอดำเนินการ',
        MilestoneStatus.inProgress => 'กำลังดำเนินการ',
        MilestoneStatus.completed => 'ช่างแจ้งเสร็จแล้ว',
        MilestoneStatus.approved => 'ยืนยันรับงวดแล้ว',
        MilestoneStatus.paid => 'ปลดล็อกเงินแล้ว',
      };

  /// Counted as "done" for progress-bar purposes -- mirrors the
  /// `doneStatuses` list in rakbaan_ops/src/main.js's resolveMilestoneProgress,
  /// keep both in sync.
  bool get isDone => this == MilestoneStatus.completed || this == MilestoneStatus.approved || this == MilestoneStatus.paid;
}

extension MilestoneStatusFirestore on MilestoneStatus {
  String toFirestoreValue() => switch (this) {
        MilestoneStatus.pending => 'pending',
        MilestoneStatus.inProgress => 'in_progress',
        MilestoneStatus.completed => 'completed',
        MilestoneStatus.approved => 'approved',
        MilestoneStatus.paid => 'paid',
      };

  static MilestoneStatus fromFirestoreValue(String value) => switch (value) {
        'in_progress' => MilestoneStatus.inProgress,
        'completed' => MilestoneStatus.completed,
        'approved' => MilestoneStatus.approved,
        'paid' => MilestoneStatus.paid,
        _ => MilestoneStatus.pending,
      };
}

class Milestone {
  const Milestone({
    required this.id,
    required this.sequence,
    required this.title,
    required this.amount,
    required this.status,
    this.description = '',
    this.dueDate,
  });

  final String id;
  final int sequence;
  final String title;
  final String description;
  final int amount;
  final MilestoneStatus status;
  final DateTime? dueDate;
}
