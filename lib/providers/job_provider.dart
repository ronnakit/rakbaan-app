import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/job.dart';
import '../repositories/job_repository.dart';

/// Thin ChangeNotifier wrapper around JobRepository -- same shape as
/// ChatProvider, so screens use the same Provider pattern everywhere.
class JobProvider extends ChangeNotifier {
  JobProvider({required JobRepository repository}) : _repository = repository {
    // Forwards out-of-band updates (e.g. a Firestore snapshot listener
    // firing inside FirestoreJobRepository) into this provider's own
    // notifyListeners() -- see the `changes` doc comment on JobRepository.
    _changesSubscription = _repository.changes.listen((_) => notifyListeners());
  }

  final JobRepository _repository;
  late final StreamSubscription<void> _changesSubscription;

  List<ServiceCategory> get categories => _repository.getCategories();

  List<ServiceAddress> get addresses => _repository.getAddresses();

  Job? get activeJob => _repository.getActiveJob();

  List<Job> get history => _repository.getJobHistory();

  Future<Job> createJob({
    required ServiceCategory category,
    required ServiceAddress address,
    required String description,
  }) async {
    final job = await _repository.createJob(
      category: category,
      address: address,
      description: description,
    );
    notifyListeners();
    return job;
  }

  void advanceActiveJobStatus() {
    _repository.advanceActiveJobStatus();
    notifyListeners();
  }

  @override
  void dispose() {
    _changesSubscription.cancel();
    _repository.dispose();
    super.dispose();
  }
}
