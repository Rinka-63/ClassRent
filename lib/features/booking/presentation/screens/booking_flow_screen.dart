import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../rooms/domain/entities/room.dart';
import '../../../rooms/presentation/providers/rooms_providers.dart';
import '../providers/booking_admin_providers.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({this.initialRoomId, super.key});

  final String? initialRoomId;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomId = widget.initialRoomId;
    final roomValue = roomId == null || roomId.isEmpty
        ? null
        : ref.watch(roomDetailProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('New Booking')),
      body: roomValue == null
          ? const EmptyState(
              title: 'Choose a room first',
              message: 'Open a room detail page, then tap Start Booking.',
            )
          : roomValue.when(
              loading: () => const LoadingView(),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: ErrorCard(message: error.toString()),
              ),
              data: _buildForm,
            ),
    );
  }

  Widget _buildForm(Room room) {
    final money =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final totalPrice = _estimatedPrice(room);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _RoomSummary(room: room),
          const SizedBox(height: 16),
          _PickerTile(
            icon: Icons.calendar_today_outlined,
            title: 'Booking date',
            value: _selectedDate == null
                ? 'Select date'
                : DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate!),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  icon: Icons.schedule_outlined,
                  title: 'Start time',
                  value:
                      _startTime == null ? 'Start' : _formatTime(_startTime!),
                  onTap: () => _pickTime(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerTile(
                  icon: Icons.timer_outlined,
                  title: 'End time',
                  value: _endTime == null ? 'End' : _formatTime(_endTime!),
                  onTap: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Optional request for the room owner',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price estimate',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('${money.format(room.hourlyRate)} / hour'),
                  const SizedBox(height: 4),
                  Text(
                    totalPrice == null
                        ? 'Select time to calculate total.'
                        : money.format(totalPrice),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : () => _submit(room),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_isSubmitting ? 'Saving...' : 'Confirm Booking'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? _startTime ?? TimeOfDay.now()),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _submit(Room room) async {
    final user = ref.read(currentUserProvider);
    final date = _selectedDate;
    final start = _startTime;
    final end = _endTime;
    final totalPrice = _estimatedPrice(room);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login before booking.')),
      );
      return;
    }
    if (date == null || start == null || end == null || totalPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select booking date and valid time range.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ref.read(bookingRepositoryProvider).createBooking({
      'user_id': user.id,
      'room_id': room.id,
      if (room.facilityId != null) 'facility_id': room.facilityId,
      'booking_date': DateFormat('yyyy-MM-dd').format(date),
      'start_time': _formatTime(start),
      'end_time': _formatTime(end),
      'base_price': room.hourlyRate,
      'final_price': totalPrice,
      'status': room.requiresApproval ? 'pending_approval' : 'pending',
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.match(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) {
        ref.invalidate(userBookingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking saved successfully.')),
        );
        context.go(AppRoutes.bookings);
      },
    );
  }

  double? _estimatedPrice(Room room) {
    final start = _startTime;
    final end = _endTime;
    if (start == null || end == null) return null;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    if (endMinutes <= startMinutes) return null;
    final hours = (endMinutes - startMinutes) / 60;
    if (hours < room.minimumHours) return room.hourlyRate * room.minimumHours;
    return room.hourlyRate * hours;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _RoomSummary extends StatelessWidget {
  const _RoomSummary({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.meeting_room_outlined)),
        title: Text(room.name),
        subtitle: Text('${room.city} - ${room.capacity} seats'),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
