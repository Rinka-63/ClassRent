import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../providers/coupon_providers.dart';
import '../../domain/entities/coupon.dart';

class CouponManagementScreen extends ConsumerWidget {
  const CouponManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(agencyCouponsProvider);

    return AppScaffold(
      title: 'Manajemen Kupon',
      actions: [
        IconButton(
          onPressed: () => _showCouponDialog(context, ref),
          icon: const Icon(Icons.add),
          tooltip: 'Buat Kupon Baru',
        ),
      ],
      body: couponsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat kupon: $e')),
        data: (coupons) {
          if (coupons.isEmpty) {
            return const Center(child: Text('Belum ada kupon. Buat satu sekarang!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return _CouponCard(coupon: coupon);
            },
          );
        },
      ),
    );
  }

  void _showCouponDialog(BuildContext context, WidgetRef ref, [Coupon? coupon]) {
    showDialog(
      context: context,
      builder: (context) => _CouponFormDialog(coupon: coupon),
    );
  }
}

class _CouponCard extends ConsumerWidget {
  const _CouponCard({required this.coupon});

  final Coupon coupon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Row(
          children: [
            Text(
              coupon.code,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(width: 8),
            if (!coupon.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('NONAKTIF', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            if (coupon.validUntil != null && coupon.validUntil!.isBefore(DateTime.now()))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('EXPIRED', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Diskon: ${coupon.discountPercent}%'),
            if (coupon.maxDiscountAmount != null)
              Text('Maks. Potongan: ${money.format(coupon.maxDiscountAmount)}'),
            if (coupon.validUntil != null)
              Text('Berlaku s/d: ${DateFormat('dd MMM yyyy').format(coupon.validUntil!)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showCouponDialog(context, ref, coupon),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, ref, coupon),
            ),
          ],
        ),
      ),
    );
  }

  void _showCouponDialog(BuildContext context, WidgetRef ref, Coupon coupon) {
    showDialog(
      context: context,
      builder: (context) => _CouponFormDialog(coupon: coupon),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Coupon coupon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kupon?'),
        content: Text('Apakah Anda yakin ingin menghapus kupon ${coupon.code}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(couponRepositoryProvider).deleteCoupon(coupon.id);
        ref.invalidate(agencyCouponsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kupon berhasil dihapus')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }
}

class _CouponFormDialog extends ConsumerStatefulWidget {
  const _CouponFormDialog({this.coupon});

  final Coupon? coupon;

  @override
  ConsumerState<_CouponFormDialog> createState() => _CouponFormDialogState();
}

class _CouponFormDialogState extends ConsumerState<_CouponFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _maxDiscountCtrl;
  bool _isActive = true;
  DateTime? _validUntil;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.coupon?.code);
    _nameCtrl = TextEditingController(text: widget.coupon?.name);
    _discountCtrl = TextEditingController(text: widget.coupon?.discountValue.toInt().toString());
    _maxDiscountCtrl = TextEditingController(text: widget.coupon?.maxDiscountAmount?.toInt().toString());
    _isActive = widget.coupon?.isActive ?? true;
    _validUntil = widget.coupon?.validUntil;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _discountCtrl.dispose();
    _maxDiscountCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'code': _codeCtrl.text.toUpperCase(),
      'name': _nameCtrl.text,
      'discount_type': 'percentage',
      'discount_value': int.parse(_discountCtrl.text),
      'max_discount_amount': _maxDiscountCtrl.text.isEmpty ? null : int.parse(_maxDiscountCtrl.text),
      'is_active': _isActive,
      'valid_from': widget.coupon?.validFrom.toUtc().toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
      'valid_until': _validUntil?.toUtc().toIso8601String(),
    };

    try {
      if (widget.coupon == null) {
        await ref.read(couponRepositoryProvider).createCoupon(data);
      } else {
        await ref.read(couponRepositoryProvider).updateCoupon(widget.coupon!.id, data);
      }
      ref.invalidate(agencyCouponsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kupon tersimpan!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.coupon == null ? 'Buat Kupon Baru' : 'Edit Kupon'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(labelText: 'Kode Kupon', hintText: 'Contoh: DISC20'),
                textCapitalization: TextCapitalization.characters,
                validator: (val) => val == null || val.isEmpty ? 'Kode tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Kupon', hintText: 'Contoh: Promo Akhir Tahun'),
                validator: (val) => val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountCtrl,
                decoration: const InputDecoration(labelText: 'Diskon (%)', suffixText: '%'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Harus diisi';
                  final n = int.tryParse(val);
                  if (n == null || n <= 0 || n > 100) return 'Masukkan 1 - 100';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxDiscountCtrl,
                decoration: const InputDecoration(labelText: 'Maksimal Potongan (Rp)', hintText: 'Opsional'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Status Aktif'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              ListTile(
                title: const Text('Batas Berlaku'),
                subtitle: Text(_validUntil == null ? 'Tidak ada batas waktu' : DateFormat('dd MMM yyyy').format(_validUntil!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _validUntil ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _validUntil = picked);
                  }
                },
              ),
              if (_validUntil != null)
                TextButton(
                  onPressed: () => setState(() => _validUntil = null),
                  child: const Text('Hapus Batas Waktu'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}
