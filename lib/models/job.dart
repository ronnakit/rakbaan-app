/// The 5-step job lifecycle shown in the tracking stepper
/// (rakbaan_md/02-app-features-ui.md Screen 04).
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
  });

  final String id;
  final String label; // e.g. "บ้านหลัก", "คอนโด"
  final String fullAddress;
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
        technician: technician ?? this.technician,
        description: description,
        warrantyDaysLeft: warrantyDaysLeft,
      );
}
