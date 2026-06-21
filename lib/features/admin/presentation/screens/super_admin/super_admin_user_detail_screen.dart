import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/error_card.dart';
import '../../../domain/entities/platform_user.dart';
import '../../providers/super_admin_providers.dart';

class SuperAdminUserDetailScreen extends ConsumerWidget {
  const SuperAdminUserDetailScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(platformUserDetailProvider(userId));
    final bookingsAsync = ref.watch(userBookingsProvider(userId));
    final paymentsAsync = ref.watch(userPaymentsProvider(userId));
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail User')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(message: error.toString()),
        ),
        data: (user) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileCard(user: user, dateFormat: dateFormat),
            const SizedBox(height: 20),
            _Section(
              title: 'Riwayat Booking',
              child: bookingsAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Gagal memuat booking'),
                data: (bookings) => bookings.isEmpty
                    ? const Text('Belum ada booking')
                    : Column(
                        children: [
                          for (final booking in bookings)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.event_note_outlined),
                              title: Text(
                                  _nestedName(booking['rooms']) ?? 'Booking'),
                              subtitle: Text(
                                  '${booking['status']} • ${booking['booking_date']}'),
                              trailing: Text(currency.format(
                                  (booking['final_price'] as num?)
                                          ?.toDouble() ??
                                      0)),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Riwayat Pembayaran',
              child: paymentsAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Gagal memuat payment'),
                data: (payments) => payments.isEmpty
                    ? const Text('Belum ada payment')
                    : Column(
                        children: [
                          for (final payment in payments)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.payments_outlined),
                              title: Text(payment.status),
                              subtitle:
                                  Text(dateFormat.format(payment.createdAt)),
                              trailing: Text(currency.format(payment.amount)),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Aktivitas Terakhir',
              child: Text(
                'Login/logout dan perubahan profil tercatat di Audit Log platform.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _nestedName(dynamic nested) {
    if (nested is Map<String, dynamic>) return nested['name'] as String?;
    if (nested is List && nested.isNotEmpty) {
      return (nested.first as Map<String, dynamic>)['name'] as String?;
    }
    return null;
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.dateFormat});

  final PlatformUser user;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.surfaceContainerLow,
                child: Text(user.fullName.characters.first.toUpperCase(),
                    style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(user.email),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Row('Role', user.role.name),
          _Row('Agency', user.agencyName ?? '-'),
          _Row('Status', user.statusLabel),
          _Row('Telepon', user.phone ?? '-'),
          _Row(
            'Last Login',
            user.lastLoginAt == null
                ? '-'
                : dateFormat.format(user.lastLoginAt!),
          ),
          _Row('Registrasi',
              dateFormat.format(user.createdAt ?? DateTime.now())),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(color: AppColors.onSurfaceVariant))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
