import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/design_tokens.dart';
import '../models/job.dart';
import '../providers/job_provider.dart';

/// Screen 01 in rakbaan_md/02-app-features-ui.md: active-job status card,
/// 3 quick actions, recent job preview, membership promo.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobProvider>();
    final activeJob = jobs.activeJob;
    final recent = jobs.history;

    return Scaffold(
      appBar: AppBar(title: const Text('รักบ้าน@CNX')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          if (activeJob != null) _ActiveJobCard(job: activeJob),
          const SizedBox(height: AppSpacing.s6),
          const _QuickActions(),
          const SizedBox(height: AppSpacing.s6),
          Text('งานล่าสุด', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.s3),
          for (final job in recent.take(2)) _RecentJobTile(job: job),
          const SizedBox(height: AppSpacing.s6),
          const _MembershipPromoCard(),
        ],
      ),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  const _ActiveJobCard({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.navy700,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(job.jobNumber,
                  style: const TextStyle(color: AppColors.navy100, fontSize: 12)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s2, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold500,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(job.status.label,
                    style: const TextStyle(
                        color: AppColors.navy900,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(job.category.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.s1),
          Text('ทีมช่างกำลังเดินทางมาที่ ${job.address.label}',
              style: const TextStyle(color: AppColors.navy100, fontSize: 13)),
          const SizedBox(height: AppSpacing.s4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.navy100),
                  ),
                  onPressed: () => context.go('/tracking'),
                  child: const Text('ติดตามช่าง'),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold500,
                    foregroundColor: AppColors.navy900,
                  ),
                  onPressed: () {},
                  child: const Text('โทรหาช่าง'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (icon: Icons.add_circle_outline, label: 'แจ้งซ่อมใหม่', route: '/report'),
      (icon: Icons.event_repeat, label: 'นัดบำรุงรักษา', route: '/report'),
      (icon: Icons.search, label: 'เช็คสถานะ', route: '/tracking'),
    ];
    return Row(
      children: [
        for (final action in actions)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () => context.go(action.route),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s4, horizontal: AppSpacing.s2),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadows.sm,
                  ),
                  child: Column(
                    children: [
                      Icon(action.icon, color: AppColors.navy700),
                      const SizedBox(height: AppSpacing.s2),
                      Text(action.label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentJobTile extends StatelessWidget {
  const _RecentJobTile({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
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
          Text(job.category.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.category.name,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(job.jobNumber,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.mint500, size: 20),
        ],
      ),
    );
  }
}

class _MembershipPromoCard extends StatelessWidget {
  const _MembershipPromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.gold100,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Text('🏡', style: TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('แพ็กเกจดูแลบ้านรายปี',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.navy900)),
                Text('ตรวจเช็คระบบบ้านฟรี 2-4 ครั้ง/ปี',
                    style: TextStyle(color: AppColors.gold600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
