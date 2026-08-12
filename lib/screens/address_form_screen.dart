import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/design_tokens.dart';
import '../models/job.dart';
import '../providers/job_provider.dart';

/// Add/edit one [ServiceAddress] -- the screen that was missing entirely
/// until now (rakbaan_md/BACKLOG.md's long-standing #1 blocker: no customer
/// could create a real job because there was no way to add a real address).
///
/// Pass [existing] to edit; omit it to add a new address. On save, pops
/// with the resulting [ServiceAddress] so a caller (e.g.
/// `ReportJobDetailsScreen`) can select it immediately without a second trip
/// through the address list.
class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, this.existing});

  final ServiceAddress? existing;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  late final _labelController = TextEditingController(text: widget.existing?.label);
  late final _recipientController = TextEditingController(text: widget.existing?.recipientName);
  late final _phoneController = TextEditingController(text: widget.existing?.phone);
  late final _detailController = TextEditingController(text: widget.existing?.fullAddress);
  late bool _isDefault = widget.existing?.isDefault ?? false;
  double? _lat;
  double? _lng;
  bool _locating = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lat = widget.existing?.lat;
    _lng = widget.existing?.lng;
  }

  bool get _isEditing => widget.existing != null;

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('กรุณาเปิด Location Service ของอุปกรณ์ก่อน');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
    } catch (e) {
      setState(() => _error = e is StateError ? e.message : 'ระบุตำแหน่งไม่สำเร็จ');
    } finally {
      setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (_labelController.text.trim().isEmpty || _detailController.text.trim().isEmpty) {
      setState(() => _error = 'กรุณากรอกป้ายชื่อและรายละเอียดที่อยู่');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final jobs = context.read<JobProvider>();
    try {
      if (_isEditing) {
        final updated = ServiceAddress(
          id: widget.existing!.id,
          label: _labelController.text.trim(),
          fullAddress: _detailController.text.trim(),
          recipientName: _recipientController.text.trim(),
          phone: _phoneController.text.trim(),
          isDefault: _isDefault,
          lat: _lat,
          lng: _lng,
        );
        await jobs.updateAddress(updated);
        if (mounted) context.pop(updated);
      } else {
        final created = await jobs.addAddress(
          label: _labelController.text.trim(),
          recipientName: _recipientController.text.trim(),
          phone: _phoneController.text.trim(),
          addressDetail: _detailController.text.trim(),
          lat: _lat,
          lng: _lng,
          isDefault: _isDefault,
        );
        if (mounted) context.pop(created);
      }
    } catch (e) {
      setState(() => _error = 'บันทึกไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบที่อยู่นี้?'),
        content: Text('ลบ "${widget.existing!.label}" ใช่ไหม'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => context.pop(true), child: const Text('ลบ')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final jobs = context.read<JobProvider>();
    setState(() => _saving = true);
    try {
      await jobs.deleteAddress(widget.existing!.id);
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'ลบไม่สำเร็จ: $e';
      });
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _recipientController.dispose();
    _phoneController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'แก้ไขที่อยู่' : 'เพิ่มที่อยู่ใหม่'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: AppColors.error600),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(labelText: 'ป้ายชื่อที่อยู่', hintText: 'เช่น บ้านหลัก, คอนโด'),
          ),
          const SizedBox(height: AppSpacing.s3),
          TextField(
            controller: _recipientController,
            decoration: const InputDecoration(labelText: 'ชื่อผู้รับบริการหน้างาน'),
          ),
          const SizedBox(height: AppSpacing.s3),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'เบอร์โทรติดต่อประจำที่อยู่นี้'),
          ),
          const SizedBox(height: AppSpacing.s3),
          TextField(
            controller: _detailController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'รายละเอียดที่อยู่',
              hintText: 'บ้านเลขที่ ซอย ถนน ตำบล อำเภอ จังหวัด รหัสไปรษณีย์',
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _lat != null && _lng != null
                        ? 'พิกัด: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                        : 'ยังไม่มีพิกัด GPS (ใช้คำนวณค่าระยะทาง Zone Fee)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                // IntrinsicWidth is required here -- a Button as a bare
                // (non-Expanded) Row sibling throws "BoxConstraints forces
                // an infinite width" on this Flutter/Impeller build, the
                // same crash already found+fixed once today in
                // tracking_screen.dart's _HistoryTile.
                IntrinsicWidth(
                  child: OutlinedButton.icon(
                    onPressed: _locating ? null : _useCurrentLocation,
                    icon: _locating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: const Text('ใช้ตำแหน่งปัจจุบัน'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('ตั้งเป็นที่อยู่หลัก'),
            value: _isDefault,
            onChanged: (value) => setState(() => _isDefault = value),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(_error!, style: const TextStyle(color: AppColors.error600)),
          ],
          const SizedBox(height: AppSpacing.s4),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
}
