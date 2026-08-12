import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design_tokens.dart';
import '../models/job.dart';
import '../models/review.dart';
import '../providers/job_provider.dart';

/// Customer -> technician rating, shown from a completed job's history
/// tile. The technician -> customer direction uses the same
/// [RaterRole.technician] path in the repository already, but has no
/// screen yet -- see [JobRepository.submitReview]'s doc comment on scope.
Future<void> showReviewSheet(BuildContext context, Job job) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ReviewSheet(job: job),
  );
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.job});

  final Job job;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 0;
  final Set<String> _selectedTags = {};
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final technician = widget.job.technician;
    if (_rating == 0 || technician == null) return;

    setState(() => _submitting = true);
    final jobs = context.read<JobProvider>();
    try {
      await jobs.submitReview(
        jobId: widget.job.id,
        customerId: jobs.currentUserId,
        technicianId: technician.id,
        raterRole: RaterRole.customer,
        rating: _rating,
        tags: _selectedTags.toList(),
        comment: _commentController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ขอบคุณสำหรับคะแนนค่ะ')),
        );
      }
    } catch (_) {
      // Most likely cause: this direction was already submitted for this
      // job -- firestore.rules rejects the resubmission (see
      // JobRepository.submitReview's doc comment). Could also be a network
      // error; either way there's nothing UI-actionable to distinguish here.
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งคะแนนไม่สำเร็จ (อาจเคยให้คะแนนงานนี้ไปแล้ว)')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.s4,
        right: AppSpacing.s4,
        top: AppSpacing.s4,
        bottom: AppSpacing.s4 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ให้คะแนนงาน ${widget.job.jobNumber}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating ? Icons.star : Icons.star_border,
                    color: AppColors.gold500,
                    size: 32,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              for (final tag in ReviewTags.forTechnician)
                FilterChip(
                  label: Text(tag),
                  selected: _selectedTags.contains(tag),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'บอกเราเพิ่มเติมได้ (ไม่บังคับ)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _rating == 0 || _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ส่งคะแนน'),
            ),
          ),
        ],
      ),
    );
  }
}
