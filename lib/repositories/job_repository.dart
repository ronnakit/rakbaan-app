import '../models/job.dart';

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
  List<ServiceCategory> getCategories();

  List<ServiceAddress> getAddresses();

  Job? getActiveJob();

  List<Job> getJobHistory();

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

  /// Fires whenever cached data changes out-of-band (e.g. a Firestore
  /// snapshot listener), so [JobProvider] knows to rebuild. Implementations
  /// with no such out-of-band source (like [MockJobRepository]) never need
  /// to emit on this.
  Stream<void> get changes;

  /// Releases any stream subscriptions/listeners. Call from
  /// `JobProvider.dispose()`.
  void dispose();
}
