import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _language = 'hindi';
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('language') ?? 'hindi';
      _notifications = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    setState(() => _language = lang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Language'),
          RadioListTile<String>(
            title: const Text('हिंदी'),
            value: 'hindi',
            groupValue: _language,
            onChanged: (v) => _saveLanguage(v!),
          ),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'english',
            groupValue: _language,
            onChanged: (v) => _saveLanguage(v!),
          ),
          RadioListTile<String>(
            title: const Text('Hinglish'),
            value: 'hinglish',
            groupValue: _language,
            onChanged: (v) => _saveLanguage(v!),
          ),
          const _SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Horoscope, festivals, transits'),
            value: _notifications,
            onChanged: (v) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications', v);
              setState(() => _notifications = v);
            },
          ),
          const _SectionHeader('Privacy'),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: AppColors.gold),
            title: const Text('Privacy Policy'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text('Delete Account'),
            subtitle: const Text('GDPR compliant data deletion'),
            onTap: () => _showDeleteDialog(context),
          ),
          const _SectionHeader('About'),
          const ListTile(
            title: Text('AI Jyotish Guru'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your data. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Call DELETE /users/me
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
