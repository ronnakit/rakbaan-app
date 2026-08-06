import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design_tokens.dart';
import '../models/job.dart';
import '../providers/job_provider.dart';

/// Screens 04-05: live 5-step stepper for the active job (with a "จำลอง"
/// button standing in for the Firestore realtime listener that will drive
/// this for real -- see rakbaan_md/07-technical-requirements.md §1.3) plus
/// job history with warranty countdown.
class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobProvider>();
    final activeJob = jobs.activeJob;

    return Scaffold(
      appBar: AppBar(title: const Text('ติดตามงาน')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          if (activeJob != null) ...[
            _JobHeader(job: activeJob),
            const SizedBox(height: AppSpacing.s4),
            _StatusStepper(currentStatus: activeJob.status),
            const SizedBox(height: AppSpacing.s4),
            if (activeJob.technician != null)
              _TechnicianCard(technician: activeJob.technician!),
            const SizedBox(height: AppSpacing.s4),
            _EscrowHeldCard(amount: activeJob.escrowAmount),
            const SizedBox(height: AppSpacing.s3),
            if (activeJob.status != JobStatus.completed)
              OutlinedButton(
                onPressed: () => context.read<JobProvider>().advanceActiveJobStatus(),
                child: const Text('จำลอง: อัปเดตสถานะถัดไป'),
              ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s8),
              child: Center(child: Text('ยังไม่มีงานที่กำลังดำเนินการ')),
            ),
          const SizedBox(height: AppSpacing.s8),
          Text('ประวัติงาน', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.s3),
          for (final job in jobs.history) _HistoryTile(job: job),
        ],
      ),
    );
  }
}

class _JobHeader extends StatelessWidget {
  const _JobHeader({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('${job.jobNumber} · ${job.category.name}',
              style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.currentStatus});

  final JobStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    final steps = JobStatus.values;
    final currentIndex = steps.indexOf(currentStatus);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _StepRow(
              label: steps[i].label,
              done: i <= currentIndex,
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.done, required this.isLast});

  final String label;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.mint500 : AppColors.gray300;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(done ? Icons.check_circle : Icons.circle_outlined, color: color, size: 20),
            if (!isLast) Container(width: 2, height: 24, color: color),
          ],
        ),
        const SizedBox(width: AppSpacing.s3),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s3),
          child: Text(
            label,
            style: TextStyle(
              color: done ? AppColors.gray900 : AppColors.gray600,
              fontWeight: done ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({required this.technician});

  final Technician technician;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: AppColors.navy100, child: Icon(Icons.person)),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(technician.name, style: Theme.of(context).textTheme.titleMedium),
                    if (technician.isVerified) ...[
                      const SizedBox(width: AppSpacing.s1),
                      const Icon(Icons.verified, color: AppColors.gold600, size: 16),
                    ],
                  ],
                ),
                Text('★ ${technician.rating} · ${technician.completedJobs} งาน',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.call, color: AppColors.navy700)),
        ],
      ),
    );
  }
}

class _EscrowHeldCard extends StatelessWidget {
  const _EscrowHeldCard({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.mint100,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('ยอดเงินที่พักไว้ในระบบ', style: TextStyle(color: AppColors.mint700)),
          Text('$amount฿',
              style: const TextStyle(color: AppColors.mint700, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final warrantyDays = job.warrantyDaysLeft;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s2),
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${job.category.icon} ${job.category.name}',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(job.jobNumber, style: Theme.of(context).textTheme.bodySmall),
                if (warrantyDays != null)
                  Text(
                    'ประกันคงเหลือ $warrantyDays วัน',
                    style: TextStyle(
                      color: warrantyDays <= 7 ? AppColors.warning600 : AppColors.gray600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          OutlinedButton(onPressed: () {}, child: const Text('เรียกช่างคนเดิม')),
        ],
      ),
    );
  }
}
