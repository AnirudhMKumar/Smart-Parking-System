import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                (authState.user?.fullName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(authState.user?.fullName ?? 'User', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(authState.user?.email ?? '', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            Card(
              child: Column(
                children: [
                  _ProfileTile(icon: Icons.history, title: 'Reservation History', onTap: () => context.go('/history')),
                  const Divider(height: 1),
                  _ProfileTile(icon: Icons.directions_car, title: 'My Vehicles', onTap: () {}),
                  const Divider(height: 1),
                  _ProfileTile(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () {}),
                  const Divider(height: 1),
                  _ProfileTile(icon: Icons.settings, title: 'Settings', onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _ProfileTile(icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
                  const Divider(height: 1),
                  _ProfileTile(icon: Icons.info_outline, title: 'About SmartPS', onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ProfileTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
