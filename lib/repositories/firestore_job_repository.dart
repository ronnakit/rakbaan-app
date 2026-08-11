import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/job.dart';
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

  Job? _activeJob;
  List<Job> _history = [];
  List<ServiceAddress> _addresses = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _jobsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _addressesSub;
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

  @override
  List<ServiceCategory> getCategories() => HomeRepairCategories.all;

  @override
  List<ServiceAddress> getAddresses() => _addresses;

  @override
  Job? getActiveJob() => _activeJob;

  @override
  List<Job> getJobHistory() => List.unmodifiable(_history);

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
    _changesController.close();
  }
}
