import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/job.dart';
import '../models/milestone.dart';
import '../models/review.dart';
import 'job_repository.dart';

/// Real backend for [JobRepository] against the schema documented in
/// rakbaan_md/12-database-structure-front-end.md.
///
/// NOT YET ACTIVATED in main.dart (still [MockJobRepository] there) --
/// the `rakbaan-cnx` Firebase project has never had Cloud Firestore
/// enabled/provisioned, so every call this class makes would fail right
/// now. Swap it in once that's done (see the comment in main.dart) and
/// after this class itself has been exercised against the Firebase
/// Emulator at least once -- it hasn't been run yet.
///
/// Known simplifications vs. the full documented schema (fix these before
/// treating this as more than a first pass):
/// - `priceMin`/`priceMax`/`escrowAmount` are always 0 -- real pricing lives
///   in the `boq_items` sub-collection and real escrow amounts in
///   `escrow_transactions`, neither of which this class reads yet.
/// - `technician` is always null -- there's no `technicians` collection yet
///   (backend/ops-portal schema is intentionally out of scope, see
///   rakbaan_md/12-database-structure-front-end.md's own scope note).
/// - `jobNumber` is derived from the Firestore doc id, not a real
///   sequential `#RB-XXXXX` counter (that needs a transaction/Cloud
///   Function, not built).
/// - [customerId] must come from *some* signed-in Firebase Auth user --
///   anonymous auth is enough to satisfy firestore.rules, but is not a real
///   customer identity (no phone-OTP login flow exists yet).
/// - [advanceActiveJobStatus] is a deliberate no-op: firestore.rules denies
///   customers from writing `jobs.status` directly (only team/admin can),
///   so TrackingScreen's "จำลอง" demo button does nothing against this
///   repository -- that's correct, not a bug.
/// - `jobs.addressId` (added here) isn't in the documented schema's field
///   list yet -- the doc never actually said how a job points at an
///   address, which this class needs to work at all. Fold this back into
///   rakbaan_md/12-database-structure-front-end.md §2.3 next time that file
///   is touched.
class FirestoreJobRepository implements JobRepository {
  FirestoreJobRepository({
    required this.customerId,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance {
    _listenToAddresses();
    _listenToJobs();
  }

  final String customerId;
  final FirebaseFirestore _db;

  @override
  String get currentUserId => customerId;

  Job? _activeJob;
  List<Job> _history = [];
  List<ServiceAddress> _addresses = [];
  List<Milestone> _milestones = [];
  String? _milestonesJobId;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _jobsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _addressesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _milestonesSub;
  final _changesController = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changesController.stream;

  void _listenToAddresses() {
    _addressesSub = _db
        .collection('addresses')
        .where('userId', isEqualTo: customerId)
        .snapshots()
        .listen((snapshot) {
      _addresses = snapshot.docs
          .where((d) => ((d.data()['recordStatus'] as num?) ?? 0) <= 1)
          .map((d) => ServiceAddress(
                id: d.id,
                label: d.data()['label'] as String? ?? '',
                fullAddress: d.data()['addressDetail'] as String? ?? '',
                recipientName: d.data()['recipientName'] as String? ?? '',
                phone: d.data()['phone'] as String? ?? '',
                isDefault: d.data()['isDefault'] as bool? ?? false,
                lat: (d.data()['lat'] as num?)?.toDouble(),
                lng: (d.data()['lng'] as num?)?.toDouble(),
              ))
          .toList();
      _changesController.add(null);
    });
  }

  void _listenToJobs() {
    // Needs a composite index on (customerId ASC, createdAt DESC) --
    // added to firestore.indexes.json alongside this file.
    _jobsSub = _db
        .collection('jobs')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final visible = snapshot.docs.where(
        (d) => ((d.data()['recordStatus'] as num?) ?? 0) <= 1,
      );
      final jobs = visible.map(_jobFromDoc).toList();
      _activeJob = jobs.where((j) => j.status != JobStatus.completed).firstOrNull;
      _history = jobs.where((j) => j.status == JobStatus.completed).toList();
      _syncMilestonesSubscription();
      _changesController.add(null);
    });
  }

  Job _jobFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final categoryId = data['category'] as String? ?? '';
    final category = HomeRepairCategories.all
        .where((c) => c.id == categoryId)
        .firstOrNull ??
        HomeRepairCategories.all.first;

    final addressId = data['addressId'] as String?;
    final address = _addresses.where((a) => a.id == addressId).firstOrNull ??
        const ServiceAddress(id: '', label: 'ไม่ระบุที่อยู่', fullAddress: '');

    return Job(
      id: doc.id,
      // Placeholder until a real sequential job-number counter exists.
      jobNumber: '#RB-${doc.id.length >= 5 ? doc.id.substring(0, 5).toUpperCase() : doc.id.toUpperCase()}',
      category: category,
      address: address,
      status: JobStatusFirestore.fromFirestoreValue(data['status'] as String? ?? 'pending_review'),
      // Not wired yet -- see class doc comment.
      priceMin: 0,
      priceMax: 0,
      escrowAmount: 0,
      jobType: JobTypeFirestore.fromFirestoreValue(data['jobType'] as String? ?? 'repair'),
      technician: null, // no `technicians` collection yet
      description: data['title'] as String? ?? '',
    );
  }

  // Re-subscribes the milestones listener whenever the active job changes to
  // a *different* construction job (or stops being one) -- called every time
  // _listenToJobs' snapshot fires, so must no-op when the active job id is
  // unchanged to avoid tearing down and rebuilding the listener on every
  // unrelated jobs-collection update.
  void _syncMilestonesSubscription() {
    final job = _activeJob;
    final targetJobId = (job != null && job.jobType == JobType.construction) ? job.id : null;
    if (targetJobId == _milestonesJobId) return;

    _milestonesSub?.cancel();
    _milestonesJobId = targetJobId;
    _milestones = [];

    if (targetJobId == null) return;
    _milestonesSub = _db
        .collection('jobs')
        .doc(targetJobId)
        .collection('milestones')
        .orderBy('sequence')
        .snapshots()
        .listen((snapshot) {
      _milestones = snapshot.docs
          .where((d) => ((d.data()['recordStatus'] as num?) ?? 0) <= 1)
          .map(_milestoneFromDoc)
          .toList();
      _changesController.add(null);
    });
  }

  Milestone _milestoneFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final dueDate = data['dueDate'];
    return Milestone(
      id: doc.id,
      sequence: (data['sequence'] as num?)?.toInt() ?? 0,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      status: MilestoneStatusFirestore.fromFirestoreValue(data['status'] as String? ?? 'pending'),
      dueDate: dueDate is Timestamp ? dueDate.toDate() : null,
    );
  }

  @override
  List<ServiceCategory> getCategories() => HomeRepairCategories.all;

  @override
  List<ServiceAddress> getAddresses() => _addresses;

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
    final docRef = _db.collection('addresses').doc();
    await docRef.set({
      'userId': customerId,
      'label': label,
      'recipientName': recipientName,
      'phone': phone,
      'addressDetail': addressDetail,
      'lat': lat,
      'lng': lng,
      'isDefault': isDefault,
      'recordStatus': 0,
      'lastActorId': customerId,
      'lastActorType': 'customer',
    });
    return ServiceAddress(
      id: docRef.id,
      label: label,
      fullAddress: addressDetail,
      recipientName: recipientName,
      phone: phone,
      lat: lat,
      lng: lng,
      isDefault: isDefault,
    );
  }

  @override
  Future<void> updateAddress(ServiceAddress address) {
    // ไม่แก้ recordStatus เลย -- isProtectedStatusWrite() ใน firestore.rules
    // เช็คว่า recordStatus เปลี่ยนไหม การไม่ส่ง field นี้เข้า update() เท่ากับ
    // "ไม่เปลี่ยน" อยู่แล้ว ไม่ต้องอ่านค่าเดิมมาก่อน
    return _db.collection('addresses').doc(address.id).update({
      'label': address.label,
      'recipientName': address.recipientName,
      'phone': address.phone,
      'addressDetail': address.fullAddress,
      'lat': address.lat,
      'lng': address.lng,
      'isDefault': address.isDefault,
      'lastActorId': customerId,
      'lastActorType': 'customer',
    });
  }

  @override
  Future<void> deleteAddress(String addressId) {
    // self-delete (0->3) -- ต้องส่งแค่ 3 field นี้เท่านั้นให้ตรงกับ
    // isSelfDeleteTransition ใน firestore.rules เป๊ะๆ ห้ามมี field อื่นแอบมาด้วย
    return _db.collection('addresses').doc(addressId).update({
      'recordStatus': 3,
      'lastActorId': customerId,
      'lastActorType': 'customer',
    });
  }

  @override
  Job? getActiveJob() => _activeJob;

  @override
  List<Job> getJobHistory() => List.unmodifiable(_history);

  @override
  List<Milestone> getMilestones() => List.unmodifiable(_milestones);

  @override
  Future<Job> createJob({
    required ServiceCategory category,
    required ServiceAddress address,
    required String description,
  }) async {
    final docRef = _db.collection('jobs').doc();
    await docRef.set({
      'customerId': customerId,
      'customerName': '', // TODO: no profile/display-name field wired up yet
      'category': category.id,
      'jobType': JobType.repair.toFirestoreValue(),
      'title': description,
      'addressId': address.id,
      'assignedTeamId': null,
      'status': JobStatus.received.toFirestoreValue(),
      'escrowStatus': null, // ยังไม่มีธุรกรรมจนกว่าจะจ่ายเงินจริง
      'createdAt': FieldValue.serverTimestamp(),
      'recordStatus': 0,
      'lastActorId': customerId,
      'lastActorType': 'customer',
    });

    // The snapshot listener above will eventually replace this with the
    // server-confirmed copy (with a real createdAt, etc.) -- return an
    // optimistic local copy immediately so ReportJobConfirmScreen's
    // `context.go('/tracking')` right after this call has something to show
    // without waiting for a Firestore round-trip.
    final optimisticJob = Job(
      id: docRef.id,
      jobNumber: '#RB-${docRef.id.substring(0, 5).toUpperCase()}',
      category: category,
      address: address,
      status: JobStatus.received,
      priceMin: 0,
      priceMax: 0,
      escrowAmount: 0,
      description: description,
    );
    _activeJob = optimisticJob;
    _changesController.add(null);
    return optimisticJob;
  }

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
    // Deterministic doc id -- firestore.rules rejects a second write to the
    // same id in the same direction (it evaluates as `update`, not `create`,
    // and the update rule doesn't allow a plain resubmission). We still let
    // that PERMISSION_DENIED surface to the caller rather than swallowing it.
    final reviewId = Review.reviewIdFor(jobId, raterRole);
    await _db.collection('reviews').doc(reviewId).set({
      'jobId': jobId,
      'customerId': customerId,
      'technicianId': technicianId,
      'raterRole': raterRole.toFirestoreValue(),
      'rating': rating,
      'tags': tags,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
      'recordStatus': 0,
      'lastActorId': raterRole == RaterRole.customer ? customerId : technicianId,
      'lastActorType': raterRole.toFirestoreValue(),
    });
  }

  @override
  Job advanceActiveJobStatus() {
    final job = _activeJob;
    if (job == null) {
      throw StateError('FirestoreJobRepository.advanceActiveJobStatus: no active job');
    }
    // Deliberate no-op -- see class doc comment. Real status transitions are
    // staff/team-driven (ops-portal, not built) and firestore.rules denies
    // customers from writing `jobs.status` directly.
    return job;
  }

  @override
  void dispose() {
    _jobsSub?.cancel();
    _addressesSub?.cancel();
    _milestonesSub?.cancel();
    _changesController.close();
  }
}
