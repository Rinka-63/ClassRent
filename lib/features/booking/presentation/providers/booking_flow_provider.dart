import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BookingStep { selectDate, selectTime, confirmDetails, payment, success }

class BookingFlowState {
  const BookingFlowState({
    this.step = BookingStep.selectDate,
    this.selectedDate,
    this.startTime,
    this.endTime,
  });

  final BookingStep step;
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  BookingFlowState copyWith({
    BookingStep? step,
    DateTime? selectedDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return BookingFlowState(
      step: step ?? this.step,
      selectedDate: selectedDate ?? this.selectedDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

class BookingFlowNotifier extends StateNotifier<BookingFlowState> {
  BookingFlowNotifier() : super(const BookingFlowState());

  void goTo(BookingStep step) => state = state.copyWith(step: step);
}

final bookingFlowProvider =
    StateNotifierProvider<BookingFlowNotifier, BookingFlowState>(
  (ref) => BookingFlowNotifier(),
);
