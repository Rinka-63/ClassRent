import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BookingStep { selectDate, selectTime, confirmDetails, payment, success }

class BookingFlowState {
  const BookingFlowState({
    this.step = BookingStep.selectDate,
    this.selectedDate,
    this.startTime,
    this.endTime,
    this.createdBookingId,
  });

  final BookingStep step;
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? createdBookingId;

  BookingFlowState copyWith({
    BookingStep? step,
    DateTime? selectedDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? createdBookingId,
  }) {
    return BookingFlowState(
      step: step ?? this.step,
      selectedDate: selectedDate ?? this.selectedDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdBookingId: createdBookingId ?? this.createdBookingId,
    );
  }
}

class BookingFlowNotifier extends StateNotifier<BookingFlowState> {
  BookingFlowNotifier() : super(const BookingFlowState());

  void goTo(BookingStep step) => state = state.copyWith(step: step);

  void attachCreatedBooking(String bookingId) {
    state = state.copyWith(createdBookingId: bookingId);
  }
}

final bookingFlowProvider =
    StateNotifierProvider<BookingFlowNotifier, BookingFlowState>(
  (ref) => BookingFlowNotifier(),
);
