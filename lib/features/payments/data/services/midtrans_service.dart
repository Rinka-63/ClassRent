import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MidtransService {
  MidtransService() : _dio = Dio() {
    _dio.options.baseUrl = 'https://app.sandbox.midtrans.com/snap/v1/';
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  final Dio _dio;
  final Dio _coreDio = Dio(BaseOptions(
    baseUrl: 'https://api.sandbox.midtrans.com/v2/',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  String get _serverKey => dotenv.env['MIDTRANS_SERVER_KEY'] ?? 'SB-Mid-server-DUMMYKEY';

  /// Creates a Snap transaction and returns the redirect_url
  Future<String> createTransaction({
    required String orderId,
    required double grossAmount,
    required String firstName,
    required String email,
  }) async {
    final authString = base64Encode(utf8.encode('$_serverKey:'));
    
    try {
      final response = await _dio.post(
        'transactions',
        options: Options(
          headers: {
            'Authorization': 'Basic $authString',
          },
        ),
        data: {
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

      return response.data['redirect_url'] as String;
    } catch (e) {
      if (e is DioException) {
        throw Exception('Failed to create Midtrans transaction: ${e.response?.data ?? e.message}');
      }
      throw Exception('Failed to create Midtrans transaction: $e');
    }
  }

  /// Process refund for a transaction
  Future<bool> refundTransaction({
    required String orderId,
    required String reason,
  }) async {
    final authString = base64Encode(utf8.encode('$_serverKey:'));
    
    try {
      final response = await _coreDio.post(
        '$orderId/refund',
        options: Options(
          headers: {
            'Authorization': 'Basic $authString',
          },
        ),
        data: {
          'reason': reason,
        },
      );

      return response.data['status_code'] == '200' || response.data['status_code'] == '201';
    } catch (e) {
      if (e is DioException) {
        throw Exception('Failed to refund Midtrans transaction: ${e.response?.data ?? e.message}');
      }
      throw Exception('Failed to refund Midtrans transaction: $e');
    }
  }
}
