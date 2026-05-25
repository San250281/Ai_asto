import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(dioProvider));
});

class PaymentOrder {
  final String orderId;
  final String keyId;
  final int amountPaise;
  final String currency;
  final String gateway;

  PaymentOrder({
    required this.orderId,
    required this.keyId,
    required this.amountPaise,
    required this.currency,
    required this.gateway,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'];
    final amountNum = amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0;
    return PaymentOrder(
      orderId: json['order_id'] as String,
      keyId: json['key_id'] as String? ?? '',
      amountPaise: (amountNum * 100).round(),
      currency: json['currency'] as String? ?? 'INR',
      gateway: json['gateway'] as String? ?? 'razorpay',
    );
  }
}

class PaymentRepository {
  final Dio _dio;

  PaymentRepository(this._dio);

  Future<PaymentOrder> createOrder(String planType, {String gateway = 'razorpay'}) async {
    final response = await _dio.post(
      ApiConstants.createOrder,
      data: {'plan_type': planType, 'gateway': gateway},
    );
    return PaymentOrder.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await _dio.post(
      ApiConstants.razorpayVerify,
      data: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
