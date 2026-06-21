import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/coupon.dart';
import '../../../rooms/domain/entities/room.dart';

enum BookingStep { selectDate, confirmDetails }

class BookingFlowState {
  const BookingFlowState({
    this.step = BookingStep.selectDate,
    this.roomId,
    this.room,
    this.selectedDate,
    this.startTime,
    this.endTime,
    this.appliedCoupon,
    this.isProcessing = false,
  });

  final BookingStep step;
  final String? roomId;
  final Room? room;
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Coupon? appliedCoupon;
  final bool isProcessing;

  BookingFlowState copyWith({
    BookingStep? step,
    String? roomId,
    Room? room,
    DateTime? selectedDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Coupon? appliedCoupon,
    bool clearCoupon = false,
    bool? isProcessing,
  }) {
    return BookingFlowState(
      step: step ?? this.step,
      roomId: roomId ?? this.roomId,
      room: room ?? this.room,
      selectedDate: selectedDate ?? this.selectedDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  double get durationHours {
    if (startTime == null || endTime == null) return 0;
    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    final diff = endMinutes - startMinutes;
    return diff > 0 ? diff / 60.0 : 0;
  }

  double get basePrice {
    if (room == null) return 0;
    return room!.hourlyRate * durationHours;
  }

  double get discountAmount {
    if (appliedCoupon == null || basePrice <= 0) return 0;
    final maxDiscount = appliedCoupon!.maxDiscountAmount;
    final discount = basePrice * (appliedCoupon!.discountPercent / 100);
    if (maxDiscount != null && discount > maxDiscount) {
      return maxDiscount;
    }
    return discount;
  }

  double get finalPrice => basePrice - discountAmount;
}

class BookingFlowNotifier extends StateNotifier<BookingFlowState> {
  BookingFlowNotifier() : super(const BookingFlowState());

  void init(Room room) {
    state = const BookingFlowState().copyWith(roomId: room.id, room: room);
  }

  void goTo(BookingStep step) => state = state.copyWith(step: step);

  void setDateAndTime(DateTime date, TimeOfDay start, TimeOfDay end) {
    state = state.copyWith(selectedDate: date, startTime: start, endTime: end);
  }

  void applyCoupon(Coupon coupon) {
    state = state.copyWith(appliedCoupon: coupon);
  }

  void removeCoupon() {
    state = state.copyWith(clearCoupon: true);
  }
  
  void setProcessing(bool value) {
    state = state.copyWith(isProcessing: value);
  }
}

final bookingFlowProvider =
    StateNotifierProvider<BookingFlowNotifier, BookingFlowState>(
  (ref) => BookingFlowNotifier(),
);
