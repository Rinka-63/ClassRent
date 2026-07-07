import 'package:supabase_flutter/supabase_flutter.dart';

class MidtransService {
  MidtransService();

  final _supabase = Supabase.instance.client;

  /// Creates a Snap transaction via Edge Function and returns the redirect_url
  Future<String> createTransaction({
    required String orderId,
    required double grossAmount,
    required String firstName,
    required String email,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'midtrans/snap',
        body: {
          'transaction_details': {
            'order_id': orderId,
            'gross_amount': grossAmount.toInt(),
          },
          'customer_details': {
            'first_name': firstName,
            'email': email,
          },
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to create Midtrans transaction: ${response.data}');
      }

      return response.data['redirect_url'] as String;
    } catch (e) {
      throw Exception('Failed to create Midtrans transaction: $e');
    }
  }

  /// Process refund via Edge Function (to be implemented on backend later if needed)
  Future<bool> refundTransaction({
    required String orderId,
    required String reason,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'midtrans/refund',
        body: {
          'order_id': orderId,
          'reason': reason,
        },
      );
      
      return response.status == 200;
    } catch (e) {
      throw Exception('Failed to refund Midtrans transaction: $e');
    }
  }
}

