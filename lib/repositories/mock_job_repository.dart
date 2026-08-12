import '../models/job.dart';
import '../models/milestone.dart';
import '../models/review.dart';
import 'job_repository.dart';

/// In-memory fake data matching the demo content in
/// rakbaan_md/02-app-features-ui.md so the prototype screens look like the
/// mockups without touching a real backend yet.
class MockJobRepository implements JobRepository {
  @override
  String get currentUserId => 'mock-customer';

  static const _categories = HomeRepairCategories.all;

  final List<ServiceAddress> _addresses = [
    const ServiceAddress(
      id: 'home',
      label: 'บ้านหลัก',
      fullAddress: '99/1 ถ.นิมมานเหมินท์ ต.สุเทพ อ.เมือง เชียงใหม่',
      isDefault: true,
    ),
    const ServiceAddress(
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

  // _activeJob/_history reference _addresses[n] -- since _addresses is now a
  // mutable instance field (was `static const`, before addAddress() needed
  // it writable), that reference can't happen in a field initializer
  // (Dart forbids `this` in initializers) -- built in the constructor body
  // below instead.
  late Job _activeJob;
  final List<Job> _history = [];

  MockJobRepository() {
    _activeJob = Job(
      id: 'job-24071',
      jobNumber: '#RB-24071',
      category: _categories[0], // electrical
      address: _addresses[0],
      status: JobStatus.enRoute,
      priceMin: 1150,
      priceMax: 1700,
      escrowAmount: 1450,
      technician: _technician,
      description: 'ปลั๊กไฟห้องนั่งเล่นไม่มีไฟ สงสัยเบรกเกอร์ตัด',
    );
    _history.addAll([
      Job(
        id: 'job-23980',
        jobNumber: '#RB-23980',
        category: _categories[1], // plumbing
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
        category: _categories[2], // air_con
        address: _addresses[1],
        status: JobStatus.completed,
        priceMin: 1200,
        priceMax: 1200,
        escrowAmount: 0,
        technician: _technician,
        description: 'ล้างแอร์ประจำปี',
        warrantyDaysLeft: 3,
      ),
    ]);
  }

  @override
  List<ServiceCategory> getCategories() => _categories;

  @override
  List<ServiceAddress> getAddresses() => List.unmodifiable(_addresses);

  int _addressSeq = 0;

  @override
  Future<ServiceAddress> addAddress({
    required String label,
    required String recipientName,
    required String phone,
    required String addressDetail,
    double? lat,
    double? lng,
    bool isDefault = false,
  }) async {
    final address = ServiceAddress(
      id: 'mock-addr-${_addressSeq++}',
      label: label,
      fullAddress: addressDetail,
      recipientName: recipientName,
      phone: phone,
      lat: lat,
      lng: lng,
      isDefault: isDefault,
    );
    _addresses.add(address);
    return address;
  }

  @override
  Future<void> updateAddress(ServiceAddress address) async {
    final index = _addresses.indexWhere((a) => a.id == address.id);
    if (index != -1) _addresses[index] = address;
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    _addresses.removeWhere((a) => a.id == addressId);
  }

  @override
  Job? getActiveJob() => _activeJob;

  @override
  List<Job> getJobHistory() => List.unmodifiable(_history);

  // Only shown when someone points _activeJob at a JobType.construction job
  // (not the default demo scenario -- see JobRepository.getMilestones doc
  // comment) so this stays empty for the repair-job demo without extra code.
  static const _milestones = [
    Milestone(id: 'm1', sequence: 1, title: 'งวด 1: รื้อถอน', amount: 20000, status: MilestoneStatus.paid),
    Milestone(id: 'm2', sequence: 2, title: 'งวด 2: เดินระบบ', amount: 30000, status: MilestoneStatus.approved),
    Milestone(id: 'm3', sequence: 3, title: 'งวด 3: ปิดผิว', amount: 25000, status: MilestoneStatus.pending),
  ];

  @override
  List<Milestone> getMilestones() =>
      _activeJob.jobType == JobType.construction ? _milestones : const [];

  @override
  Future<Job> createJob({
    required ServiceCategory category,
    required ServiceAddress address,
    required String description,
  }) async {
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

  final Set<String> _submittedReviewIds = {};

  @override
  Future<void> submitReview({
    required String jobId,
    required String customerId,
    required String technicianId,
    required RaterRole raterRole,
    required int rating,
    List<String> tags = const [],
    String comment = '',
  }) async {
    final reviewId = Review.reviewIdFor(jobId, raterRole);
    // Mirrors the firestore.rules behavior: a second submission for the same
    // job+direction is rejected, not silently overwritten.
    if (!_submittedReviewIds.add(reviewId)) {
      throw StateError('Review $reviewId already submitted');
    }
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

  // Mock data only ever changes through the direct calls above, which the
  // UI already awaits synchronously -- nothing to emit here.
  @override
  Stream<void> get changes => const Stream.empty();

  @override
  void dispose() {}
}
