import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/design_tokens.dart';
import '../models/job.dart';
import '../providers/job_provider.dart';

/// Screen 02 (ขั้น 1/4): pick a service category, with the emergency
/// shortcut called out in red per rakbaan_md/02-app-features-ui.md.
class ReportJobScreen extends StatelessWidget {
  const ReportJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<JobProvider>().categories;
    final normal = categories.where((c) => !c.isEmergency).toList();
    final emergency = categories.where((c) => c.isEmergency).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งซ่อม · ขั้น 1/4')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('เลือกหมวดงาน', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.s4),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: AppSpacing.s3,
              crossAxisSpacing: AppSpacing.s3,
              children: [
                for (final category in normal)
                  _CategoryTile(
                    category: category,
                    onTap: () => context.push('/report/details', extra: category),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s6),
            if (emergency.isNotEmpty)
              _EmergencyButton(
                category: emergency.first,
                onTap: () => context.push('/report/details', extra: emergency.first),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final ServiceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: AppSpacing.s2),
            Text(category.name, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.category, required this.onTap});

  final ServiceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          color: AppColors.error100,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.error600, width: 1.5),
        ),
        child: Row(
          children: [
            const Text('🚨', style: TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  color: AppColors.error600,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.error600),
          ],
        ),
      ),
    );
  }
}
