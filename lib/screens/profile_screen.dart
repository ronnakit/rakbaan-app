import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/design_tokens.dart';
import '../providers/job_provider.dart';
import '../providers/text_scale_provider.dart';

/// Screen 07: addresses, payment methods, PIN/biometric entry point, and the
/// A+/A- text-size control required by rakbaan_md/01-brand-identity.md §5/§11.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final addresses = context.watch<JobProvider>().addresses;

    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          const _ProfileHeader(),
          const SizedBox(height: AppSpacing.s6),
          _SectionLabel('ที่อยู่ของฉัน'),
          for (final address in addresses)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: ListTile(
                tileColor: AppColors.pureWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                leading: const Icon(Icons.home_outlined, color: AppColors.navy700),
                title: Row(
                  children: [
                    Text(address.label),
                    if (address.isDefault) ...[
                      const SizedBox(width: AppSpacing.s2),
                      const Text('· หลัก', style: TextStyle(color: AppColors.mint700, fontSize: 12)),
                    ],
                  ],
                ),
                subtitle: Text(address.fullAddress),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/address/edit', extra: address),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => context.push('/address/new'),
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มที่อยู่ใหม่'),
          ),
          const SizedBox(height: AppSpacing.s6),
          _SectionLabel('วิธีการชำระเงิน'),
          const ListTile(
            tileColor: AppColors.pureWhite,
            leading: Icon(Icons.qr_code, color: AppColors.navy700),
            title: Text('พร้อมเพย์'),
          ),
          const SizedBox(height: AppSpacing.s6),
          _SectionLabel('ความปลอดภัย'),
          const ListTile(
            tileColor: AppColors.pureWhite,
            leading: Icon(Icons.pin_outlined, color: AppColors.navy700),
            title: Text('PIN และไบโอเมตริก'),
            trailing: Icon(Icons.chevron_right),
          ),
          const SizedBox(height: AppSpacing.s6),
          _SectionLabel('ขนาดตัวอักษร'),
          const _TextSizeControl(),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(radius: 28, backgroundColor: AppColors.navy100, child: Icon(Icons.person, size: 28)),
        SizedBox(width: AppSpacing.s3),
        Text('คุณนิดา', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.gray600)),
    );
  }
}

class _TextSizeControl extends StatelessWidget {
  const _TextSizeControl();

  @override
  Widget build(BuildContext context) {
    final textScale = context.watch<TextScaleProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('A', style: TextStyle(fontSize: 14)),
          IconButton(
            onPressed: textScale.decrease,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('${(textScale.scale * 100).round()}%'),
          IconButton(
            onPressed: textScale.increase,
            icon: const Icon(Icons.add_circle_outline),
          ),
          const Text('A', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }
}
