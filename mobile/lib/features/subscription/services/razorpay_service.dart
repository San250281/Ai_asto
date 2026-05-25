import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

typedef PaymentSuccessCallback = void Function(PaymentSuccessResponse response);
typedef PaymentErrorCallback = void Function(PaymentFailureResponse response);

class RazorpayService {
  late final Razorpay _razorpay;
  PaymentSuccessCallback? _onSuccess;
  PaymentErrorCallback? _onError;
  VoidCallback? _onExternalWallet;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    _onSuccess?.call(response);
  }

  void _handleError(PaymentFailureResponse response) {
    _onError?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onExternalWallet?.call();
  }

  void openCheckout({
    required String keyId,
    required String orderId,
    required int amountPaise,
    required String planName,
    required String userName,
    required String userEmail,
    required String userContact,
    required PaymentSuccessCallback onSuccess,
    required PaymentErrorCallback onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;

    final options = {
      'key': keyId,
      'amount': amountPaise,
      'name': 'AI Jyotish Guru',
      'description': planName,
      'order_id': orderId,
      'currency': 'INR',
      'prefill': {
        'contact': userContact,
        'email': userEmail.isNotEmpty ? userEmail : 'user@aijyotishguru.com',
        'name': userName,
      },
      'theme': {'color': '#D4AF37'},
      'modal': {'ondismiss': () {}},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      onError(PaymentFailureResponse(
        -1,
        'Failed to open checkout: $e',
        null,
      ));
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
