import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../data/payment_repository.dart';
import '../../services/razorpay_service.dart';

final plansProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.plans);
  return response.data as List<dynamic>;
});

final razorpayServiceProvider = Provider<RazorpayService>((ref) {
  final service = RazorpayService();
  ref.onDispose(() => service.dispose());
  return service;
});

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _processing = false;
  String? _processingPlan;

  Future<void> _subscribe(String planType) async {
    setState(() {
      _processing = true;
      _processingPlan = planType;
    });

    try {
      final paymentRepo = ref.read(paymentRepositoryProvider);
      final order = await paymentRepo.createOrder(planType);

      if (order.gateway != 'razorpay' || order.keyId.isEmpty) {
        throw Exception('Razorpay not configured. Add RAZORPAY_KEY_ID to backend .env');
      }

      final profile = await ref.read(profileProvider.future);
      final razorpay = ref.read(razorpayServiceProvider);

      razorpay.openCheckout(
        keyId: order.keyId,
        orderId: order.orderId,
        amountPaise: order.amountPaise,
        planName: planType == 'premium_yearly' ? 'Premium Yearly' : 'Premium Monthly',
        userName: profile['full_name'] as String? ?? 'User',
        userEmail: profile['email'] as String? ?? '',
        userContact: (profile['mobile_number'] as String? ?? '').replaceAll('+', ''),
        onSuccess: (response) => _onPaymentSuccess(response, planType),
        onError: (response) => _onPaymentError(response),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
          _processingPlan = null;
        });
      }
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response, String planType) async {
    try {
      await ref.read(paymentRepositoryProvider).verifyRazorpayPayment(
            orderId: response.orderId ?? '',
            paymentId: response.paymentId ?? '',
            signature: response.signature ?? '',
          );
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🙏 Premium activated! आपका स्वागत है।'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e. Contact support with payment ID.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Payment cancelled'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Premium Plans')),
      body: plans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (planList) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Unlock Unlimited Guidance',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Unlimited AI chat • Voice consultation • Advanced predictions',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Secure payment via Razorpay',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gold, fontSize: 12),
            ),
            const SizedBox(height: 24),
            ...planList.map((plan) {
              final planType = plan['plan_type'] as String;
              final isLoading = _processing && _processingPlan == planType;
              return _PlanCard(
                plan: plan,
                isLoading: isLoading,
                onSubscribe: _processing ? null : () => _subscribe(planType),
              );
            }),
            const SizedBox(height: 16),
            const _FreePlanCard(),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback? onSubscribe;
  final bool isLoading;

  const _PlanCard({
    required this.plan,
    required this.onSubscribe,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isYearly = plan['plan_type'] == 'premium_yearly';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isYearly ? AppTheme.goldGradient : null,
        color: isYearly ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isYearly)
              const Chip(label: Text('BEST VALUE'), backgroundColor: AppColors.background),
            Text(
              plan['name'] ?? '',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isYearly ? AppColors.background : AppColors.gold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${plan['price']}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isYearly ? AppColors.background : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...(plan['features'] as List? ?? []).map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 16,
                      color: isYearly ? AppColors.background : AppColors.gold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text('$f')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: isYearly ? AppColors.background : AppColors.gold,
                foregroundColor: isYearly ? AppColors.gold : AppColors.background,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Subscribe with Razorpay'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreePlanCard extends StatelessWidget {
  const _FreePlanCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Free Plan', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('• 5 AI chats per day'),
            const Text('• Basic Kundli'),
            const Text('• Daily horoscope'),
          ],
        ),
      ),
    );
  }
}
