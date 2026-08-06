import 'package:flutter/foundation.dart';

import '../models/job.dart';
import '../repositories/job_repository.dart';

/// Thin ChangeNotifier wrapper around JobRepository -- same shape as
/// ChatProvider, so screens use the same Provider pattern everywhere.
class JobProvider extends ChangeNotifier {
  JobProvider({required JobRepository repository}) : _repository = repository;

  final JobRepository _repository;

  List<ServiceCategory> get categories => _repository.getCategories();

  List<ServiceAddress> get addresses => _repository.getAddresses();

  Job? get activeJob => _repository.getActiveJob();

  List<Job> get history => _repository.getJobHistory();

  Job createJob({
    required ServiceCategory category,
    required ServiceAddress address,
    required String description,
  }) {
    final job = _repository.createJob(
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
}
