import '../models/job.dart';
import 'job_repository.dart';

/// In-memory fake data matching the demo content in
/// rakbaan_md/02-app-features-ui.md so the prototype screens look like the
/// mockups without touching a real backend yet.
class MockJobRepository implements JobRepository {
  static const _categories = [
    ServiceCategory(id: 'plumbing', name: 'ประปา', icon: '🚰'),
    ServiceCategory(id: 'electrical', name: 'ไฟฟ้า', icon: '⚡'),
    ServiceCategory(id: 'aircon', name: 'แอร์', icon: '❄️'),
    ServiceCategory(id: 'structure', name: 'โครงสร้าง', icon: '🧱'),
    ServiceCategory(id: 'other', name: 'อื่นๆ', icon: '🔧'),
    ServiceCategory(
      id: 'emergency',
      name: 'งานฉุกเฉิน 24 ชม.',
      icon: '🚨',
      isEmergency: true,
    ),
  ];

  static const _addresses = [
    ServiceAddress(
      id: 'home',
      label: 'บ้านหลัก',
      fullAddress: '99/1 ถ.นิมมานเหมินท์ ต.สุเทพ อ.เมือง เชียงใหม่',
    ),
    ServiceAddress(
      id: 'condo',
      label: 'คอนโด',
      fullAddress: 'ดิ แอสตร้า คอนโด ห้อง 12B ถ.ห้วยแก้ว เชียงใหม่',
    ),
  ];

  static const _technician = Technician(
    id: 'tech-01',
    name: 'ทีมช่างสมชาย',
    rating: 4.9,
    completedJobs: 214,
    isVerified: true,
  );

  Job _activeJob = Job(
    id: 'job-24071',
    jobNumber: '#RB-24071',
    category: _categories[1],
    address: _addresses[0],
    status: JobStatus.enRoute,
    priceMin: 1150,
    priceMax: 1700,
    escrowAmount: 1450,
    technician: _technician,
    description: 'ปลั๊กไฟห้องนั่งเล่นไม่มีไฟ สงสัยเบรกเกอร์ตัด',
  );

  final List<Job> _history = [
    Job(
      id: 'job-23980',
      jobNumber: '#RB-23980',
      category: _categories[0],
      address: _addresses[0],
      status: JobStatus.completed,
      priceMin: 800,
      priceMax: 800,
      escrowAmount: 0,
      technician: _technician,
      description: 'ก๊อกน้ำห้องครัวรั่ว',
      warrantyDaysLeft: 45,
    ),
    Job(
      id: 'job-23711',
      jobNumber: '#RB-23711',
      category: _categories[2],
      address: _addresses[1],
      status: JobStatus.completed,
      priceMin: 1200,
      priceMax: 1200,
      escrowAmount: 0,
      technician: _technician,
      description: 'ล้างแอร์ประจำปี',
      warrantyDaysLeft: 3,
    ),
  ];

  @override
  List<ServiceCategory> getCategories() => _categories;

  @override
  List<ServiceAddress> getAddresses() => _addresses;

  @override
  Job? getActiveJob() => _activeJob;

  @override
  List<Job> getJobHistory() => List.unmodifiable(_history);

  @override
  Job createJob({
    required ServiceCategory category,
    required ServiceAddress address,
    required String description,
  }) {
    _activeJob = Job(
      id: 'job-${DateTime.now().millisecondsSinceEpoch}',
      jobNumber: '#RB-${10000 + _history.length}',
      category: category,
      address: address,
      status: JobStatus.received,
      priceMin: 300,
      priceMax: 900,
      escrowAmount: 0,
      description: description,
    );
    return _activeJob;
  }

  @override
  Job advanceActiveJobStatus() {
    final steps = JobStatus.values;
    final currentIndex = steps.indexOf(_activeJob.status);
    if (currentIndex >= steps.length - 1) return _activeJob;
    final next = steps[currentIndex + 1];
    _activeJob = _activeJob.copyWith(
      status: next,
      technician: _activeJob.technician ?? _technician,
    );
    return _activeJob;
  }
}
