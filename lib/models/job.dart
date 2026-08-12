/// The 5-step job lifecycle shown in the tracking stepper
/// (rakbaan_md/02-app-features-ui.md Screen 04).
///
/// Values map to `jobs.status` in rakbaan_md/12-database-structure-front-end.md
/// §2.3, which uses different string spellings -- see [JobStatusFirestore].
enum JobStatus { received, assigned, enRoute, inProgress, completed }

extension JobStatusLabel on JobStatus {
  String get label => switch (this) {
        JobStatus.received => 'รับเรื่องแล้ว',
        JobStatus.assigned => 'มอบหมายทีมช่าง',
        JobStatus.enRoute => 'กำลังเดินทาง',
        JobStatus.inProgress => 'กำลังซ่อม',
        JobStatus.completed => 'เสร็จสิ้น',
      };
}

/// Converts between the app's [JobStatus] enum and the `jobs.status` string
/// values documented in rakbaan_md/12-database-structure-front-end.md §2.3
/// (`pending_review`, `assigned`, `traveling`, `in_progress`, `completed`).
extension JobStatusFirestore on JobStatus {
  String toFirestoreValue() => switch (this) {
        JobStatus.received => 'pending_review',
        JobStatus.assigned => 'assigned',
        JobStatus.enRoute => 'traveling',
        JobStatus.inProgress => 'in_progress',
        JobStatus.completed => 'completed',
      };

  static JobStatus fromFirestoreValue(String value) => switch (value) {
        'pending_review' => JobStatus.received,
        'assigned' => JobStatus.assigned,
        'traveling' => JobStatus.enRoute,
        'in_progress' => JobStatus.inProgress,
        'completed' => JobStatus.completed,
        _ => throw ArgumentError('Unknown jobs.status value: $value'),
      };
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.isEmergency = false,
  });

  final String id;
  final String name;
  final String icon; // emoji placeholder until real icon set exists
  final bool isEmergency;
}

/// The 9-value `jobs.category` enum documented in
/// rakbaan_md/12-database-structure-front-end.md §2.3 (kept in sync with
/// rakbaan_md/13-mali-scenario-framework.md's taxonomy) -- both
/// [MockJobRepository] and the real Firestore-backed repository must use
/// exactly these ids, since they get written straight into `jobs.category`.
class HomeRepairCategories {
  HomeRepairCategories._();

  static const List<ServiceCategory> all = [
    ServiceCategory(id: 'electrical', name: 'ไฟฟ้า', icon: '⚡'),
    ServiceCategory(id: 'plumbing', name: 'ประปา', icon: '🚰'),
    ServiceCategory(id: 'air_con', name: 'แอร์', icon: '❄️'),
    ServiceCategory(id: 'roof_structure', name: 'หลังคา-โครงสร้าง', icon: '🏠'),
    ServiceCategory(id: 'wall_paint', name: 'ผนัง-สี', icon: '🎨'),
    ServiceCategory(id: 'floor_tile', name: 'พื้น-กระเบื้อง', icon: '🧱'),
    ServiceCategory(id: 'door_window', name: 'ประตู-หน้าต่าง', icon: '🚪'),
    ServiceCategory(id: 'appliance_ventilation', name: 'เครื่องใช้ไฟฟ้า', icon: '🔌'),
    ServiceCategory(
      id: 'emergency_safety',
      name: 'ความปลอดภัยฉุกเฉิน',
      icon: '🚨',
      isEmergency: true,
    ),
  ];
}

class Technician {
  const Technician({
    required this.id,
    required this.name,
    required this.rating,
    required this.completedJobs,
    required this.isVerified,
  });

  final String id;
  final String name;
  final double rating;
  final int completedJobs;
  final bool isVerified;
}

class ServiceAddress {
  const ServiceAddress({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.recipientName = '',
    this.phone = '',
    this.isDefault = false,
    this.lat,
    this.lng,
  });

  final String id;
  final String label; // e.g. "บ้านหลัก", "คอนโด"
  final String fullAddress;
  final String recipientName;
  final String phone;
  final bool isDefault;

  /// GPS coordinates for Zone Fee calculation
  /// (rakbaan_md/12-database-structure-front-end.md §2.2) -- null until
  /// filled via the "ใช้ตำแหน่งปัจจุบัน" button (device GPS through
  /// `geolocator`) -- no interactive map picker yet (would need Google Maps
  /// Platform API key/billing, see rakbaan_md/07-technical-requirements.md §1.3).
  final double? lat;
  final double? lng;
}

/// `jobs.jobType` (rakbaan_md/12-database-structure-front-end.md §2.3,
/// added 2026-08-11) -- drives the Retention Schedule grace period (90 days
/// repair / 365 days construction, see §1.5.5). Every job defaults to
/// [repair]; nothing in the UI lets a customer pick [construction] yet, so
/// that path is only reachable by writing it directly in Firestore/ops-portal
/// for now.
enum JobType { repair, construction }

extension JobTypeFirestore on JobType {
  String toFirestoreValue() => name;

  static JobType fromFirestoreValue(String value) => switch (value) {
        'construction' => JobType.construction,
        _ => JobType.repair,
      };
}

class Job {
  const Job({
    required this.id,
    required this.jobNumber,
    required this.category,
    required this.address,
    required this.status,
    required this.priceMin,
    required this.priceMax,
    required this.escrowAmount,
    this.jobType = JobType.repair,
    this.technician,
    this.description = '',
    this.warrantyDaysLeft,
  });

  final String id;
  final String jobNumber; // e.g. "#RB-24071"
  final ServiceCategory category;
  final ServiceAddress address;
  final JobStatus status;
  final int priceMin;
  final int priceMax;
  final int escrowAmount;
  final JobType jobType;
  final Technician? technician;
  final String description;
  final int? warrantyDaysLeft;

  Job copyWith({JobStatus? status, Technician? technician}) => Job(
        id: id,
        jobNumber: jobNumber,
        category: category,
        address: address,
        status: status ?? this.status,
        priceMin: priceMin,
        priceMax: priceMax,
        escrowAmount: escrowAmount,
        jobType: jobType,
        technician: technician ?? this.technician,
        description: description,
        warrantyDaysLeft: warrantyDaysLeft,
      );
}
