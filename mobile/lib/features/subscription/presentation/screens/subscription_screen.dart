import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';

final plansProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.plans);
  return response.data as List<dynamic>;
});

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            const SizedBox(height: 24),
            ...planList.map((plan) => _PlanCard(
                  plan: plan,
                  onSubscribe: () => _subscribe(ref, plan['plan_type']),
                )),
            const SizedBox(height: 16),
            const _FreePlanCard(),
          ],
        ),
      ),
    );
  }

  Future<void> _subscribe(WidgetRef ref, String planType) async {
    final dio = ref.read(dioProvider);
    await dio.post(
      ApiConstants.createOrder,
      data: {'plan_type': planType, 'gateway': 'razorpay'},
    );
    // Integrate Razorpay checkout in production
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onSubscribe;

  const _PlanCard({required this.plan, required this.onSubscribe});

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
              onPressed: onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: isYearly ? AppColors.background : AppColors.gold,
                foregroundColor: isYearly ? AppColors.gold : AppColors.background,
              ),
              child: const Text('Subscribe Now'),
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
