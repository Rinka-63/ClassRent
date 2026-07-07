import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../booking/presentation/providers/booking_admin_providers.dart';
import '../../../booking/presentation/screens/bookings_screen.dart';
import '../../../booking/presentation/utils/auto_cancel_pending_bookings.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../../../rooms/presentation/providers/rooms_providers.dart';
import '../../../rooms/presentation/widgets/room_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _autoCancelChecked = false;
  static const _homeBlue = Color(0xff0f8fb3);
  static const _homeBlueDeep = Color(0xff08718f);

  @override
  Widget build(BuildContext context) {
    final roomsValue = ref.watch(roomsProvider);
    final user = ref.watch(currentUserProvider);
    final unreadNotifications = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    final bookingsAsync = ref.watch(userBookingsProvider);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (!_autoCancelChecked && bookingsAsync.hasValue) {
      _autoCancelChecked = true;
      final bookings = bookingsAsync.valueOrNull ?? [];
      autoCancelStalePendingBookings(
        bookings: bookings,
        repository: ref.read(bookingRepositoryProvider),
      ).then((_) {
        if (mounted) ref.invalidate(userBookingsProvider);
      });
    }

    final upcoming = bookingsAsync.valueOrNull
        ?.where((b) =>
            b.status == 'confirmed' ||
            b.status == 'pending_payment' ||
            b.status == 'pending_approval')
        .toList();
    upcoming?.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
    final nextBooking =
        upcoming != null && upcoming.isNotEmpty ? upcoming.first : null;
    final headerGradient = isDark
        ? LinearGradient(
            colors: [
              colorScheme.surfaceContainerHigh,
              colorScheme.surfaceContainerHighest,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [_homeBlueDeep, _homeBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(roomsProvider);
            ref.invalidate(userBookingsProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: false,
                expandedHeight: 116,
                backgroundColor:
                    isDark ? colorScheme.surfaceContainerHigh : _homeBlue,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Container(
                    decoration: BoxDecoration(gradient: headerGradient),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 4,
                      left: 20,
                      right: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.welcome,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: isDark
                                          ? colorScheme.onSurfaceVariant
                                          : Colors.white
                                              .withValues(alpha: 0.78),
                                    ),
                                  ),
                                  Text(
                                    user?.fullName.split(' ').first ??
                                        'ClassRent',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? colorScheme.onSurface
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  context.push(AppRoutes.notifications),
                              icon: NotificationBadge(
                                count: unreadNotifications,
                                child: Icon(
                                  Icons.notifications_none,
                                  color: isDark
                                      ? colorScheme.onSurface
                                      : Colors.white,
                                ),
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? colorScheme.surface
                                        .withValues(alpha: 0.14)
                                    : Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () => context.push(AppRoutes.profile),
                              icon: Icon(Icons.person_outline,
                                  color: isDark
                                      ? colorScheme.onSurface
                                      : Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? colorScheme.surface
                                        .withValues(alpha: 0.14)
                                    : Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(58),
                  child: Container(
                    width: double.infinity,
                    color:
                        isDark ? colorScheme.surfaceContainerHigh : _homeBlue,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _HomeSearchBar(
                      onTap: () => context.go(AppRoutes.search),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: InformationBanner(
                    title: nextBooking != null
                        ? strings.bookingUpcoming
                        : strings.tips,
                    message: nextBooking != null
                        ? '${nextBooking.roomName ?? 'Ruangan'} • ${DateFormat('dd MMM yyyy', 'id_ID').format(nextBooking.bookingDate)}'
                        : strings.tr(
                            'Gunakan filter di halaman Ruangan untuk menemukan ruang sesuai kapasitas, harga, dan fasilitas.',
                            'Use filters on the Rooms page to find spaces by capacity, price, and facilities.',
                          ),
                    icon: nextBooking != null
                        ? Icons.event_available_outlined
                        : Icons.lightbulb_outline,
                    actionLabel: nextBooking != null
                        ? strings.tr('Lihat Detail', 'View Details')
                        : null,
                    onAction: nextBooking != null
                        ? () => context.push(
                              '/bookings/${nextBooking.id}',
                            )
                        : null,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.meeting_room_outlined,
                          label: strings.rooms,
                          value: roomsValue.maybeWhen(
                            data: (rooms) => '${rooms.length}',
                            orElse: () => '-',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.event_available_outlined,
                          label: strings.tr('Pesanan Aktif', 'Active Bookings'),
                          value: bookingsAsync.maybeWhen(
                            data: (bookings) =>
                                '${bookings.where((b) => b.status == 'confirmed' || b.status == 'pending_payment').length}',
                            orElse: () => '-',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.recommendation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.search),
                        child: Text(strings.seeAll),
                      ),
                    ],
                  ),
                ),
              ),
              roomsValue.when(
                loading: () => SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingView(
                    message: strings.tr(
                      'Menyiapkan rekomendasi ruangan...',
                      'Preparing room recommendations...',
                    ),
                  ),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ErrorCard(
                      message: error.toString(),
                      onRetry: () => ref.invalidate(roomsProvider),
                    ),
                  ),
                ),
                data: (rooms) {
                  if (rooms.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.meeting_room_outlined,
                        title: strings.tr('Belum ada ruangan', 'No rooms yet'),
                        message: strings.tr(
                          'Ruangan akan muncul setelah admin menambahkannya.',
                          'Rooms will appear after admins add them.',
                        ),
                        actionLabel: strings.tr('Muat ulang', 'Reload'),
                        onAction: () => ref.invalidate(roomsProvider),
                      ),
                    );
                  }

                  final recommendations = rooms.take(6).toList();
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent:
                            MediaQuery.sizeOf(context).width > 600 ? 280 : 210,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 310,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, index) => RoomCard(room: recommendations[index]),
                        childCount: recommendations.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const RoleAwareNavBar(currentPath: AppRoutes.home),
    );
  }
}

class InformationBanner extends StatefulWidget {
  const InformationBanner({
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<InformationBanner> createState() => _InformationBannerState();
}

class _InformationBannerState extends State<InformationBanner> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_index + 1) % 3;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final banners = [
      _BannerData(
        title: widget.title,
        message: widget.message.replaceAll('â€¢', '•'),
        icon: widget.icon,
        color: AppColors.primaryDeep,
        accent: AppColors.accent,
        onTap: widget.onAction,
      ),
      _BannerData(
        title: strings.tr(
          'Ruang Tepat, Jadwal Rapi',
          'Right Room, Clear Schedule',
        ),
        message: strings.tr(
          'Temukan kelas, meeting room, dan studio yang siap dipakai.',
          'Find classrooms, meeting rooms, and studios ready to use.',
        ),
        icon: Icons.auto_awesome_outlined,
        color: AppColors.primary,
        accent: const Color(0xff2ec4b6),
      ),
      _BannerData(
        title: strings.tr('Cari Sesuai Kebutuhan', 'Search by Your Needs'),
        message: strings.tr(
          'Filter kota, tipe ruang, kapasitas, dan fasilitas utama.',
          'Filter by city, room type, capacity, and key facilities.',
        ),
        icon: Icons.tune_outlined,
        color: const Color(0xff4c6f2f),
        accent: const Color(0xffffb703),
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 146,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (value) => setState(() => _index = value),
            itemCount: banners.length,
            itemBuilder: (context, index) => _BannerCard(data: banners[index]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: _index == i ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _index == i
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BannerData {
  const _BannerData({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.accent,
    this.onTap,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final Color accent;
  final VoidCallback? onTap;
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.data});

  final _BannerData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: data.color,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -28,
              child: Icon(
                data.icon,
                size: 140,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              right: 18,
              top: 18,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: data.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 82, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  color: _HomeScreenState._homeBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.of(context).tr(
                    'Cari ruangan, kota, kapasitas...',
                    'Search rooms, city, capacity...',
                  ),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ),
              const Icon(Icons.tune_rounded, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
