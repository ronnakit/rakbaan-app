import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/design_tokens.dart';
import '../models/job.dart';
import '../providers/job_provider.dart';

/// Carries the picked category + address + description forward to the
/// confirm screen via GoRouter's `extra` param.
class ReportJobDraft {
  ReportJobDraft({required this.category, required this.address, required this.description});

  final ServiceCategory category;
  final ServiceAddress address;
  final String description;
}

/// Describe the issue, attach a photo (placeholder), and pick the address --
/// folds Screens 02's remaining steps (2-3/4) into one screen for the
/// prototype pass.
class ReportJobDetailsScreen extends StatefulWidget {
  const ReportJobDetailsScreen({super.key, this.category});

  final ServiceCategory? category;

  @override
  State<ReportJobDetailsScreen> createState() => _ReportJobDetailsScreenState();
}

class _ReportJobDetailsScreenState extends State<ReportJobDetailsScreen> {
  final _descriptionController = TextEditingController();
  ServiceAddress? _selectedAddress;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final addresses = context.watch<JobProvider>().addresses;
    _selectedAddress ??= addresses.firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งซ่อม · ขั้น 2/4')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          if (category != null)
            Text('หมวด: ${category.icon} ${category.name}',
                style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.s4),
          Text('อธิบายอาการ', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.s2),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'เช่น ปลั๊กไฟห้องนั่งเล่นไม่มีไฟ',
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('แนบรูป/วิดีโอ (ยังไม่เชื่อมกล้องจริง)'),
          ),
          const SizedBox(height: AppSpacing.s6),
          Text('เลือกที่อยู่', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.s2),
          if (addresses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s2),
              child: Text('ยังไม่มีที่อยู่ — กดเพิ่มที่อยู่ใหม่ก่อนแจ้งซ่อมได้เลย',
                  style: TextStyle(color: AppColors.gray600)),
            )
          else
            RadioGroup<ServiceAddress>(
              groupValue: _selectedAddress,
              onChanged: (value) => setState(() => _selectedAddress = value),
              child: Column(
                children: [
                  for (final address in addresses)
                    RadioListTile<ServiceAddress>(
                      value: address,
                      title: Text(address.label),
                      subtitle: Text(address.fullAddress),
                      tileColor: AppColors.pureWhite,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.s2),
          OutlinedButton.icon(
            onPressed: () async {
              final created = await context.push<ServiceAddress>('/address/new');
              if (created != null) setState(() => _selectedAddress = created);
            },
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มที่อยู่ใหม่'),
          ),
          const SizedBox(height: AppSpacing.s6),
          FilledButton(
            onPressed: category == null || _selectedAddress == null
                ? null
                : () => context.push(
                      '/report/confirm',
                      extra: ReportJobDraft(
                        category: category,
                        address: _selectedAddress!,
                        description: _descriptionController.text,
                      ),
                    ),
            child: const Text('ดูใบประเมินราคา'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
