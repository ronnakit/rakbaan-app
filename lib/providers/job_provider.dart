import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/job.dart';
import '../models/milestone.dart';
import '../models/review.dart';
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

  String get currentUserId => _repository.currentUserId;

  List<ServiceCategory> get categories => _repository.getCategories();

  List<ServiceAddress> get addresses => _repository.getAddresses();

  Job? get activeJob => _repository.getActiveJob();

  List<Job> get history => _repository.getJobHistory();

  List<Milestone> get milestones => _repository.getMilestones();

  Future<ServiceAddress> addAddress({
    required String label,
    required String recipientName,
    required String phone,
    required String addressDetail,
    double? lat,
    double? lng,
    bool isDefault = false,
  }) async {
    final address = await _repository.addAddress(
      label: label,
      recipientName: recipientName,
      phone: phone,
      addressDetail: addressDetail,
      lat: lat,
      lng: lng,
      isDefault: isDefault,
    );
    notifyListeners();
    return address;
  }

  Future<void> updateAddress(ServiceAddress address) async {
    await _repository.updateAddress(address);
    notifyListeners();
  }

  Future<void> deleteAddress(String addressId) async {
    await _repository.deleteAddress(addressId);
    notifyListeners();
  }

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

  /// Only the customer direction (`RaterRole.customer`) has a screen that
  /// calls this today -- see [JobRepository.submitReview]'s doc comment.
  Future<void> submitReview({
    required String jobId,
    required String customerId,
    required String technicianId,
    required RaterRole raterRole,
    required int rating,
    List<String> tags = const [],
    String comment = '',
  }) async {
    await _repository.submitReview(
      jobId: jobId,
      customerId: customerId,
      technicianId: technicianId,
      raterRole: raterRole,
      rating: rating,
      tags: tags,
      comment: comment,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _changesSubscription.cancel();
    _repository.dispose();
    super.dispose();
  }
}
