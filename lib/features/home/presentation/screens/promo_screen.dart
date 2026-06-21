import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../booking/domain/entities/coupon.dart';
import '../../../booking/presentation/providers/coupon_providers.dart';

/// Provider to track claimed voucher IDs from database
final claimedVouchersProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  
  final result = await ref.read(couponRepositoryProvider).getClaimedCoupons(user.id);
  return result.fold((l) => {}, (r) => r.toSet());
});

class PromoScreen extends ConsumerWidget {
  const PromoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient App Bar
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Promo & Voucher',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF0052CC), Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: 20,
                      child: Icon(Icons.discount_outlined, size: 160, color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -10,
                      child: Icon(Icons.celebration, size: 120, color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 80, 20, 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '🎉 Promo Spesial',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Klaim voucher dan nikmati\ndiskon menarik!',
                            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _PromoList(),
          ),
        ],
      ),
    );
  }
}

class _PromoList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimedIdsAsync = ref.watch(claimedVouchersProvider);
    final claimedIds = claimedIdsAsync.value ?? {};

    return FutureBuilder(
      future: ref.read(couponRepositoryProvider).getAllCoupons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || claimedIdsAsync.isLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final result = snapshot.data;
        if (result == null || result.isLeft()) {
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.onSurfaceVariant),
                  SizedBox(height: 12),
                  Text('Gagal memuat promo'),
                ],
              ),
            ),
          );
        }

        final coupons = result.getOrElse((l) => []);

        if (coupons.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer_outlined, size: 56, color: AppColors.outlineVariant),
                  SizedBox(height: 12),
                  Text('Belum ada promo tersedia', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('Nantikan promo menarik dari ClassRent!', style: TextStyle(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final coupon = coupons[index];
              final isClaimed = claimedIds.contains(coupon.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PromoCard(coupon: coupon, isClaimed: isClaimed),
              );
            },
            childCount: coupons.length,
          ),
        );
      },
    );
  }
}

class _PromoCard extends ConsumerWidget {
  const _PromoCard({required this.coupon, required this.isClaimed});

  final Coupon coupon;
  final bool isClaimed;

  // Different gradient for each discount tier
  List<Color> get _gradientColors {
    if (coupon.discountPercent >= 50) {
      return const [Color(0xFFE65100), Color(0xFFFF8F00)];
    } else if (coupon.discountPercent >= 30) {
      return const [Color(0xFF6A1B9A), Color(0xFFAB47BC)];
    } else if (coupon.discountPercent >= 20) {
      return const [Color(0xFF1565C0), Color(0xFF42A5F5)];
    }
    return const [Color(0xFF00695C), Color(0xFF26A69A)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _gradientColors[0].withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left discount badge
              Container(
                width: 100,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${coupon.discountPercent}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'OFF',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            // Right info section
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            coupon.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        if (isClaimed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 14, color: Colors.green),
                                SizedBox(width: 4),
                                Text('Diklaim', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      coupon.maxDiscountAmount != null
                          ? 'Maks. diskon ${money.format(coupon.maxDiscountAmount)}'
                          : 'Tanpa batas maksimal diskon',
                      style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                    if (coupon.validUntil != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 13, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Berlaku hingga ${dateFormat.format(coupon.validUntil!)}',
                            style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: isClaimed
                          ? OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Sudah Diklaim'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                            )
                          : FilledButton.icon(
                              onPressed: () async {
                                final user = ref.read(currentUserProvider);
                                if (user == null) return;
                                
                                final result = await ref.read(couponRepositoryProvider).claimCoupon(user.id, coupon.id);
                                if (result.isRight()) {
                                  ref.invalidate(claimedVouchersProvider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('🎉 Voucher ${coupon.code} berhasil diklaim! Gunakan saat checkout.'),
                                        backgroundColor: Colors.green.shade600,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                } else {
                                  final err = result.getLeft().toNullable()?.message ?? 'Gagal klaim';
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(err), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.card_giftcard, size: 16),
                              label: const Text('Klaim Voucher'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _gradientColors[0],
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
