import '../models/job.dart';

/// Data-access boundary for jobs/categories/addresses/history.
///
/// UI screens depend on this interface only, never on a concrete backend.
/// MockJobRepository (in-memory fake data) implements it for the UI
/// prototype phase; a FirebaseJobRepository can implement the same
/// interface later without any screen changing (see
/// rakbaan_md/07-technical-requirements.md §2.2 for the intended schema).
abstract class JobRepository {
  List<ServiceCategory> getCategories();

  List<ServiceAddress> getAddresses();

  Job? getActiveJob();

  List<Job> getJobHistory();

  Job createJob({
    required ServiceCategory category,
    required ServiceAddress address,
    required String description,
  });

  /// Advances the active job to the next step in [JobStatus] -- stands in
  /// for what would be a Firestore realtime listener update in production.
  Job advanceActiveJobStatus();
}
