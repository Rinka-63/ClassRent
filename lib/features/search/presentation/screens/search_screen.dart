import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../rooms/presentation/providers/rooms_providers.dart';
import '../../../rooms/presentation/widgets/room_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomsValue = ref.watch(roomSearchProvider(_query));

    return AppScaffold(
      title: 'Search',
      bottomNavigationBar: const RoleAwareNavBar(currentPath: AppRoutes.search),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(roomSearchProvider(_query)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search room name or location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            roomsValue.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorCard(
                message: error.toString(),
                onRetry: () => ref.invalidate(roomSearchProvider(_query)),
              ),
              data: (rooms) {
                if (rooms.isEmpty) {
                  return EmptyState(
                    title: _query.isEmpty
                        ? 'No rooms available'
                        : 'No results found',
                    message: _query.isEmpty
                        ? 'Available rooms will appear here.'
                        : 'Try another room name or location.',
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rooms.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.84,
                  ),
                  itemBuilder: (_, index) => RoomCard(room: rooms[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }
}
