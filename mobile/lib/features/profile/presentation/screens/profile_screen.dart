import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_repository.dart';

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.profile);
  return response.data as Map<String, dynamic>;
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                child: Text(
                  (user['full_name'] as String? ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 36, color: AppColors.gold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user['full_name'] ?? '',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            if (user['is_premium'] == true)
              const Center(
                child: Chip(
                  label: Text('Premium Member'),
                  backgroundColor: AppColors.gold,
                ),
              ),
            const SizedBox(height: 24),
            _ProfileTile(Icons.cake, 'Date of Birth', '${user['date_of_birth']}'),
            _ProfileTile(Icons.access_time, 'Birth Time', '${user['birth_time']}'),
            _ProfileTile(Icons.place, 'Birth Place', user['birth_place'] ?? ''),
            _ProfileTile(Icons.phone, 'Mobile', user['mobile_number'] ?? ''),
            _ProfileTile(Icons.language, 'Language', user['language_preference'] ?? ''),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.star, color: AppColors.gold),
              title: const Text('Upgrade to Premium'),
              onTap: () => context.push('/subscription'),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Logout'),
              onTap: () async {
                await ref.read(authRepositoryProvider).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.gold),
        title: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        subtitle: Text(value),
      ),
    );
  }
}
