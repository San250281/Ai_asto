import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';

final dailyHoroscopeProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.dailyHoroscope);
  return response.data as Map<String, dynamic>;
});

class HoroscopeScreen extends ConsumerWidget {
  const HoroscopeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horoscope = ref.watch(dailyHoroscopeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Horoscope')),
      body: horoscope.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HoroscopeCard(
              title: 'आज का राशिफल',
              content: data['content_hi'] ?? data['content_en'] ?? '',
              icon: Icons.wb_sunny,
            ),
            const SizedBox(height: 16),
            _PredictionTabs(),
          ],
        ),
      ),
    );
  }
}

class _HoroscopeCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _HoroscopeCard({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.spiritualCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const Divider(color: AppColors.gold),
          Text(content, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _PredictionTabs extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ['weekly', 'career', 'marriage', 'health'];
    return DefaultTabController(
      length: types.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: types.map((t) => Tab(text: t.toUpperCase())).toList(),
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              children: types.map((type) {
                return FutureBuilder(
                  future: ref.read(dioProvider).get('/horoscope/$type'),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snapshot.data!.data;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        data['content_hi'] ?? data['content_en'] ?? '',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
