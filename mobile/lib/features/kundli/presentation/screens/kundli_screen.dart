import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';

final kundliProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get(ApiConstants.kundli);
    return response.data as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
});

class KundliScreen extends ConsumerWidget {
  const KundliScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kundliAsync = ref.watch(kundliProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Kundli')),
      body: kundliAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _GenerateView(ref: ref),
        data: (kundli) {
          if (kundli == null) return _GenerateView(ref: ref);
          return _KundliView(kundli: kundli);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generateKundli(ref),
        icon: const Icon(Icons.refresh),
        label: const Text('Regenerate'),
      ),
    );
  }

  Future<void> _generateKundli(WidgetRef ref) async {
    final dio = ref.read(dioProvider);
    await dio.post(ApiConstants.kundliGenerate, data: {'force_regenerate': true});
    ref.invalidate(kundliProvider);
  }
}

class _GenerateView extends ConsumerWidget {
  final WidgetRef ref;
  const _GenerateView({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 80, color: AppColors.gold),
          const SizedBox(height: 24),
          Text('Generate Your Kundli', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              await dio.post(ApiConstants.kundliGenerate);
              ref.invalidate(kundliProvider);
            },
            child: const Text('Generate Kundli'),
          ),
        ],
      ),
    );
  }
}

class _KundliView extends StatelessWidget {
  final Map<String, dynamic> kundli;
  const _KundliView({required this.kundli});

  @override
  Widget build(BuildContext context) {
    final lagna = kundli['lagna_chart'] as Map? ?? {};
    final planets = kundli['planet_positions'] as Map? ?? {};
    final dasha = kundli['dasha'] as Map? ?? {};
    final dosha = kundli['dosha_analysis'] as Map? ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'लग्न कुंडली',
          child: Text('Lagna: ${lagna['lagna'] ?? 'N/A'}'),
        ),
        _SectionCard(
          title: 'राशि & नक्षत्र',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rashi: ${kundli['rashi'] ?? 'N/A'}'),
              Text('Nakshatra: ${kundli['nakshatra'] ?? 'N/A'}'),
            ],
          ),
        ),
        _SectionCard(
          title: 'ग्रह स्थिति',
          child: Column(
            children: planets.entries.map((e) {
              final data = e.value as Map?;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${data?['rashi'] ?? ''} ${data?['degree_in_sign'] ?? ''}°'),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        _SectionCard(
          title: 'दशा',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mahadasha: ${dasha['current_mahadasha'] ?? 'N/A'}'),
              Text('Antardasha: ${dasha['current_antardasha'] ?? 'N/A'}'),
              Text('Remaining: ${dasha['remaining_years'] ?? 'N/A'} years'),
            ],
          ),
        ),
        _SectionCard(
          title: 'दोष विश्लेषण',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DoshaRow('Mangal Dosha', dosha['mangal_dosha'] == true),
              _DoshaRow('Kaal Sarp', dosha['kaal_sarp_dosha'] == true),
              _DoshaRow('Pitra Dosha', dosha['pitra_dosha'] == true),
              if (dosha['remedies'] != null) ...[
                const SizedBox(height: 12),
                const Text('उपाय:', style: TextStyle(color: AppColors.gold)),
                ...(dosha['remedies'] as List).map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $r'),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (kundli['horoscope_summary'] != null)
          _SectionCard(
            title: 'सारांश',
            child: Text(kundli['horoscope_summary']),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(color: AppColors.gold),
            child,
          ],
        ),
      ),
    );
  }
}

class _DoshaRow extends StatelessWidget {
  final String label;
  final bool present;
  const _DoshaRow(this.label, this.present);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          present ? Icons.warning_amber : Icons.check_circle,
          color: present ? AppColors.error : AppColors.success,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
