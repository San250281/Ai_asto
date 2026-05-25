import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/spiritual_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('AI Jyotish Guru'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SpiritualCard(
                    title: 'आज का राशिफल',
                    subtitle: 'Daily personalized horoscope',
                    icon: Icons.wb_sunny,
                    onTap: () => context.go('/horoscope'),
                  ).animate().fadeIn().slideY(begin: 0.2),
                  const SizedBox(height: 16),
                  SpiritualCard(
                    title: 'आपकी कुंडली',
                    subtitle: 'Lagna, planets, dasha & dosha',
                    icon: Icons.auto_awesome,
                    onTap: () => context.go('/kundli'),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                  const SizedBox(height: 16),
                  _VoiceAssistantCard(
                    onTap: () => context.go('/voice'),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Predictions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _PredictionGrid(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceAssistantCard extends StatelessWidget {
  final VoidCallback onTap;
  const _VoiceAssistantCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: AppColors.gold, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Voice Astrologer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.greetingHi,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.background.withValues(alpha: 0.8),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.background),
          ],
        ),
      ),
    );
  }
}

class _PredictionGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Career', Icons.work, Colors.blue),
      ('Marriage', Icons.favorite, Colors.pink),
      ('Health', Icons.health_and_safety, Colors.green),
      ('Finance', Icons.account_balance_wallet, Colors.amber),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final (title, icon, color) = items[index];
        return SpiritualCard(
          title: title,
          icon: icon,
          accentColor: color,
          compact: true,
          onTap: () => context.go('/horoscope'),
        );
      },
    );
  }
}
