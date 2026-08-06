import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/design_tokens.dart';
import '../providers/job_provider.dart';
import 'report_job_details_screen.dart';

/// Screen 03 (ขั้น 4/4): price estimate + the mint Escrow explainer banner +
/// payment method, matching rakbaan_md/02-app-features-ui.md.
///
/// The wording here intentionally still says "เงินพักไว้ในระบบ Escrow" per
/// the note in that doc §4 -- only the backend behind it changes (Payment
/// Gateway hold & release, not a company-held account), so the customer-
/// facing copy doesn't need to change when that gets wired up for real.
class ReportJobConfirmScreen extends StatelessWidget {
  const ReportJobConfirmScreen({super.key, this.draft});

  final ReportJobDraft? draft;

  static const _inspectionFee = 300;
  static const _laborMin = 600;
  static const _laborMax = 900;
  static const _partsMin = 250;
  static const _partsMax = 500;

  @override
  Widget build(BuildContext context) {
    final totalMin = _inspectionFee + _laborMin + _partsMin;
    final totalMax = _inspectionFee + _laborMax + _partsMax;

    return Scaffold(
      appBar: AppBar(title: const Text('ตรวจสอบและยืนยัน · ขั้น 4/4')),
      body: draft == null
          ? const Center(child: Text('ไม่พบข้อมูลงาน กลับไปแจ้งซ่อมใหม่'))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.s4),
              children: [
                Text('ใบประเมินราคา', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.s3),
                _PriceRow(label: 'ค่าเข้าตรวจ', value: '$_inspectionFee฿'),
                _PriceRow(label: 'ค่าแรงประเมิน', value: '$_laborMin-$_laborMax฿'),
                _PriceRow(label: 'ค่าอะไหล่', value: '$_partsMin-$_partsMax฿'),
                const Divider(height: AppSpacing.s6),
                _PriceRow(
                  label: 'รวม',
                  value: '$totalMin-$totalMax฿',
                  emphasize: true,
                ),
                const SizedBox(height: AppSpacing.s6),
                const _EscrowBanner(),
                const SizedBox(height: AppSpacing.s6),
                Text('วิธีชำระเงิน', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.s2),
                const _PaymentMethodTile(label: 'พร้อมเพย์', icon: Icons.qr_code),
                const _PaymentMethodTile(label: 'บัตรเครดิต/เดบิต', icon: Icons.credit_card),
                const SizedBox(height: AppSpacing.s6),
                FilledButton(
                  onPressed: () {
                    context.read<JobProvider>().createJob(
                          category: draft!.category,
                          address: draft!.address,
                          description: draft!.description,
                        );
                    context.go('/tracking');
                  },
                  child: const Text('ยืนยันและล็อกคิวงาน'),
                ),
              ],
            ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

class _EscrowBanner extends StatelessWidget {
  const _EscrowBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.mint100,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.mint700),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              'เงินของคุณจะถูกพักไว้ในระบบ Escrow จนกว่างานจะเสร็จและคุณยืนยันความพึงพอใจ',
              style: TextStyle(color: AppColors.mint700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: ListTile(
        tileColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        leading: Icon(icon, color: AppColors.navy700),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
