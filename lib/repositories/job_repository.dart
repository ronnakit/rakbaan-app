import '../models/job.dart';
import '../models/milestone.dart';
import '../models/review.dart';

/// Data-access boundary for jobs/categories/addresses/history.
///
/// UI screens depend on this interface only, never on a concrete backend.
/// [MockJobRepository] (in-memory fake data) implements it for the UI
/// prototype phase; [FirestoreJobRepository] implements the same interface
/// against the real backend (rakbaan_md/12-database-structure-front-end.md)
/// without any screen changing.
///
/// All getters stay synchronous by design (screens read them directly, no
/// FutureBuilder/StreamBuilder plumbing) -- [FirestoreJobRepository] keeps a
/// local cache updated by Firestore snapshot listeners and fires [changes]
/// whenever that cache updates, which [JobProvider] forwards to its own
/// `notifyListeners()`. [MockJobRepository] never emits on [changes] since
/// its data only changes through direct method calls, which already notify
/// synchronously.
abstract class JobRepository {
  /// The signed-in user's own id -- lets screens fill in `customerId` for
  /// [submitReview] without importing `firebase_auth` directly.
  String get currentUserId;

  List<ServiceCategory> getCategories();

  List<ServiceAddress> getAddresses();

  /// Adds a new address for the current customer. Returns the created
  /// address (with its real id) so the caller can select it immediately
  /// (see `ReportJobDetailsScreen`'s "+ เพิ่มที่อยู่ใหม่" entry point).
  Future<ServiceAddress> addAddress({
    required String label,
    required String recipientName,
    required String phone,
    required String addressDetail,
    double? lat,
    double? lng,
    bool isDefault = false,
  });

  /// Overwrites an existing address's editable fields. [address.id] must
  /// already exist and belong to the current customer.
  Future<void> updateAddress(ServiceAddress address);

  /// Self-delete (recordStatus 0->3) -- matches `isSelfDeleteTransition` in
  /// firestore.rules, so only `recordStatus`/`lastActorId`/`lastActorType`
  /// get written, never a hard delete.
  Future<void> deleteAddress(String addressId);

  Job? getActiveJob();

  List<Job> getJobHistory();

  /// Billing milestones of the current active job -- only non-empty when
  /// [getActiveJob] returns a job with [JobType.construction] (see
  /// rakbaan_md/12-database-structure-front-end.md §2.14). Repair jobs never
  /// have milestones, so this stays `[]` for them. Kept keyed to "the active
  /// job" rather than taking a jobId param, mirroring [getActiveJob] itself --
  /// a customer only ever tracks one in-progress job's milestones at a time.
  List<Milestone> getMilestones();

  /// Async because a real backend write is inherently async -- callers that
  /// only ever ran against the synchronous [MockJobRepository] need an
  /// `await` added (see `ReportJobConfirmScreen`).
  Future<Job> createJob({
    required ServiceCategory category,
    required ServiceAddress address,
    required String description,
  });

  /// Advances the active job to the next step in [JobStatus] -- stands in
  /// for what would be a Firestore realtime listener update in production.
  Job advanceActiveJobStatus();

  /// Submits one direction of a review for a completed job (see
  /// rakbaan_md/12-database-structure-front-end.md §2.8). Only the
  /// customer-facing screens call this today -- [RaterRole.technician]
  /// exists in the schema/rules already but has no UI yet, since technicians
  /// don't have an app of their own (see [JobRepository]'s own doc comment
  /// on scope). Throws if this direction was already submitted for [jobId]
  /// (enforced server-side by firestore.rules, not re-checked here).
  Future<void> submitReview({
    required String jobId,
    required String customerId,
    required String technicianId,
    required RaterRole raterRole,
    required int rating,
    List<String> tags,
    String comment,
  });

  /// Fires whenever cached data changes out-of-band (e.g. a Firestore
  /// snapshot listener), so [JobProvider] knows to rebuild. Implementations
  /// with no such out-of-band source (like [MockJobRepository]) never need
  /// to emit on this.
  Stream<void> get changes;

  /// Releases any stream subscriptions/listeners. Call from
  /// `JobProvider.dispose()`.
  void dispose();
}
