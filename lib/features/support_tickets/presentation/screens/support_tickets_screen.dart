import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';

class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AppScaffold(
      title: strings.tr('Pusat Bantuan', 'Help Center'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.support_agent_outlined,
                  color: Colors.white,
                  size: 36,
                ),
                const SizedBox(height: 16),
                Text(
                  strings.tr(
                    'Ada yang bisa kami bantu?',
                    'How can we help?',
                  ),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.tr(
                    'Temukan jawaban cepat untuk booking, pembayaran, akun, dan pengelolaan ruangan.',
                    'Find quick answers for bookings, payments, accounts, and room management.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            strings.tr('Topik Bantuan', 'Help Topics'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _HelpTopicTile(
            icon: Icons.event_available_outlined,
            title: strings.tr('Booking Ruangan', 'Room Booking'),
            subtitle: strings.tr(
              'Cara memilih jadwal, cek status, dan membatalkan pesanan.',
              'How to choose schedules, check status, and cancel bookings.',
            ),
          ),
          _HelpTopicTile(
            icon: Icons.payments_outlined,
            title: strings.payments,
            subtitle: strings.tr(
              'Panduan pembayaran Midtrans dan status transaksi.',
              'Guide to Midtrans payments and transaction status.',
            ),
          ),
          _HelpTopicTile(
            icon: Icons.account_circle_outlined,
            title: strings.tr('Akun & Profil', 'Account & Profile'),
            subtitle: strings.tr(
              'Bantuan login, informasi kontak, dan keamanan akun.',
              'Help with login, contact information, and account security.',
            ),
          ),
          _HelpTopicTile(
            icon: Icons.business_outlined,
            title: strings.tr('Admin Agensi', 'Agency Admin'),
            subtitle: strings.tr(
              'Informasi approval agency, ruangan, laporan, dan booking.',
              'Information about agency approval, rooms, reports, and bookings.',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            strings.tr('Tiket Bantuan', 'Support Tickets'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const _TicketEmptyCard(),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.profile),
            icon: const Icon(Icons.person_outline),
            label: Text(strings.tr('Kembali ke Profil', 'Back to Profile')),
          ),
        ],
      ),
    );
  }
}

class _HelpTopicTile extends StatelessWidget {
  const _HelpTopicTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.outline),
        ],
      ),
    );
  }
}

class _TicketEmptyCard extends StatelessWidget {
  const _TicketEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accentContainer.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.mark_chat_unread_outlined,
              color: AppColors.secondary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.of(context).tr(
              'Belum ada tiket aktif',
              'No active tickets yet',
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.of(context).tr(
              'Jika fitur tiket sudah diaktifkan oleh backend, daftar percakapan bantuan Anda akan tampil di sini.',
              'When support tickets are enabled by the backend, your help conversations will appear here.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
